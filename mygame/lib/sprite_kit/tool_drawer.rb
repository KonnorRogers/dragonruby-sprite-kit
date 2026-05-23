require SpriteKit.to_load_path("sprite_methods")
require SpriteKit.to_load_path("string_helper")

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
      @focus = nil

      @buttons = {
        view_file_tree: {
          id: :view_file_tree,
          label: proc { { id: :view_file_tree, text: "View File Tree" } },
          handle_click: proc {
            @state.next_view = :file_tree
          }
        },
        gap_button: {
          id: :gap_button,
          label: proc { { id: :gap_button, text: (@state.current_sprite.prefab ? "Add gap" : "Remove Gap") } },
          handle_click: proc {
            current_sprite = @state.current_sprite

            if current_sprite.prefab
              current_sprite.prefab = nil
            else
              current_sprite.prefab = SpriteKit::SpriteMethods.generate_prefab(current_sprite, @state)
            end
          }
        },
        copy_to_clipboard: {
          id: :copy_to_clipboard,
          label: proc { { id: :copy_to_clipboard, text: "Copy to clipboard" } },
          handle_click: proc {
            str = SpriteMethods.serialize_sprite(@state.current_sprite, :ruby)
            str = str.slice(2..-4) + ","
            GTK.exec("echo \"#{str}\" | pbcopy")
            # DR.misc_ffi.set_clipboard(str)
          }
        },
        # save_format: {
        #   label: proc { { id: :save_format, text: "Copy to clipboard" } },
        # }
      }

      @counters = {
        tile_selection_w: {
          label: proc { { id: :tile_selection_w, text: "  w: #{@state.tile_selection.w}" } },
          increment: proc { @state.tile_selection.w += 1 },
          decrement: proc { @state.tile_selection.w -= 1 },
          handle_text: proc { |text|
            handle_text(@state.tile_selection, :w, text)
          },
          handle_keyboard: proc { |keyboard|
            handle_keyboard(@state.tile_selection, :w, keyboard)
          }
        },
        tile_selection_h: {
          label: proc { { id: :tile_selection_h, text: "  h: #{@state.tile_selection.h}" } },
          increment: proc { @state.tile_selection.h += 1 },
          decrement: proc { @state.tile_selection.h -= 1 },
          handle_text: proc { |text|
            handle_text(@state.tile_selection, :h, text)
          },
          handle_keyboard: proc { |keyboard|
            handle_keyboard(@state.tile_selection, :h, keyboard)
          }
        },
        row_gap: {
          label: proc { { id: :row_gap, text: "row_gap: #{@state.tile_selection.row_gap}" } },
          increment: proc { @state.tile_selection.row_gap += 1 },
          decrement: proc { @state.tile_selection.row_gap -= 1 },
          handle_text: proc { |text|
            handle_text(@state.tile_selection, :row_gap, text)
          },
          handle_keyboard: proc { |keyboard|
            handle_keyboard(@state.tile_selection, :row_gap, keyboard)
          }
        },
        column_gap: {
          label: proc { { id: :column_gap, text: "column_gap: #{@state.tile_selection.column_gap}" } },
          increment: proc { @state.tile_selection.column_gap += 1 },
          decrement: proc { @state.tile_selection.column_gap -= 1 },
          handle_text: proc { |text|
            handle_text(@state.tile_selection, :column_gap, text)
          },
          handle_keyboard: proc { |keyboard|
            handle_keyboard(@state.tile_selection, :column_gap, keyboard)
          }
        },
        offset_x: {
          label: proc { { id: :offset_x, text: "offset_x: #{@state.tile_selection.offset_x}" } },
          increment: proc { @state.tile_selection.offset_x += 1 },
          decrement: proc { @state.tile_selection.offset_x -= 1 },
          handle_text: proc { |text|
            handle_text(@state.tile_selection, :offset_x, text)
          },
          handle_keyboard: proc { |keyboard|
            handle_keyboard(@state.tile_selection, :offset_x, keyboard)
          }
        },
        offset_y: {
          label: proc { { id: :offset_y, text: "offset_y: #{@state.tile_selection.offset_y}" } },
          increment: proc { @state.tile_selection.offset_y += 1 },
          decrement: proc { @state.tile_selection.offset_y -= 1 },
          handle_text: proc { |text|
            handle_text(@state.tile_selection, :offset_y, text)
          },
          handle_keyboard: proc { |keyboard|
            handle_keyboard(@state.tile_selection, :offset_y, keyboard)
          }
        },
        source_x: {
          label: proc { { id: :source_x, text: "source_x: #{@state.current_sprite.source_x}" } },
          increment: proc { @state.current_sprite.source_x += 1 },
          decrement: proc { @state.current_sprite.source_x -= 1 },
          handle_text: proc { |text|
            handle_text(@state.tile_selection, :source_x, text)
          },
          handle_keyboard: proc { |keyboard|
            handle_keyboard(@state.tile_selection, :source_x, keyboard)
          }
        },
        source_y: {
          label: proc { { id: :source_y, text: "source_y: #{@state.current_sprite.source_y}" } },
          increment: proc { @state.current_sprite.source_y += 1 },
          decrement: proc { @state.current_sprite.source_y -= 1 },
          handle_text: proc { |text|
            handle_text(@state.tile_selection, :source_y, text)
          },
          handle_keyboard: proc { |keyboard|
            handle_keyboard(@state.tile_selection, :source_y, keyboard)
          }
        },
        source_w: {
          label: proc { { id: :source_w, text: "source_w: #{@state.current_sprite.source_w}" } },
          increment: proc { @state.current_sprite.source_w += 1 },
          decrement: proc { @state.current_sprite.source_w -= 1 },
          handle_text: proc { |text|
            handle_text(@state.tile_selection, :source_w, text)
          },
          handle_keyboard: proc { |keyboard|
            handle_keyboard(@state.tile_selection, :source_w, keyboard)
          }
        },
        source_h: {
          label: proc { { id: :source_h, text: "source_h: #{@state.current_sprite.source_h}" } },
          increment: proc { @state.current_sprite.source_h += 1 },
          decrement: proc { @state.current_sprite.source_h -= 1 },
          handle_text: proc { |text|
            handle_text(@state.tile_selection, :source_h, text)
          },
          handle_keyboard: proc { |keyboard|
            handle_keyboard(@state.tile_selection, :source_h, keyboard)
          }
        },
      }
    end

    def serialize
      {
        x: @x,
        y: @y,
        w: @w,
        h: @h,
        primitive_marker: :sprite,
        scale_quality_enum: 2,
        path: @render_path
      }
    end

    def tick(args)
      input(args)
      calc(args)
      render(args)
    end

    def input(args)
      if args.inputs.keyboard.key_down.tab
        idx = @state.views.find_index { |view| @state.view == view }
        idx += 1
        idx = 0 if idx >= @state.views.length

        @state.next_view = @state.views[idx]
      end

      if @focus
        counter = @counters[@focus.id]
        if counter
          text = args.inputs.text
          if text.length > 0
            counter.handle_text&.call(text)
          end
          counter.handle_keyboard.call(args.inputs.keyboard)
        end
      else
        # DR.stop_text_input
      end
    end

    def calc(args)
    end

    def render(args)
      @state.draw_buffer.primitives << self.serialize
      render_target = args.outputs[@render_path]
      render_target.background_color = [255, 255, 255, 255]
      render_target.w = @w
      render_target.h = @h


      label_offset_x = 20
      label_offset_y = 40

      text = [
        @buttons.view_file_tree.label.call,
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
          @buttons.gap_button.label.call,
          @counters.source_x.label.call,
          @counters.source_y.label.call,
          @counters.source_w.label.call,
          @counters.source_h.label.call,
          { text: StringHelper.truncate("path: #{@state.current_sprite.path}", max_width: @w - label_offset_x - 5) },
          @buttons.copy_to_clipboard.label.call,
          { text: "Spritesheet Properties:" },
          { text: "w: #{@state.current_sprite.spritesheet.w}" },
          { text: "h: #{@state.current_sprite.spritesheet.h}" },
        ])
      end

      prev_y = 0
      label_gap = 14
      text.each_with_index do |label, index|
        label_w, label_h = GTK.calcstringbox(label.text)
        label.w = label_w
        label.h = label_h
        label.x = label_offset_x
        label.y = @h - label_offset_y - prev_y - label_h - (label_gap * index)
        label.primitive_marker = :label
        label.anchor_y = 0
        prev_y += label_h
      end

      if args.inputs.mouse.click
        focus = Geometry.find_intersect_rect(args.inputs.mouse, text)

        if focus
          @focus = focus
          DR.start_text_input
        else
          @focus = nil
          DR.stop_text_input
        end
      end

      label_offset_x = 20
      counter_buttons = []
      button_borders = []

      @buttons.each do |key, button|
        label = text.find { |hash| hash[:id] == key }
        if label
          button_borders.concat(Primitives.borders(label, padding: 8).values)
          if args.inputs.click && args.inputs.mouse.intersect_rect?(label)
            button.handle_click.call
          end
        end
      end

      @counters.each do |key, counter|
        hash = text.find { |hash| hash[:id] == key }

        next if !hash

        row_gap = 8
        btn_x = hash.x + row_gap + hash.w
        btn_y = hash.y

        gap = 20
        decrement_button = {
          x: btn_x + gap,
          y: btn_y + 5,
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

              diff = (current_tick - (start_tick + 30))
              if diff > 0
                counter.increment.call
              end
            end
          elsif args.inputs.mouse.intersect_rect?(decrement_button)
            if args.inputs.mouse.click
              counter.decrement.call
            elsif args.inputs.mouse.buttons.left.held
              start_tick = args.inputs.mouse.buttons.left.click_at
              current_tick = Kernel.tick_count

              diff = (current_tick - (start_tick + 30))
              if diff > 0
                counter.decrement.call
              end
            end
          end
        end
      end

      @state.draw_buffer[@render_path]
        .concat(button_borders)
        .concat(text)
        .concat(counter_buttons)

      if @focus
        @focus = text.find { |obj| obj.id == @focus.id }
        if @focus
          @state.draw_buffer[@render_path].concat(
            Primitives.borders(@focus, padding: 8).values
          )
        end
      end


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

    def handle_text(obj, key, text)
      val = obj.send(key.to_sym)
      val = "#{val}#{text.join}".to_i
      obj.send("#{key}=".to_sym, val)
    end

    def handle_keyboard(obj, key, keyboard)
      if keyboard.key_down.backspace || keyboard.key_repeat.backspace
        val = obj.send(key.to_sym).to_s
        val = val.slice(0, val.length - 1).to_i
        obj.send("#{key}=".to_sym, val)
      end
    end
  end
end


