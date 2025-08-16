require SpriteKit.to_load_path("camera")
require SpriteKit.to_load_path("spritesheet_loader")
# require SpriteKit.to_load_path("primitives")
# require SpriteKit.to_load_path(File.join("ui", "semantic_palette"))
# require SpriteKit.to_load_path("serializer")
require SpriteKit.to_load_path("sprite_methods")

module SpriteKit
  class Canvas
    attr_accessor :hover_rect, :rect_size, :viewport_boundary, :spritesheets, :max_width, :state

    def initialize(state:, sprite_directory: "sprites")
      @spritesheet_loader = SpriteKit::SpritesheetLoader.new
      @spritesheets = @spritesheet_loader.load_directory(sprite_directory)

      # max_width of elements to load. Wraps downward if greater than 2000px
      @max_width = 2000

      @hover_rect = nil
      @hover_rect_screen = nil

      # @show_grid = false

      # used to calculate where clicks are registered.
      @viewport_boundary = {
        x: 0,
        y: 0,
        h: Grid.h,
        w: Grid.w
      }
      @state = state
    end

    def camera_render_target(args)
      rt = args.outputs[@state.camera_path]
      viewport = @state.camera.viewport
      args.outputs[@state.camera_path].w = viewport.w
      args.outputs[@state.camera_path].h = viewport.h
      rt
    end

    def camera_speed
      3 + (12 / @state.camera.scale)
    end

    def tick(args)
      input(args)
      calc(args)
      render(args)
    end

    def input(args)
      move_camera(args)

      if args.inputs.keyboard.key_down.escape
        @state.current_sprite = nil
      end

      # if args.inputs.keyboard.key_down.g
      #   @show_grid = !@show_grid
      # end
    end

    def calc(args)
      calc_camera(args)
    end

    def render(args)
      render_camera(args)
      render_sprite_canvas(args)
      # render_grid_lines(args)
      render_current_sprite(args)

      if @hover_rect_screen
        @state.draw_buffer[@state.camera_path] << @hover_rect_screen
      end
    end

    def move_camera(args)
      inputs = args.inputs

      speed = camera_speed

      # Movement
      if inputs.keyboard.left_arrow
        @state.camera.target_x -= speed
      elsif inputs.keyboard.right_arrow
        @state.camera.target_x += speed
      end

      if inputs.keyboard.down_arrow
        @state.camera.target_y -= speed
      elsif inputs.keyboard.up_arrow
        @state.camera.target_y += speed
      end

      # Zoom
      if args.inputs.keyboard.key_down.equal_sign || args.inputs.keyboard.key_down.plus
        @state.camera.target_scale += 0.25
      elsif args.inputs.keyboard.key_down.minus
        @state.camera.target_scale -= 0.25
        @state.camera.target_scale = 0.25 if @state.camera.target_scale < 0.25
      elsif args.inputs.keyboard.zero
        @state.camera.target_scale = 1
      end
    end

    def calc_camera(_args)
      ease = 0.1
      @state.camera.scale += (@state.camera.target_scale - @state.camera.scale) * ease

      @state.camera.x += (@state.camera.target_x - @state.camera.x) * ease
      @state.camera.y += (@state.camera.target_y - @state.camera.y) * ease
    end

    def render_camera(args)
      camera_render_target(args)
      @state.draw_buffer.primitives << { **@state.camera.viewport, path: @state.camera_path }
    end

    def render_sprite_canvas(args)
      x = 0
      y = 0
      gap = 80
      current_width = 0

      current_row = []

      @hover_rect = nil
      @hover_rect_screen = nil

      @spritesheets.each_with_index do |spritesheet, index|
        current_width += spritesheet.file_width

        if index > 0
          prev_spritesheet = @spritesheets[index - 1]
          if current_width + gap + spritesheet.file_width > @max_width
            # move down a row
            current_width = spritesheet.file_width
            y -= current_row.max_by(&:h).h + gap
            x = 0
            current_row = []
          else
            x += prev_spritesheet.file_width + gap
          end
        end

        spritesheet.merge!({
          x: x,
          y: y - spritesheet.file_height,
          w: spritesheet.file_width,
          h: spritesheet.file_height,
          path: spritesheet.path
        })

        current_row << spritesheet
      end

      visible_spritesheets = @state.camera.find_all_intersect_viewport(@spritesheets)

      visible_spritesheets.each do |spritesheet|
        spritesheet.spritesheet_screen = @state.camera.to_screen_space(spritesheet)
        @state.draw_buffer[@state.camera_path] << spritesheet.spritesheet_screen
      end

      if !args.inputs.mouse.intersect_rect?(@viewport_boundary)
        return
      end

      Geometry.find_all_intersect_rect(@state.world_mouse, visible_spritesheets).each do |spritesheet|
        spritesheet_screen = spritesheet.spritesheet_screen
        rect_size = @state.tile_selection

        relative_x = (@state.world_mouse.x - spritesheet.x).clamp(@state.tile_selection.offset_x, spritesheet.w)
        relative_y = (@state.world_mouse.y - spritesheet.y).clamp(@state.tile_selection.offset_y, spritesheet.h)

        column_gap = @state.tile_selection.column_gap

        row_gap = @state.tile_selection.row_gap

        rect_x = (relative_x).ifloor(rect_size.w + column_gap)
        rect_y = (relative_y).ifloor(rect_size.h + row_gap)

        hover_rect_x = rect_x + spritesheet.x + @state.tile_selection.offset_x
        hover_rect_y = rect_y + spritesheet.y + @state.tile_selection.offset_y

        @hover_rect = rect_size.merge({
          x: hover_rect_x,
          y: hover_rect_y,
          path: :pixel,
          primitive_marker: :sprite,
          r: 255,
          g: 0,
          b: 0,
          a: 128
        })

        unclamped_source_x = (@hover_rect.x - spritesheet.x)# .clamp(0, spritesheet.w - rect_size.w)
        unclamped_source_y = (@hover_rect.y - spritesheet.y)# .clamp(0, spritesheet.h - rect_size.h)

        source_x = unclamped_source_x.clamp(@state.tile_selection.offset_x, spritesheet.w - rect_size.w)
        source_y = unclamped_source_y.clamp(@state.tile_selection.offset_y, spritesheet.h - rect_size.h)

        # source_w and source_h need to be "clamped" because otherwise you get weird scaling.
        source_w = (rect_size.w).clamp(@state.tile_selection.offset_x, spritesheet.w - source_x)
        if unclamped_source_x < 0
          source_w += unclamped_source_x
          @hover_rect.w += unclamped_source_x
          @hover_rect.x -= unclamped_source_x
        elsif unclamped_source_x > spritesheet.w - rect_size.w
          source_x_diff = unclamped_source_x - source_x
          source_w -= source_x_diff
          source_x += source_x_diff
          @hover_rect.w -= source_x_diff
          # @hover_rect.x -= source_x_diff
        end

        # w = 16, source_x = 72 = 88px, but file max is 80. need to chop 8px.
        # w = 16, source_x = 0 = 16px, file max is 80. use 16px.

        source_h = (rect_size.h).clamp(@state.tile_selection.offset_y, spritesheet.h - source_y)
        if unclamped_source_y < 0
          source_h += unclamped_source_y
          @hover_rect.h += unclamped_source_y
          @hover_rect.y -= unclamped_source_y
        elsif unclamped_source_y > spritesheet.h - rect_size.h
          source_y_diff = unclamped_source_y - source_y
          source_h -= source_y_diff
          source_y += source_y_diff
          @hover_rect.h -= source_y_diff
          # @hover_rect.x -= source_x_diff
        end
        # h = 16, source_y = 72 = 88px, but file max is 80px. need to chop 8px.
        # h = 16, source_x = 0 = 16px, file max is 80. use 16px.

        new_sprite = {
          spritesheet: spritesheet,
          w: @hover_rect.w,
          h: @hover_rect.h,
          source_x: source_x,
          source_y: source_y,
          source_w: source_w,
          source_h: source_h,
          path: spritesheet.path
        }

        if @state.current_sprite && @state.current_sprite.path == new_sprite.path && args.inputs.keyboard.key_down_or_held?(:shift)
          current_sprite = @state.current_sprite

          if current_sprite.source_x == new_sprite.source_x
            # no-op
          elsif current_sprite.source_x > new_sprite.source_x
            source_x = [current_sprite.source_x, new_sprite.source_x].min
            source_w = [current_sprite.source_x - new_sprite.source_x + @hover_rect.w, current_sprite.source_w].max
          else
            source_x = [current_sprite.source_x, new_sprite.source_x].min
            source_w = [new_sprite.source_x - current_sprite.source_x + @hover_rect.w, spritesheet.w - source_x].min
          end

          if current_sprite.source_y == new_sprite.source_y
            # no-op
          elsif current_sprite.source_y > new_sprite.source_y
            source_y = new_sprite.source_y
            source_h = current_sprite.source_y - new_sprite.source_y + [new_sprite.source_h, current_sprite.source_h].min
          else
            source_y = current_sprite.source_y
            source_h = new_sprite.source_y - current_sprite.source_y + [new_sprite.source_h, current_sprite.source_h].min
          end

          # rect_x = (relative_x).ifloor(rect_size.w + column_gap)
          # rect_y = (relative_y).ifloor(rect_size.h + row_gap)
          # puts "Rows: #{rows}, Columns: #{columns}"

          new_sprite = new_sprite.merge({
            source_x: source_x,
            source_y: source_y,
            source_w: source_w,
            source_h: source_h,
          })

          if args.inputs.mouse.click
            @virtual_sprite_selection = nil
          else
            @virtual_sprite_selection = {
              x: spritesheet.x + new_sprite.source_x,
              y: spritesheet.y + new_sprite.source_y,
              w: new_sprite.source_w,
              h: new_sprite.source_h,
              path: :pixel,
              r: 255,
              g: 255,
              b: 255,
              a: 64,
              # blendmode_enum: 0,
            }
          end
        else
          @virtual_sprite_selection = nil
        end

        if args.inputs.mouse.click
          @state.current_sprite = new_sprite
          @state.current_sprite.spritesheet = spritesheet
        end

        @hover_rect_screen = @state.camera.to_screen_space(@hover_rect)

        label_size = 20
        label = {
          x: spritesheet_screen.x + (spritesheet_screen.w / 2),
          y: spritesheet_screen.y + spritesheet_screen.h + label_size,
          text: "#{spritesheet.path}",
          primitive_marker: :label,
          size_px: label_size,
          r: 255,
          b: 255,
          g: 255,
          a: 255,
          anchor_x: 0.5,
          anchor_y: 0.5,
          scale_quality_enum: 2
        }
        label_w, label_h = GTK.calcstringbox(label.text, size_px: label_size)
        label_background = label.merge({
          w: label_w + 16,
          h: label_h + 8,
          anchor_x: 0.5,
          anchor_y: 0.5,
          primitive_marker: :solid,
          r: 0,
          b: 0,
          g: 0,
          a: 255,
        })
        @state.draw_buffer[@state.camera_path].concat([
          label_background,
          label,
        ])
      end

      if @virtual_sprite_selection
        @state.draw_buffer[@state.camera_path] << @state.camera.to_screen_space(@virtual_sprite_selection)
      end


      if @state.current_sprite
        @current_sprite_selection = {
          x: @state.current_sprite.spritesheet.x + @state.current_sprite.source_x,
          y: @state.current_sprite.spritesheet.y + @state.current_sprite.source_y,
          w: @state.current_sprite.source_w,
          h: @state.current_sprite.source_h,
          path: :pixel,
          r: 50,
          g: 50,
          b: 50,
          a: 128,
        }

        @state.draw_buffer[@state.camera_path] << @state.camera.to_screen_space(@current_sprite_selection)
      end
    end

    def render_current_sprite(args)
      current_sprite = @state.current_sprite
      if current_sprite
        current_sprite.w = current_sprite.source_w
        current_sprite.h = current_sprite.source_h
        current_sprite.x = @state.world_mouse.x - (@state.current_sprite.w / 2)
        current_sprite.y = @state.world_mouse.y - (@state.current_sprite.h / 2)
        # args.outputs.debug << { x: @state.camera.x, y: @state.camera.y }.to_s

        # prefab stuff.
        if @state.current_sprite.prefab && @state.current_sprite.prefab.length > 0
          prefab = SpriteMethods.render_prefab(@state.current_sprite).map do |sprite|
            @state.camera.to_screen_space(sprite)
          end
          @state.draw_buffer[@state.camera_path].sprites.concat(prefab)
        else
          @state.draw_buffer[@state.camera_path].sprites << @state.camera.to_screen_space(@state.current_sprite)
        end

        # @state.draw_buffer[@state.camera_path].sprites << @state.camera.to_screen_space(@state.current_sprite)
      end
    end

    # def render_grid_lines(args)
    #   grid_border_size = 1
    #   tile_size = 16

    #   rows = 80
    #   columns = 80
    #   width = tile_size * rows
    #   height = tile_size * columns

    #   if Kernel.tick_count == 0
    #     args.outputs[:grid].w = width
    #     args.outputs[:grid].h = height
    #     args.outputs[:grid].background_color = [0, 0, 0, 0]
    #     @grid = []
    #     height.idiv(tile_size).each do |x|
    #       width.idiv(tile_size).each do |y|
    #         @grid << { line_type: :horizontal, x: x * tile_size, y: y * tile_size, w: tile_size, h: grid_border_size, r: 200, g: 200, b: 200, a: 255, primitive_marker: :sprite, path: :pixel }
    #         @grid << { line_type: :vertical, x: x * tile_size, y: y * tile_size, w: grid_border_size, h: tile_size, r: 200, g: 200, b: 200, a: 255, primitive_marker: :sprite, path: :pixel  }
    #       end
    #     end
    #   end

    #   if !@show_grid
    #     return
    #   end

    #   if @state.camera.scale != @current_scale
    #     @current_scale = @state.camera.scale

    #     if @state.camera.scale < 1
    #       border_size = (grid_border_size / @state.camera.scale).ceil
    #     else
    #       border_size = grid_border_size
    #     end

    #     grid_border_size = border_size

    #     @grid.each do |line|
    #       line.w = grid_border_size if line[:line_type] == :vertical
    #       line.h = grid_border_size if line[:line_type] == :horizontal
    #     end

    #     # Update the grid with new widths.
    #     @state.draw_buffer[:grid].concat(@grid)
    #   end

    #   @grid_boxes ||= 10.flat_map do |x|
    #     10.map do |y|
    #       { x: (x - 5) * 1280, y: (y - 5) * 1280, w: 1280, h: 1280, path: :grid, r: 0, b: 0, g: 0, a: 64 }
    #     end
    #   end

    #   if @hover_rect_screen
    #     @hover_rect_screen.w += grid_border_size + 2
    #     @hover_rect_screen.h += grid_border_size + 2
    #   end

    #   @state.draw_buffer[@state.camera_path].sprites.concat(@grid_boxes.map do |rect|
    #     @state.camera.to_screen_space(rect)
    #   end)
    # end

    def sprite_out_of_bounds?(sprite, rect)
      return true if sprite.source_x < 0
      return true if sprite.source_y < 0
      return true if sprite.source_x + sprite.source_w > rect.w
      return true if sprite.source_y + sprite.source_h > rect.h

      false
    end
  end # Canvas
end # SpriteKit
