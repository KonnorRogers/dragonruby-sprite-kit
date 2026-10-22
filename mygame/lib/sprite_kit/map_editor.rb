require SpriteKit.to_load_path("camera")
require SpriteKit.to_load_path("map")
require SpriteKit.to_load_path("primitives")
require SpriteKit.to_load_path("sprite_methods")
require SpriteKit.to_load_path("spritesheet_loader")
require SpriteKit.to_load_path("string_helper")
require SpriteKit.to_load_path(File.join("ui", "color"))
require SpriteKit.to_load_path(File.join("ui", "static_palette"))
require SpriteKit.to_load_path(File.join("ui", "semantic_palette"))

module SpriteKit
  # A tile map editor. Paints `@state.current_sprite` (picked from `SpriteKit::Canvas`) onto layers of a `SpriteKit::Map`.
  # The grid size is the same as the brush size (`@state.tile_selection.w` / `@state.tile_selection.h`).
  #
  # See `SpriteKit::Scenes::MapEditorScene` for wiring it up with a canvas + tool drawer.
  class MapEditor
    # These keys dont really map to anything.
    IGNORED_KEYS = [:char, :raw_key]

    # We dont really expect modifier keys to be used as actual keys.
    MODIFIER_KEYS = [
      :control,
      :control_left,
      :control_right,

      :shift,
      :shift_right,
      :shift_left,

      :meta,
      :meta_left,
      :meta_right,

      :alt,
      :alt_left,
      :alt_right,
    ]

    HELP = [
      "LMB: use tool   RMB: erase",
      "MMB / Space+drag: pan",
      "Wheel / +/-/0: zoom",
      "Ctrl+Z: undo  Ctrl+Shift+Z: redo",
      "Ctrl+S: save   G: grid",
      "N: new layer   V: hide layer",
      "[ / ]: change layer",
      "Tab: pick tiles / switch view",
    ]

    PANEL_W = 260
    STATUS_H = 28
    ROW_H = 26
    PADDING = 12
    MIN_SCALE = 0.25
    MAX_SCALE = 8

    attr_accessor :state, :camera, :camera_path, :map, :tool, :show_grid, :viewport_boundary

    def initialize(state:, map_path: "data/map.json", camera: ::SpriteKit::Camera.new(path: :map_camera))
      @state = state
      @camera = camera
      @camera_path = camera.path || :map_camera
      @palette = UI::SemanticPalette.new

      @map = ::SpriteKit::Map.new(path: map_path, tile_w: @state.grid_size.w, tile_h: @state.grid_size.h)

      # Keep the brush in sync with the grid the map was made with.
      if @map.load
        @state.grid_size.w = @map.tile_w
        @state.grid_size.h = @map.tile_h
      end

      @state.grid_size.w = 48
      @state.grid_size.h = 48

      # @type [:paint, :erase, :rect, :pick]
      @tool = :paint
      @show_grid = true

      # The in-progress brush stroke / rectangle.
      @stroke = nil
      @panning = false
      @saved_at = nil

      # used to calculate where clicks are registered.
      @viewport_boundary = {
        x: 0,
        y: 0,
        h: Grid.h,
        w: Grid.w
      }

      @panel_buttons = []

      @tools = {
        paint: {
          keybindings: [
            [:b]
          ],
          label: "Paint (B)",
          action: -> { select_tool(:paint) }
        },
        erase: {
          keybindings: [
            [:e]
          ],
          label: "Erase (E)",
          action: -> { select_tool(:erase) }
        },
        rect: {
          keybindings: [
            [:r]
          ],
          label: "Rect fill (R)",
          action: -> { select_tool(:rect) }
        },
        pick: {
          keybindings: [
            [:p]
          ],
          label: "Pick tile (P)",
          action: -> { select_tool(:pick) }
        },
      }

      @hotkeys = {
        undo_change: {
          keybindings: [
            [:ctrl, :z],
            [:meta, :z]
          ],
          action: -> { undo_change }
        },
        redo_change: {
          keybindings: [
            [:ctrl, :shift, :z],
            [:meta, :shift, :z]
          ],
          action: -> { redo_change }
        },
        save: {
          keybindings: [
            [:ctrl, :s],
            [:meta, :s]
          ],
          action: -> { save }
        },
        show_grid: {
          keybindings: [
            [:g]
          ],
          action: -> { @show_grid = !@show_grid }
        },
        add_layer: {
          keybindings: [
            [:n]
          ],
          action: -> { add_layer }
        },
        toggle_layer_visibility: {
          keybindings: [
            [:v]
          ],
          action: -> { toggle_layer_visibility(@map.current_layer_index) }
        },
        select_previous_layer: {
          keybindings: [
            [:open_square_brace]
          ],
          action: -> { select_layer(@map.current_layer_index - 1) }
        },
        select_next_layer: {
          keybindings: [
            [:close_square_brace]
          ],
          action: -> { select_layer(@map.current_layer_index + 1) }
        },
        clear: {
          keybindings: [
            [:escape]
          ],
          action: -> {
            if @stroke
              @stroke = nil
            else
              @state.current_sprite = nil
            end
          }
        }
      }.merge(@tools)

      @background_color = nil
      @background_color = { r: 40, g: 42, b: 54, a: 255 }
    end

    def tick(args)
      input(args)
      calc(args)
      render(args)
    end

    # Only the side panel, for when another view (canvas / file tree) is showing so the brush + layers stay visible.
    def tick_panel(args)
      calc_layout(args)
      build_panel(args)
      handle_panel_click(args)
      render_panel(args)
    end

    def input(args)
      calc_layout(args)

      mouse = args.inputs.mouse
      @world_mouse = @camera.to_world_space({ x: mouse.x, y: mouse.y })
      @hovered_cell = cell_at(@world_mouse)
      @mouse_over_map = mouse.intersect_rect?(@map_area)

      move_camera(args)
      handle_pan(args)

      if !@state.text_input_focused
        HotkeyHandler.handle(args.inputs.keyboard, @hotkeys)
      end

      build_panel(args)
      handle_panel_click(args)
      handle_mouse(args) if !@panning
    end

    def calc(args)
      calc_camera(args)

      @map.tile_w = @state.grid_size.w
      @map.tile_h = @state.grid_size.h
    end

    def render(args)
      render_camera(args)
      render_tiles(args)
      render_grid(args) if @show_grid
      render_cursor(args)
      render_panel(args)
      render_status_bar(args)
      render_hint(args)
    end

    def grid_w
      [@state.grid_size.w.to_i, 1].max
    end

    def grid_h
      [@state.grid_size.h.to_i, 1].max
    end

    def save
      @map.save
      @saved_at = Kernel.tick_count
    end

    # Tiles that the current sprite (or prefab) would place with its bottom-left at `x`, `y`.
    def brush_tiles(x, y)
      sprite = @state.current_sprite
      return [] if !sprite

      if sprite.prefab && sprite.prefab.length > 0
        SpriteMethods.render_prefab(sprite.merge({ x: x, y: y })).map do |prefab_sprite|
          tile_from_sprite(prefab_sprite, prefab_sprite.x, prefab_sprite.y)
        end
      else
        [tile_from_sprite(sprite, x, y)]
      end
    end

    private

    def tile_from_sprite(sprite, x, y)
      {
        x: x,
        y: y,
        w: sprite.source_w,
        h: sprite.source_h,
        path: sprite.path,
        source_x: sprite.source_x,
        source_y: sprite.source_y,
        source_w: sprite.source_w,
        source_h: sprite.source_h,
      }
    end

    def calc_layout(args)
      @panel = {
        x: args.grid.w - PANEL_W,
        y: 0,
        w: PANEL_W,
        h: args.grid.h,
      }

      map_x = @viewport_boundary.x
      @map_area = {
        x: map_x,
        y: STATUS_H,
        w: @panel.x - map_x,
        h: args.grid.h - STATUS_H,
      }

      @status_bar = {
        x: map_x,
        y: 0,
        w: @map_area.w,
        h: STATUS_H,
      }
    end

    # Snaps a world point to the bottom-left of its grid cell.
    def cell_at(point)
      {
        x: (point.x / grid_w).floor * grid_w,
        y: (point.y / grid_h).floor * grid_h,
        w: grid_w,
        h: grid_h,
      }
    end

    # ---------------------------------------------------------------------------
    # Camera
    # ---------------------------------------------------------------------------

    def camera_speed
      3 + (12 / @camera.scale)
    end

    def move_camera(args)
      return if @state.text_input_focused

      keyboard = args.inputs.keyboard
      speed = camera_speed

      # Movement
      if keyboard.left
        @camera.target_x -= speed
      elsif keyboard.right
        @camera.target_x += speed
      end

      if keyboard.down
        @camera.target_y -= speed
      elsif keyboard.up
        @camera.target_y += speed
      end

      # Zoom
      if keyboard.key_down.equal_sign || keyboard.key_down.plus
        zoom_to(@camera.target_scale + 0.25)
      elsif keyboard.key_down.minus
        zoom_to(@camera.target_scale - 0.25)
      elsif keyboard.key_down.zero
        zoom_to(1)
      end

      wheel = args.inputs.mouse.wheel
      if wheel && wheel.y != 0 && @mouse_over_map
        zoom_to(@camera.target_scale * (1.1**wheel.y), anchor: args.inputs.mouse)
      end
    end

    # Zooms while keeping the world point under `anchor` (a screen point) in place.
    def zoom_to(scale, anchor: nil)
      scale = scale.clamp(MIN_SCALE, MAX_SCALE)

      if anchor
        world = @camera.to_world_space({ x: anchor.x, y: anchor.y })
        @camera.target_x = world.x - (anchor.x - @camera.half_width - @camera.offset_x) / scale
        @camera.target_y = world.y - (anchor.y - @camera.half_height - @camera.offset_y) / scale
      end

      @camera.target_scale = scale
    end

    def handle_pan(args)
      mouse = args.inputs.mouse
      space_drag = args.inputs.keyboard.space && mouse.button_left

      if !@panning && @mouse_over_map && (mouse.key_down.middle || (space_drag && mouse.key_down.left))
        @panning = true
      end

      if @panning && !(mouse.button_middle || space_drag)
        @panning = false
      end

      return if !@panning

      # Panning moves 1:1 with the mouse, so skip the easing.
      @camera.x -= mouse.relative_x / @camera.scale
      @camera.y -= mouse.relative_y / @camera.scale
      @camera.target_x = @camera.x
      @camera.target_y = @camera.y
    end

    def calc_camera(_args)
      ease = 0.1
      @camera.scale += (@camera.target_scale - @camera.scale) * ease

      @camera.x += (@camera.target_x - @camera.x) * ease
      @camera.y += (@camera.target_y - @camera.y) * ease
    end

    # ---------------------------------------------------------------------------
    # Keyboard
    # ---------------------------------------------------------------------------

    def handle_hotkeys(args)
    end

    def select_tool(tool)
      return if @stroke

      @tool = tool
    end

    # ---------------------------------------------------------------------------
    # Mouse / tools
    # ---------------------------------------------------------------------------

    def handle_mouse(args)
      mouse = args.inputs.mouse

      if !@stroke && @mouse_over_map
        if mouse.key_down.left
          start_stroke(:left)
        elsif mouse.key_down.right
          start_stroke(:right)
        end
      end

      return if !@stroke

      held = @stroke.button == :left ? mouse.button_left : mouse.button_right

      if held
        continue_stroke
      else
        end_stroke
      end
    end

    # The tool a stroke uses. Right click always erases.
    def stroke_tool(button)
      return :erase if button == :right && @tool != :rect

      @tool
    end

    def start_stroke(button)
      tool = stroke_tool(button)

      if tool == :pick
        pick_tile
        return
      end

      layer = @map.current_layer
      @stroke = {
        button: button,
        tool: tool,
        erase: button == :right || tool == :erase,
        change: @map.begin_change(layer),
        start_cell: @hovered_cell,
        last_cell: nil,
      }

      continue_stroke
    end

    def continue_stroke
      stroke = @stroke
      return if stroke.tool == :rect

      cells = stroke.last_cell ? cells_between(stroke.last_cell, @hovered_cell) : [@hovered_cell]
      cells.each do |cell|
        if stroke.erase
          @map.erase(cell, stroke.change)
        else
          paint_at(cell.x, cell.y, stroke.change)
        end
      end

      stroke.last_cell = @hovered_cell
    end

    def end_stroke
      stroke = @stroke
      @stroke = nil

      if stroke.tool == :rect
        rect = stroke_rect(stroke)
        if stroke.erase
          @map.erase(rect, stroke.change)
        else
          fill_rect(rect, stroke.change)
        end
      end

      # Purposely delay saving until the stroke ends, otherwise the editor lags a lot.
      return save if @map.commit(stroke.change)
    end

    def paint_at(x, y, change)
      tiles = brush_tiles(x, y)
      return if tiles.length <= 0

      # Don't let a stroke paint over itself when the brush is larger than the grid.
      return if tiles.any? { |tile| Geometry.find_intersect_rect(tile, change.added) }

      tiles.each { |tile| @map.place_tile(tile, change) }
    end

    def fill_rect(rect, change)
      sprite = @state.current_sprite
      return if !sprite

      # Step by the brush size (rounded up to the grid) so larger sprites tile cleanly.
      bounds = brush_bounds(brush_tiles(0, 0))
      step_x = [(bounds.w / grid_w).ceil, 1].max * grid_w
      step_y = [(bounds.h / grid_h).ceil, 1].max * grid_h

      y = rect.y
      while y < rect.y + rect.h
        x = rect.x
        while x < rect.x + rect.w
          paint_at(x, y, change)
          x += step_x
        end
        y += step_y
      end
    end

    def pick_tile
      found = @map.tile_at(@world_mouse)
      return if !found

      tile = found.tile
      spritesheet = @state.spritesheets[tile.path]

      if !spritesheet
        spritesheet = SpritesheetLoader.new.load_file(path: tile.path)
        @state.spritesheets[tile.path] = spritesheet
      end

      @state.current_sprite = {
        source_x: tile.source_x,
        source_y: tile.source_y,
        source_w: tile.source_w,
        source_h: tile.source_h,
        w: tile.source_w,
        h: tile.source_h,
        path: tile.path,
        spritesheet: spritesheet,
      }

      # So tabbing over to the canvas shows the spritesheet the tile came from.
      @state.file_path = tile.path
      @map.current_layer_index = found.layer_index
      @tool = :paint
    end

    # Grid cells along the line between 2 cells so fast mouse movements don't leave gaps.
    def cells_between(from, to)
      columns = ((to.x - from.x) / grid_w).abs
      rows = ((to.y - from.y) / grid_h).abs
      steps = [columns, rows].max.ceil

      return [to] if steps <= 0

      (1..steps).map do |step|
        percent = step.fdiv(steps)
        cell_at({
          x: from.x + (to.x - from.x) * percent + grid_w / 2,
          y: from.y + (to.y - from.y) * percent + grid_h / 2,
        })
      end
    end

    # The rect (in world space) covered by a rect stroke, from its starting cell to the hovered cell.
    def stroke_rect(stroke)
      start_cell = stroke.start_cell
      x = [start_cell.x, @hovered_cell.x].min
      y = [start_cell.y, @hovered_cell.y].min

      {
        x: x,
        y: y,
        w: [start_cell.x, @hovered_cell.x].max + grid_w - x,
        h: [start_cell.y, @hovered_cell.y].max + grid_h - y,
      }
    end

    def brush_bounds(tiles)
      return @hovered_cell if tiles.length <= 0

      min_x = tiles.map(&:x).min
      min_y = tiles.map(&:y).min
      max_x = tiles.map { |tile| tile.x + tile.w }.max
      max_y = tiles.map { |tile| tile.y + tile.h }.max

      { x: min_x, y: min_y, w: max_x - min_x, h: max_y - min_y }
    end

    # ---------------------------------------------------------------------------
    # History / layers
    # ---------------------------------------------------------------------------

    def undo_change
      return if @stroke

      save if @map.undo
    end

    def redo_change
      return if @stroke

      save if @map.redo
    end

    def add_layer
      @map.add_layer
      save
    end

    def remove_layer
      save if @map.remove_layer
    end

    def move_layer(direction)
      save if @map.move_layer(@map.current_layer_index, direction)
    end

    def select_layer(index)
      @map.current_layer_index = index.clamp(0, @map.layers.length - 1)
    end

    def toggle_layer_visibility(index)
      @map.toggle_layer_visibility(index)
      save
    end

    # ---------------------------------------------------------------------------
    # Rendering
    # ---------------------------------------------------------------------------

    def render_camera(args)
      viewport = @camera.viewport
      args.outputs[@camera_path].w = viewport.w
      args.outputs[@camera_path].h = viewport.h
      args.outputs[@camera_path].background_color = @background_color
      @state.draw_buffer.primitives << { **viewport, path: @camera_path }
    end

    def render_tiles(_args)
      sprites = []

      @map.layers.each do |layer|
        next if !layer.visible

        @camera.find_all_intersect_viewport(layer.tiles).each do |tile|
          sprites << @camera.to_screen_space(tile)
        end
      end

      @state.draw_buffer[@camera_path].concat(sprites)
    end

    def render_grid(_args)
      # Too dense to be useful, and expensive.
      return if grid_w * @camera.scale < 4 || grid_h * @camera.scale < 4

      world = @camera.viewport_world

      min_x = (world.x / grid_w).floor * grid_w
      min_y = (world.y / grid_h).floor * grid_h
      max_x = world.x + world.w
      max_y = world.y + world.h

      solids = []

      x = min_x
      while x <= max_x
        s = @camera.to_screen_space!({ x: x, y: min_y, w: 1, h: max_y - min_y })
        dark_alpha = x == 0 ? 200 : 120
        light_alpha = x == 0 ? 180 : 60
        solids << { x: s.x - 1, y: s.y, w: 1, h: s.h, r: 0, g: 0, b: 0, a: dark_alpha, path: :solid } # dark
        solids << { x: s.x, y: s.y, w: 1, h: s.h, r: 255, g: 255, b: 255, a: light_alpha, path: :solid } # light
        x += grid_w
      end

      y = min_y
      while y <= max_y
        s = @camera.to_screen_space!({ x: min_x, y: y, w: max_x - min_x, h: 1 })
        dark_alpha = y == 0 ? 180 : 120
        light_alpha = y == 0 ? 200 : 60
        solids << { x: s.x, y: s.y - 1, w: s.w, h: 1, r: 0, g: 0, b: 0, a: dark_alpha, path: :solid } # dark
        solids << { x: s.x, y: s.y, w: s.w, h: 1, r: 255, g: 255, b: 255, a: light_alpha, path: :solid } # light
        y += grid_h
      end

      @state.draw_buffer[@camera_path].concat(solids)
    end

    def render_cursor(args)
      return if @panning
      return if !@stroke && !@mouse_over_map

      primitives = []
      tool = @stroke ? @stroke.tool : @tool
      erasing = @stroke ? @stroke.erase : (tool == :erase || args.inputs.mouse.button_right)

      if tool == :rect && @stroke
        rect = @camera.to_screen_space(stroke_rect(@stroke))
        color = erasing ? { r: 255, g: 60, b: 60 } : { r: 80, g: 160, b: 255 }
        primitives << rect.merge({ path: :solid, a: 60, **color })
        primitives.concat(Primitives.borders(rect, border_width: 2, color: { **color, a: 255 }).values)
      elsif tool == :pick
        found = @map.tile_at(@world_mouse)
        if found
          rect = @camera.to_screen_space(found.tile)
          primitives.concat(Primitives.borders(rect, border_width: 2, color: { r: 255, g: 220, b: 80, a: 255 }).values)
        end
      elsif erasing
        rect = @camera.to_screen_space(@hovered_cell)
        primitives << rect.merge({ path: :solid, r: 255, g: 60, b: 60, a: 80 })
        primitives.concat(Primitives.borders(rect, border_width: 2, color: { r: 255, g: 60, b: 60, a: 255 }).values)
      else
        tiles = brush_tiles(@hovered_cell.x, @hovered_cell.y)

        tiles.each do |tile|
          primitives << @camera.to_screen_space(tile).merge({ a: 160 })
        end

        rect = @camera.to_screen_space(brush_bounds(tiles))
        primitives.concat(Primitives.borders(rect, border_width: 2, color: { r: 80, g: 220, b: 120, a: 255 }).values)
      end

      @state.draw_buffer[@camera_path].concat(primitives)
    end

    # Tells the user where tiles come from when they don't have one to paint with yet.
    def render_hint(_args)
      return if @state.current_sprite
      return if @tool != :paint && @tool != :rect

      text = "No tile selected. Click \"Choose tile\" in the panel (or press Tab) to pick one."
      text_w, text_h = GTK.calcstringbox(text, size_px: 18)
      hint = {
        x: @map_area.x + (@map_area.w - text_w) / 2 - PADDING,
        y: @map_area.y + @map_area.h - text_h - PADDING * 3,
        w: text_w + PADDING * 2,
        h: text_h + PADDING,
      }

      @state.draw_buffer.primitives.concat([
        hint.merge({ path: :solid, **@palette.colors.dig(:brand, :fill, :loud) }),
        {
          x: hint.x + PADDING,
          y: hint.y + hint.h / 2,
          text: text,
          size_px: 18,
          anchor_y: 0.5,
          **@palette.colors.dig(:brand, :on, :loud)
        }.label!
      ])
    end

    def render_status_bar(args)
      layer = @map.current_layer
      cell_x = (@hovered_cell.x / grid_w).floor
      cell_y = (@hovered_cell.y / grid_h).floor

      saved = if @saved_at && Kernel.tick_count - @saved_at < 60
                "saved!"
              else
                @map.path
              end

      parts = [
        @tools[@tool][:label],
        "Layer: #{layer.name}#{layer.visible ? "" : " (hidden)"}",
        "Cell: #{cell_x}, #{cell_y}",
        "Zoom: #{@camera.scale.round(2)}x",
        "Tiles: #{@map.tile_count}",
        saved,
      ]

      @state.draw_buffer.primitives.concat([
        @status_bar.merge({ path: :solid, **@palette.colors.dig(:neutral, :fill, :loud) }),
        {
          x: @status_bar.x + PADDING,
          y: @status_bar.y + @status_bar.h / 2,
          text: StringHelper.truncate(parts.join("  |  "), size_px: 16, max_width: @status_bar.w - PADDING * 2),
          size_px: 16,
          anchor_y: 0.5,
          **@palette.colors.dig(:neutral, :on, :loud)
        }.label!
      ])
    end

    # Builds every clickable element of the side panel. `render_panel` draws them, `handle_panel_click` clicks them.
    def build_panel(args)
      mouse = args.inputs.mouse
      @panel_buttons = []
      @panel_labels = []
      @panel_sprites = []

      x = @panel.x + PADDING
      w = @panel.w - PADDING * 2
      y = @panel.h - PADDING

      _, button_h = GTK.calcstringbox("+ Add")
      button_h += 2 + 8

      y = add_panel_heading("Brush", x, y)
      y = build_brush_preview(x, y, button_h)
      y -= 16

      y = add_panel_heading("Layers", x, y)

      button_x = x
      [
        { text: "+ Add", action: proc { add_layer } },
        { text: "Delete", action: proc { remove_layer }, danger: true },
        { text: "Up", action: proc { move_layer(1) } },
        { text: "Down", action: proc { move_layer(-1) } },
      ].each do |config|
        button = panel_button(config.text, button_x, y - button_h, config.action, danger: config.danger)
        button_x += button.w + 6
      end
      y -= button_h + 10

      # Top-most layer first, like most editors.
      (@map.layers.length - 1).downto(0) do |index|
        layer = @map.layers[index]
        row = { x: x, y: y - ROW_H, w: w, h: ROW_H }
        eye = { x: row.x + 6, y: row.y + (ROW_H - 14) / 2, w: 14, h: 14 }

        @panel_buttons << row.merge({
          kind: :layer_row,
          active: index == @map.current_layer_index,
          hovered: mouse.intersect_rect?(row),
          layer: layer,
          eye: eye,
          action: proc { select_layer(index) }
        })

        # Comes after the row so it gets clicked instead of the row.
        @panel_buttons << eye.merge({ kind: :hit_box, action: proc { toggle_layer_visibility(index) } })

        y -= ROW_H + 2
      end

      y -= 16
      y = add_panel_heading("Tools", x, y)

      @tools.each do |tool, config|
        row = { x: x, y: y - ROW_H, w: w, h: ROW_H }
        @panel_buttons << row.merge({
          kind: :tool_row,
          text: config[:label],
          active: tool == @tool,
          hovered: mouse.intersect_rect?(row),
          action: proc { select_tool(tool) }
        })
        y -= ROW_H + 2
      end

      y -= 16
      @panel_labels << panel_label("Grid: #{grid_w}x#{grid_h} (brush w / h)", x, y, :quiet)
      y -= 24

      HELP.each do |text|
        @panel_labels << panel_label(text, x, y, :quiet)
        y -= 20
      end
    end

    # Shows the current tile and a button to go pick one from the spritesheets.
    def build_brush_preview(x, y, button_h)
      preview_size = 48
      preview = { x: x, y: y - preview_size, w: preview_size, h: preview_size }
      sprite = @state.current_sprite

      @panel_sprites << preview.merge({ path: :solid, r: 0, g: 0, b: 0, a: 80 })
      @panel_sprites.concat(Primitives.borders(preview, color: @palette.colors.dig(:neutral, :border, :loud)).values)

      text_x = preview.x + preview.w + 10

      if sprite
        # Fit the tile inside the preview box, keeping its aspect ratio.
        scale = [preview_size.fdiv(sprite.source_w), preview_size.fdiv(sprite.source_h)].min
        w = sprite.source_w * scale
        h = sprite.source_h * scale
        @panel_sprites << {
          x: preview.x + (preview_size - w) / 2,
          y: preview.y + (preview_size - h) / 2,
          w: w,
          h: h,
          path: sprite.path,
          source_x: sprite.source_x,
          source_y: sprite.source_y,
          source_w: sprite.source_w,
          source_h: sprite.source_h,
        }

        name = "#{sprite.source_w}x#{sprite.source_h} #{File.basename(sprite.path.to_s)}"
        name = StringHelper.truncate(name, size_px: 16, max_width: @panel.x + @panel.w - PADDING - text_x)
        @panel_labels << panel_label(name, text_x, preview.y + preview.h, :loud)
      else
        @panel_labels << panel_label("No tile selected", text_x, preview.y + preview.h, :loud)
      end

      if @state.view == :map
        panel_button("Choose tile", text_x, preview.y, proc { choose_tile }, brand: !sprite)
      else
        panel_button("Back to map", text_x, preview.y, proc { @state.next_view = :map }, brand: !!sprite)
      end

      preview.y - 4
    end

    # Sends the user to pick a tile. Opens the last spritesheet if there was one, otherwise the file tree.
    def choose_tile
      @state.next_view = @state.spritesheets[@state.file_path] ? :canvas : :file_tree
    end

    def panel_button(text, x, y, action, danger: false, brand: false)
      color_group = if danger
                      :danger
                    elsif brand
                      :brand
                    else
                      :neutral
                    end
      attention = brand ? :loud : :normal

      button = Primitives.button(
        text: text,
        x: x,
        y: y,
        padding: 4,
        border_width: 1,
        background_color: {
          path: :solid,
          **@palette.colors.dig(color_group, :fill, attention)
        }
      )
      button.action = action
      button.label_color = @palette.colors.dig(color_group, :on, attention)
      @panel_buttons << button
      button
    end

    def add_panel_heading(text, x, y)
      @panel_labels << panel_label(text, x, y, :loud, size_px: 20)
      y - 30
    end

    def panel_label(text, x, y, attention, size_px: 16)
      color = attention == :loud ? @palette.colors.dig(:neutral, :on, :loud) : @palette.colors.dig(:neutral, :border, :normal)
      {
        x: x,
        y: y,
        text: text,
        size_px: size_px,
        anchor_y: 1,
        **color
      }.label!
    end

    def handle_panel_click(args)
      mouse = args.inputs.mouse
      return if !mouse.click
      return if @stroke
      return if !mouse.intersect_rect?(@panel)

      button = @panel_buttons.reverse_each.find { |b| mouse.intersect_rect?(b) }
      button.action.call if button
    end

    def render_panel(_args)
      primitives = []
      colors = @palette.colors

      primitives << @panel.merge({ path: :solid, **colors.dig(:neutral, :fill, :loud) })
      primitives << { x: @panel.x, y: 0, w: 1, h: @panel.h, path: :solid, **colors.dig(:neutral, :border, :loud) }

      @panel_buttons.each do |button|
        case button.kind
        when :hit_box
          next
        when :layer_row
          primitives.concat(render_layer_row(button))
        when :tool_row
          primitives.concat(render_tool_row(button))
        else
          # Primitives.button
          label = button.primitives[0].merge(button.label_color)
          primitives << button
          primitives << label
          primitives.concat(button.primitives[1..-1])
        end
      end

      primitives.concat(@panel_sprites)
      primitives.concat(@panel_labels)
      @state.draw_buffer.primitives.concat(primitives)
    end

    def row_background(row)
      colors = @palette.colors
      # Only take the rect, otherwise a row with `text:` gets rendered as a label.
      rect = { x: row.x, y: row.y, w: row.w, h: row.h }

      if row.active
        rect.merge({ path: :solid, **colors.dig(:brand, :fill, :loud) })
      elsif row.hovered
        rect.merge({ path: :solid, **colors.dig(:neutral, :on, :quiet) })
      end
    end

    def render_layer_row(row)
      colors = @palette.colors
      layer = row.layer
      eye = row.eye
      text_color = layer.visible ? colors.dig(:neutral, :on, :loud) : colors.dig(:neutral, :border, :loud)

      primitives = []
      background = row_background(row)
      primitives << background if background

      if layer.visible
        primitives << eye.merge({ path: :solid, **colors.dig(:neutral, :on, :loud) })
      end
      primitives.concat(Primitives.borders(eye, color: colors.dig(:neutral, :on, :loud)).values)

      primitives << {
        x: eye.x + eye.w + 10,
        y: row.y + row.h / 2,
        text: StringHelper.truncate(layer.name, size_px: 16, max_width: row.w - 90),
        size_px: 16,
        anchor_y: 0.5,
        **text_color
      }.label!

      primitives << {
        x: row.x + row.w - 8,
        y: row.y + row.h / 2,
        text: "#{layer.tiles.length}",
        size_px: 14,
        anchor_x: 1,
        anchor_y: 0.5,
        **text_color
      }.label!

      primitives
    end

    def render_tool_row(row)
      primitives = []
      background = row_background(row)
      primitives << background if background

      primitives << {
        x: row.x + 10,
        y: row.y + row.h / 2,
        text: row.text,
        size_px: 16,
        anchor_y: 0.5,
        **@palette.colors.dig(:neutral, :on, :loud)
      }.label!

      primitives
    end
  end
end
