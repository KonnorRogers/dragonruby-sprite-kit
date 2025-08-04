require SpriteKit.to_load_path("string_cache")
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

      @counters = {
        tile_selection_w: {
          label: proc { { id: :tile_selection_w, text: "  w: #{@state.tile_selection.w}" } },
          increment: proc { @state.tile_selection.w += 1 },
          decrement: proc { @state.tile_selection.w -= 1 }
        },
        tile_selection_h: {
          label: proc { { id: :tile_selection_h, text: "  h: #{@state.tile_selection.h}" } },
          increment: proc { @state.tile_selection.h += 1 },
          decrement: proc { @state.tile_selection.h -= 1 }
        },
        row_gap: {
          label: proc { { id: :row_gap, text: "row_gap: #{@state.tile_selection.row_gap}" } },
          increment: proc { @state.tile_selection.row_gap += 1 },
          decrement: proc { @state.tile_selection.row_gap -= 1 }
        },
        column_gap: {
          label: proc { { id: :column_gap, text: "column_gap: #{@state.tile_selection.column_gap}" } },
          increment: proc { @state.tile_selection.column_gap += 1 },
          decrement: proc { @state.tile_selection.column_gap -= 1 }
        },
        offset_x: {
          label: proc { { id: :offset_x, text: "offset_x: #{@state.tile_selection.offset_x}" } },
          increment: proc { @state.tile_selection.offset_x += 1 },
          decrement: proc { @state.tile_selection.offset_x -= 1 }
        },
        offset_y: {
          label: proc { { id: :offset_y, text: "offset_y: #{@state.tile_selection.offset_y}" } },
          increment: proc { @state.tile_selection.offset_y += 1 },
          decrement: proc { @state.tile_selection.offset_y -= 1 }
        },
        source_x: {
          label: proc { { id: :source_x, text: "source_x: #{@state.current_sprite.source_x}" } },
          increment: proc { @state.current_sprite.source_x += 1 },
          decrement: proc { @state.current_sprite.source_x -= 1 }
        },
        source_y: {
          label: proc { { id: :source_y, text: "source_y: #{@state.current_sprite.source_y}" } },
          increment: proc { @state.current_sprite.source_y += 1 },
          decrement: proc { @state.current_sprite.source_y -= 1 }
        },
        source_w: {
          label: proc { { id: :source_w, text: "source_w: #{@state.current_sprite.source_w}" } },
          increment: proc { @state.current_sprite.source_w += 1 },
          decrement: proc { @state.current_sprite.source_w -= 1 }
        },
        source_h: {
          label: proc { { id: :source_h, text: "source_h: #{@state.current_sprite.source_h}" } },
          increment: proc { @state.current_sprite.source_h += 1 },
          decrement: proc { @state.current_sprite.source_h -= 1 }
        }
      }
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
        { text: "brush: { " },
        @counters.tile_selection_w.label.call,
        @counters.tile_selection_h.label.call,
        { text: "}" } ,
        @counters.offset_x.label.call,
        @counters.offset_y.label.call,
        @counters.column_gap.label.call,
        @counters.row_gap.label.call,
      ]

      if @state.current_sprite
        text.concat([
          { text: "" },
          @counters.source_x.label.call,
          @counters.source_y.label.call,
          @counters.source_w.label.call,
          @counters.source_h.label.call,
          { text: "path: #{@state.current_sprite.path}" },
          { text: "" },
          { text: "Spritesheet Properties:" },
          { text: "w: #{@state.current_sprite.spritesheet.w}" },
          { text: "h: #{@state.current_sprite.spritesheet.h}" },
        ])
      end

      text.each_with_index do |label, index|
        label.x = 20
        label.y = @h - 40
        label.primitive_marker = :label
        label.anchor_y = 0.5 + index * 1.75
      end

      counter_buttons = []
      @counters.each do |key, counter|
        hash = text.find { |hash| hash[:id] == key }

        next if !hash

        label_w, label_h = SpriteKit::StringCache.get(hash.text)

        anchored_label = { x: hash.x, y: hash.y, w: label_w, h: label_h }
        anchored_label = anchored_label.anchor_rect(hash&.anchor_x || 0, hash&.anchor_y || 0)
        row_gap = 8
        btn_x = anchored_label.x + row_gap + label_w
        btn_y = anchored_label.y

        gap = 20
        decrement_button = {
          x: btn_x + gap,
          y: btn_y,
          w: 16,
          h: 16,
          path: SpriteKit.to_load_path("sprites/minus-sprite.png")
        }

        gap = 20
        increment_button = decrement_button.merge({
          x: decrement_button.x + decrement_button.w + gap,
          y: decrement_button.y,
          path: SpriteKit.to_load_path("sprites/plus-sprite.png")
        })

        counter_buttons << increment_button
        counter_buttons << decrement_button

        if args.inputs.mouse.click || args.inputs.mouse.buttons.left.held
          if args.inputs.mouse.intersect_rect?(increment_button)
            if args.inputs.mouse.click
              counter.increment.call
            elsif args.inputs.mouse.buttons.left.held
              start_tick = args.inputs.mouse.buttons.left.click_at
              current_tick = Kernel.tick_count

              diff = (current_tick - (start_tick + 75))
              if diff > 0 && diff % 4 == 0
                counter.increment.call
              end
            end
          elsif args.inputs.mouse.intersect_rect?(decrement_button)
            if args.inputs.mouse.click
              counter.decrement.call
            elsif args.inputs.mouse.buttons.left.held
              start_tick = args.inputs.mouse.buttons.left.click_at
              current_tick = Kernel.tick_count

              diff = (current_tick - (start_tick + 75))
              if diff > 0 && diff % 4 == 0
                counter.decrement.call
              end
            end
          end
        end
      end

      @state.draw_buffer[@render_path]
        .concat(text)
        .concat(counter_buttons)

      # need this top-layer
      # path = labels[-5]
      # if path && current_sprite
      #   text_width, text_height = GTK.calcstringbox(path.text)
      #   path_rect = path.merge({
      #     w: text_width,
      #     h: text_height,
      #   })
      #   if args.inputs.mouse.intersect_rect?(serialize) && args.inputs.mouse.intersect_rect?(path_rect)
      #     solid = {
      #         x: path_rect.x,
      #         y: path_rect.y,
      #         w: path_rect.w,
      #         h: path_rect.h,
      #         r: 0,
      #         b: 0,
      #         g: 0,
      #         a: 255,
      #         primitive_marker: :solid
      #     }.anchor_rect(path_rect.anchor_x || 0, path_rect.anchor_y || 0)
      #     solid.x -= 4
      #     solid.y -= 4
      #     solid.w += 8
      #     solid.h += 8

      #     @state.draw_buffer[:top_layer].concat([
      #       solid,
      #       {
      #         x: path_rect.x,
      #         y: path_rect.y,
      #         text: path_rect.text,
      #         primitive_marker: :label,
      #         anchor_y: path_rect.anchor_y,
      #         r: 255,
      #         g: 255,
      #         b: 255,
      #         a: 255,
      #       }.label!,
      #     ])
      #   end
      # end
      @state.draw_buffer.primitives << self.serialize
    end
  end
end
