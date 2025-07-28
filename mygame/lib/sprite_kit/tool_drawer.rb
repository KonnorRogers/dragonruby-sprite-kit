module SpriteKit
  class ToolDrawer
    attr_accessor :state, :render_path, :w, :h, :x, :y

    def initialize(state:)
      @tools = [
        :sprite,
      ]
      @render_path = :tool_drawer
      @state = state

      @x = 0
      @y = 0
      @h = Grid.h
      @w = (Grid.w / 5).ceil
    end

    def serialize
      {
        x: @x,
        y: @y,
        w: @w,
        h: @h,
        path: @render_path
      }
    end

    def tick(args)
      input(args)
      calc(args)
      render(args)
    end

    def input(args)
      # if @render_target && @current_sprite && args.inputs.click && @world_mouse.intersect_rect?(@render_path)
      #   @world_mouse
      # end
    end

    def calc(args)
    end

    def render(args)
      @render_target = args.outputs[@render_path]
      @render_target.background_color = { r: 255, g: 255, b: 255, a: 255 }
      @render_target.w = @w
      @render_target.h = @h

      text = [
        "brush: { w: #{@state.tile_selection.w}, h: #{@state.tile_selection.h} }",
        "row_gap: #{@state.tile_selection.row_gap}",
        "column_gap: #{@state.tile_selection.column_gap}",
        "offset_x: #{@state.tile_selection.offset_x}",
        "offset_y: #{@state.tile_selection.offset_y}",
        ""
      ]
      labels = []

      current_sprite = @state.current_sprite
      if current_sprite
        text.concat([
          "source_x: #{current_sprite.source_x}",
          "source_y: #{current_sprite.source_y}",
          "source_w: #{current_sprite.source_w}",
          "source_h: #{current_sprite.source_h}",
          "path: #{current_sprite.path}"
        ])

      end

      text.each_with_index do |str, index|
        labels << {
          x: 20,
          y: @h - 40 - (index * 40),
          text: str,
          primitive_marker: :label
        }
      end

      @state.draw_buffer[@render_path].concat(labels)

      # need this top-layer
      path = labels[-1]
      if path && current_sprite
        text_width, text_height = GTK.calcstringbox(path.text)
        path_rect = path.merge({
          w: text_width,
          h: text_height,
          y: path.y - text_height
        })
        if args.inputs.mouse.intersect_rect?(serialize) && args.inputs.mouse.intersect_rect?(path_rect)
          @state.draw_buffer[:top_layer].concat([
            {
              x: path_rect.x - 4,
              y: path_rect.y + path_rect.h + 4,
              w: path_rect.w + 8,
              h: path_rect.h + 8,
              r: 0,
              b: 0,
              g: 0,
              a: 255,
              anchor_y: 1,
              primitive_marker: :solid
            },
            {
              x: path_rect.x,
              y: path_rect.y + path_rect.h,
              text: path_rect.text,
              primitive_marker: :label,
              r: 255,
              g: 255,
              b: 255,
              a: 255,
            }.label!,
          ])
        end
      end
    end
  end
end
