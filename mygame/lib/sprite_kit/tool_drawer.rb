require SpriteKit.to_load_path(File.join("ui", "button.rb"))

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

      counters = {
        tile_selection_w: {
          label: { text: "  w: #{@state.tile_selection.w}" },
          increment: proc { @state.tile_selection.w += 1 },
          decrement: proc { @state.tile_selection.w -= 1 }
        },
        tile_selection_h: {
          label: { text: "  h: #{@state.tile_selection.h}" },
          increment: proc { @state.tile_selection.h += 1 },
          decrement: proc { @state.tile_selection.h -= 1 }
        },
        row_gap: {
          label: { text: "row_gap: #{@state.tile_selection.row_gap}" },
          increment: proc { @state.tile_selection.row_gap += 1 },
          decrement: proc { @state.tile_selection.row_gap -= 1 }
        },
        column_gap: {
          label: { text: "column_gap: #{@state.tile_selection.column_gap}" },
          increment: proc { @state.tile_selection.column_gap += 1 },
          decrement: proc { @state.tile_selection.column_gap -= 1 }
        },
        offset_x: {
          label: { text: "offset_x: #{@state.tile_selection.offset_x}" },
          increment: proc { @state.tile_selection.offset_x += 1 },
          decrement: proc { @state.tile_selection.offset_x -= 1 }
        },
        offset_y: {
          label: { text: "offset_y: #{@state.tile_selection.offset_y}" },
          increment: proc { @state.tile_selection.offset_y += 1 },
          decrement: proc { @state.tile_selection.offset_y -= 1 }
        }
      }

      text = [
        { text: "brush: { " },
        counters.tile_selection_w.label,
        counters.tile_selection_h.label,
        { text: "}" } ,
        counters.offset_x.label,
        counters.offset_y.label,
        counters.column_gap.label,
        counters.row_gap.label,
        { text: "" }
      ]

      current_sprite = @state.current_sprite
      if current_sprite
        counters.merge!({
          source_x: {
            label: { text: "source_x: #{current_sprite.source_x}" },
            increment: proc { @state.tile_selection.source_x += 1 },
            decrement: proc { @state.tile_selection.source_x -= 1 }
          },
          source_y: {
            label: { text: "source_y: #{current_sprite.source_y}" },
            increment: proc { @state.tile_selection.source_y += 1 },
            decrement: proc { @state.tile_selection.source_y -= 1 }
          },
          source_w: {
            label: { text: "source_w: #{current_sprite.source_w}" },
            increment: proc { @state.tile_selection.source_w += 1 },
            decrement: proc { @state.tile_selection.source_w -= 1 }
          },
          source_h: {
            label: { text: "source_h: #{current_sprite.source_h}" },
            increment: proc { @state.tile_selection.source_h += 1 },
            decrement: proc { @state.tile_selection.source_h -= 1 }
          },
        })
        text.concat([
          counters.source_x.label,
          counters.source_y.label,
          counters.source_w.label,
          counters.source_h.label,
          { text: "path: #{current_sprite.path}" }
        ])

        spritesheet = current_sprite.spritesheet
        text.concat([
          { text: "" },
          { text: "Spritesheet Properties:" },
          { text: "w: #{spritesheet.w}" },
          { text: "h: #{spritesheet.h}" },
        ])
      end

      text.each_with_index do |label, index|
        label.x = 20
        label.y = @h - 40
        label.primitive_marker = :label
        label.anchor_y = 0.5 + index * 1.5
      end

      counter_buttons = []
      counters.each do |key, counter|
        label = counter.label

        label_w, label_h = GTK.calcstringbox(label.text)
        anchored_label = { x: label.x, y: label.y, w: label_w, h: label_h }.anchor_rect(label.anchor_x || 0, label.anchor_y || 0)
        row_gap = 8
        btn_x = anchored_label.x + row_gap + label_w
        btn_y = anchored_label.y

        increment_button = ::SpriteKit::UI::Button.new(args: args, id: key.to_s + "__increment", label: { text: "blah" }, x: btn_x, y: btn_y, padding: 0)
        # increment_button = Primitives.button(args, id: key.to_s + "__increment", text: "blah")
        increment_button.x = btn_x
        increment_button.y = btn_y


        counter_buttons << increment_button
        # if args.inputs.mouse.intersect_rect?(increment_button)
        # end
        # if args.inputs.mouse.intersect_rect?(increment_button)
        # end
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
    end
  end
end
