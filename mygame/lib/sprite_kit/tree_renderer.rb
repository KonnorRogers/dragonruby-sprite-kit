module SpriteKit
  class TreeRenderer
    INDENT_SIZE = 20
    ROW_HEIGHT  = 24
    FONT_SIZE   = 14
    ICON_SIZE   = 16

    # Colors
    COLOR_BG        = { r: 30,  g: 30,  b: 40,  a: 255 }
    COLOR_HOVER     = { r: 60,  g: 60,  b: 80,  a: 200 }
    COLOR_SELECTED  = { r: 80,  g: 80,  b: 120, a: 220 }
    COLOR_CURSOR    = { r: 130, g: 180, b: 255, a: 255 }
    COLOR_TEXT      = { r: 220, g: 220, b: 220, a: 255 }
    COLOR_DIR_ICON  = { r: 255, g: 200, b: 80,  a: 255 }
    COLOR_FILE_ICON = { r: 140, g: 200, b: 255, a: 255 }

    def initialize(tree, state: {})
      @collapsed     = {}
      @tree          = tree
      @state         = state
      @scroll_offset = 0
      @selected_idx  = 0
    end

    # Call this from your tick, passing args
    def render(args, offset_x: 0, offset_y: 0)
      @args  = args
      @mouse = args.inputs.mouse
      @rows  = []

      collect_rows(@tree.root_node, depth: 0)

      handle_scroll(args)
      handle_keyboard(args)

      panel_h = Grid.h

      @primitives = []
      @primitives << {
        x: offset_x, y: args.grid.h - panel_h,
        w: args.grid.w - offset_x, h: panel_h,
        **COLOR_BG
      }.solid!

      @rows.each_with_index do |row, i|
        y = args.grid.h - ROW_HEIGHT * (i + 1) + offset_y + @scroll_offset
        next if y + ROW_HEIGHT < 0 || y > args.grid.h
        render_row(@primitives, row, i, y, offset_x: offset_x)
      end

      @primitives
    end

    private

    def handle_scroll(args)
      max_scroll = [(@rows.length * ROW_HEIGHT) - args.grid.h + ROW_HEIGHT, 0].max
      wheel_delta = args.inputs.mouse.wheel&.y.to_i * 3 * ROW_HEIGHT
      @scroll_offset = (@scroll_offset - wheel_delta).clamp(0, max_scroll)
    end

    def scroll_to_selected(args)
      row_top     = @selected_idx * ROW_HEIGHT
      row_bottom  = row_top + ROW_HEIGHT
      view_top    = @scroll_offset
      view_bottom = @scroll_offset + args.grid.h

      if row_top < view_top
        @scroll_offset = row_top
      elsif row_bottom > view_bottom
        @scroll_offset = row_bottom - args.grid.h
      end
    end

    # ---------------------------------------------------------------------------
    # Keyboard navigation
    # ---------------------------------------------------------------------------

    def handle_keyboard(args)
      return if @rows.empty?

      kbd = args.inputs.keyboard

      if kbd.key_down.up || kbd.key_repeat.up
        @selected_idx = (@selected_idx - 1).clamp(0, @rows.length - 1)
        scroll_to_selected(args)
      end

      if kbd.key_down.down || kbd.key_repeat.down
        @selected_idx = (@selected_idx + 1).clamp(0, @rows.length - 1)
        scroll_to_selected(args)
      end

      if kbd.key_down.enter || kbd.key_down.space
        activate_row(@rows[@selected_idx], source: :keyboard)
      end

      # Left arrow collapses a dir; right arrow expands it
      if kbd.key_down.left
        row = @rows[@selected_idx]
        if row && row.node.value.type == :directory
          @collapsed[node_key(row.node)] = true
        end
      end

      if kbd.key_down.right
        row = @rows[@selected_idx]
        if row && row.node.value.type == :directory
          @collapsed[node_key(row.node)] = false
        end
      end
    end

    # @!parse
    #   # @!attribute node
    #   #   @return [Node]
    #   # @!attribute depth
    #   #   @return [Integer]
    #   class Row; end

    # @param [:keyboard, :mouse] source
    # @param [Row] row
    def activate_row(row, source:)
      return unless row

      node   = row.node
      is_dir = node.value.type == :directory

      if is_dir
        key = node_key(node)
        @collapsed[key] = !@collapsed.fetch(key, false)
      else
        # 30 frames is equivalent to 500ms, we use a static number to not always do the division ourselves.
        elapsed_ticks_for_double_click = 30
        if source == :mouse && @mouse.click && @mouse.previous_click && (@mouse.click.created_at - @mouse.previous_click.created_at) <= elapsed_ticks_for_double_click
          @state.next_view = :canvas
          @state.file_path = node.value.path
        elsif source == :keyboard
          @state.next_view = :canvas
          @state.file_path = node.value.path
        end
      end
    end

    def node_key(node)
      node.value.path
    end

    def collapsed?(node)
      @collapsed.fetch(node_key(node), true)
    end

    def collect_rows(node, depth:)
      return unless node

      @rows << { node: node, depth: depth }

      if node.value.type == :directory && !collapsed?(node)
        node.children.each { |child| collect_rows(child, depth: depth + 1) }
      end
    end

    def render_row(primitives, row, index, y, offset_x: 0)
      node = row.node
      depth = row.depth
      is_dir = node.value.type == :directory
      label = File.basename(node.value.path.to_s)
      x = offset_x + 8 + depth * INDENT_SIZE

      hit     = { x: offset_x, y: y, w: @args.grid.w - offset_x, h: ROW_HEIGHT }
      hovered = @mouse.intersect_rect?(hit)

      # Mouse hover updates the keyboard cursor so the two stay in sync
      if @mouse.click && hovered
        @selected_idx = index
      end

      selected = (index == @selected_idx)

      # Row background
      if selected || hovered
        bg = selected ? COLOR_SELECTED : COLOR_HOVER
        primitives << { **hit, **bg }.solid!
      end

      # 3-px accent bar on the left edge for the keyboard-selected row
      if selected
        primitives << {
          x: offset_x, y: y,
          w: 3, h: ROW_HEIGHT,
          **COLOR_CURSOR
        }.solid!
      end

      # Mouse click
      activate_row(row, source: :mouse) if hovered && @mouse.click

      center_y = y + ROW_HEIGHT / 2

      if is_dir
        arrow = collapsed?(node) ? "▶" : "▼"

        primitives << {
          x: x, y: center_y,
          text: arrow,
          size_px: 10,
          anchor_x: 0, anchor_y: 0.5,
          **COLOR_DIR_ICON
        }.label!

        primitives << {
          x: x + 14, y: center_y,
          text: "[DIR]",
          size_px: FONT_SIZE,
          anchor_x: 0, anchor_y: 0.5,
          **COLOR_DIR_ICON
        }.label!

        primitives << {
          x: x + 60, y: center_y,
          text: label,
          size_px: FONT_SIZE,
          anchor_x: 0, anchor_y: 0.5,
          **COLOR_TEXT
        }.label!
      else
        primitives << {
          x: x, y: center_y,
          text: "[FILE]",
          size_px: FONT_SIZE,
          anchor_x: 0, anchor_y: 0.5,
          **COLOR_FILE_ICON
        }.label!

        primitives << {
          x: x + 46, y: center_y,
          text: label,
          size_px: FONT_SIZE,
          anchor_x: 0, anchor_y: 0.5,
          **COLOR_TEXT
        }.label!
      end
    end

    def point_in_rect?(mouse, rect)
      mouse.x >= rect.x &&
        mouse.x <= rect.x + rect.w &&
        mouse.y >= rect.y &&
        mouse.y <= rect.y + rect.y
    end
  end
end
