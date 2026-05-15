module SpriteKit
  class TreeRenderer
    INDENT_SIZE = 20
    ROW_HEIGHT = 24
    FONT_SIZE = 14
    ICON_SIZE = 16

    # Colors
    COLOR_BG         = { r: 30,  g: 30,  b: 40,  a: 255 }
    COLOR_HOVER      = { r: 60,  g: 60,  b: 80,  a: 255 }
    COLOR_TEXT       = { r: 220, g: 220, b: 220, a: 255 }
    COLOR_DIR_ICON   = { r: 255, g: 200, b: 80,  a: 255 }
    COLOR_FILE_ICON  = { r: 140, g: 200, b: 255, a: 255 }

    def initialize(tree, state: {})
      # node_path (array of names) => collapsed bool
      @collapsed = {}
      @tree = tree
      @state = state
    end

    # Call this from your tick, passing args and the Tree
    def render(args, offset_x: 0, offset_y: 0)
      @mouse = args.inputs.mouse
      @rows  = []
      tree = @tree

      # Walk the tree and collect visible rows
      collect_rows(tree.root_node, depth: 0)

      # Background panel
      panel_h = [@rows.length * ROW_HEIGHT, 100].max
      @primitives = []
      @primitives << {
        x: offset_x, y: args.grid.h - panel_h,
        w: Grid.w - offset_x, h: panel_h,
        **COLOR_BG
      }.solid!

      # Render each row bottom-up (DragonRuby y=0 is bottom)
      @rows.each_with_index do |row, i|
        y = args.grid.h - ROW_HEIGHT * (i + 1) + offset_y
        render_row(@primitives, row, y, offset_x: offset_x)
      end

      @primitives
    end

    private

    def node_key(node)
      node.value[:path] || node.value[:name]
    end

    def collapsed?(node)
      @collapsed.fetch(node_key(node), false)
    end

    def collect_rows(node, depth:)
      return unless node
      @rows << { node: node, depth: depth }

      if node.value[:type] == :directory && !collapsed?(node)
        node.children.each { |child| collect_rows(child, depth: depth + 1) }
      end
    end

    def render_row(primitives, row, y, offset_x: 0)
      node   = row[:node]
      depth  = row[:depth]
      is_dir = node.value[:type] == :directory
      label  = File.basename(node.value[:path].to_s)
      x      = offset_x + 8 + depth * INDENT_SIZE

      hit     = { x: offset_x, y: y, w: Grid.w - offset_x, h: ROW_HEIGHT }
      hovered = point_in_rect?(@mouse, hit)
      center_y = y + ROW_HEIGHT / 2

      if hovered
        primitives << { **hit, r: 60, g: 60, b: 80, a: 200 }.solid!
      end

      if hovered && @mouse.click
        if is_dir
          key = node_key(node)
          @collapsed[key] = !@collapsed.fetch(key, false)
        else
          @state[:next_view] = :canvas
          @state.file_path = node.value[:path]
        end
      end

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
          x: 46 + x, y: center_y,
          text: label,
          size_px: FONT_SIZE,
          anchor_x: 0, anchor_y: 0.5,
          **COLOR_TEXT
        }.label!
      end
    end
    def point_in_rect?(mouse, rect)
      mouse.x >= rect[:x] &&
        mouse.x <= rect[:x] + rect[:w] &&
        mouse.y >= rect[:y] &&
        mouse.y <= rect[:y] + rect[:h]
    end
  end
end
