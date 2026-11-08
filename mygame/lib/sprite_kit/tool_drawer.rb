require SpriteKit.to_load_path("sprite_methods")
require SpriteKit.to_load_path("string_helper")
require SpriteKit.to_load_path("sprite")

module SpriteKit
  class ToolDrawer
    attr_accessor :state, :render_path, :w, :h, :x, :y
    attr_reader :focus

    class Counter < SpriteKit::Sprite
      INPUT_H = 24
      PAD     = { top: 4, bottom: 0, left: 8, right: 4 }

      def initialize(label:, value: 0, get_value: proc {}, set_value: proc {}, on_increment: proc {}, on_decrement: proc {}, **kwargs)
        super(
          on_increment: on_increment,
          on_decrement: on_decrement,
          get_value: get_value,
          set_value: set_value,
          value: 0,
          **kwargs
        )
        @value = value
        @primitives = { label: { text: label, anchor_y: 0, primitive_marker: :label } }
        @h = INPUT_H + PAD[:top] + PAD[:bottom]
        @last_input_value = value
      end

      def run_tick(args)
        if !@primitives[:input]
          @primitives[:input] = Vendor::Input::Text.new(args, x: @x, y: @y, w: 40, h: INPUT_H, focussed: false)
          @primitives[:input].value.replace(@value.to_s)
        end

        if !@primitives[:decrement_button]
          @primitives.decrement_button = {
            w: 16,
            h: 16,
            path: SpriteKit.to_load_path("sprites/minus-sprite.png"),
            on_click: @on_decrement
          }
        end

        if !@primitives[:increment_button]
          @primitives.increment_button = {
            w: 16,
            h: 16,
            path: SpriteKit.to_load_path("sprites/plus-sprite.png"),
            on_click: @on_increment
          }
        end

        label = @primitives[:label]
        input = @primitives[:input]

        label.x = @x
        label.y = @y + PAD[:bottom]
        label_w, _ = GTK.calcstringbox(label.text)

        @w = @primitives.input.w + label_w + PAD.right + PAD.left

        input.x = @x + label_w + 20
        input.y = @y + PAD[:bottom]             # border extends PAD below input, so lift it
        input.tick
        sync(input)

        @primitives[:decrement_button].tap do |button|
          button.x = input.x + input.w + 20
          button.y = input.y + PAD[:bottom]
        end

        @primitives[:increment_button].tap do |button|
          button.x = @primitives[:decrement_button].x + 32
          button.y = @primitives[:decrement_button].y
        end

        @primitives[:borders] = SpriteKit::Primitives.borders(input, padding: PAD).values
      end

      def sync(input)
        if input.focussed?
          # input -> state, only when the text actually changed
          return if input.value.text == @last_input_value

          @last_input_value = input.value.text.to_s
          @value = input.value.text.to_s
          set_value.call(@value)
        else
          # state -> input
          @value = get_value.call(@value)
          s = @value.to_s

          return if input.value.text.to_s == s

          input.value.replace(s)
          @last_input_value = s.to_s
        end
      end
    end

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
        view_file_tree: proc {
          hash = {
            id: :view_file_tree,
            on_click: proc {
              @state.next_view = :file_tree
            },
            padding: 8,
            text: "View File Tree",
          }

          hash.run_tick = proc {
            @primitives.concat(SpriteKit::Primitives.borders(hash, padding: hash.padding).values)
            click_box = hash.merge({
              x: hash.x - hash.padding,
              y: hash.y - hash.padding,
              w: hash.w + (hash.padding * 2),
              h: hash.h + (hash.padding * 2),
            })

            # @clickables << click_box
            hash.y = hash.y + (hash.padding / 2) + 2
            hash.x = hash.x + (hash.padding / 2) + 2
          }

          hash
        },
        gap_button: proc {
          hash = {
            id: :gap_button,
            text: (@state.current_sprite.prefab ? "Add gap" : "Remove Gap"),
            padding: 4,
            on_click: proc {
              current_sprite = @state.current_sprite

              if current_sprite.prefab
                current_sprite.prefab = nil
              else
                current_sprite.prefab = SpriteKit::SpriteMethods.generate_prefab(current_sprite, @state)
              end
            }
          }
          hash.run_tick = proc {
            @primitives.concat(SpriteKit::Primitives.borders(hash, padding: hash.padding).values)
            click_box = hash.merge({
              x: hash.x - hash.padding,
              y: hash.y - hash.padding,
              w: hash.w + (hash.padding * 2),
              h: hash.h + (hash.padding * 2),
            })

            # @clickables << click_box
            hash.y = hash.y + (hash.padding / 2) + 2
            hash.x = hash.x + (hash.padding / 2) + 2
          }
          hash
        },
        copy_to_clipboard: proc {
          hash = {
            id: :copy_to_clipboard,
            text: "Copy to clipboard",
            padding: 4,
            on_click: proc {
              str = SpriteMethods.serialize_sprite(@state.current_sprite, :ruby)
              str = str.slice(2..-4) + ","
              GTK.exec("echo \"#{str}\" | pbcopy")
              # DR.misc_ffi.set_clipboard(str)
            }
          }

          hash.run_tick = proc {
            @primitives.concat(SpriteKit::Primitives.borders(hash, padding: hash.padding).values)
            click_box = hash.merge({
              x: hash.x - hash.padding,
              y: hash.y - hash.padding,
              w: hash.w + (hash.padding * 2),
              h: hash.h + (hash.padding * 2),
            })

            # @clickables << click_box
            hash.y = hash.y + (hash.padding / 2) + 2
            hash.x = hash.x + (hash.padding / 2) + 2
          }

          hash
        },
        # save_format: {
        #   label: proc { { id: :save_format, text: "Copy to clipboard" } },
        # }
      }

      counters = [
        { id: :tile_selection_w, label: "w: ", path: [:tile_selection, :w] },
        { id: :tile_selection_h, label: "h: ", path: [:tile_selection, :h] },
        { id: :row_gap, label: "row_gap: ", path: [:tile_selection, :row_gap] },
        { id: :column_gap, label: "col_gap: ", path: [:tile_selection, :column_gap] },
        { id: :offset_x, label: "offset_x: ", path: [:tile_selection, :offset_x] },
        { id: :offset_y, label: "offset_y: ", path: [:tile_selection, :offset_y] },
        { id: :source_x, label: "source_x: ", path: [:current_sprite, :source_x] },
        { id: :source_y, label: "source_y: ", path: [:current_sprite, :source_y] },
        { id: :source_w, label: "source_w: ", path: [:current_sprite, :source_w] },
        { id: :source_h, label: "source_h: ", path: [:current_sprite, :source_h] },
      ]

      @counters = {}
      counters.each do |c|
        @counters[c.id] = Counter.new(
          label: c.label,
          value: @state.dig(*c.path),
          get_value: proc {
            @state.dig(*c.path).to_i
          },
          set_value: proc { |value|
            dig_assign(@state, c.path, value.to_i)
          },
          on_increment: proc {
            val = @state.dig(*c.path)
            dig_assign(@state, c.path, val + 1)
          },
          on_decrement: proc {
            val = @state.dig(*c.path)
            dig_assign(@state, c.path, val - 1)
          }
        )
      end

      @tick_count = 0
    end

    def dig_assign(hash, path, value)
      if path.length <= 0
        return
      end
      *parents, last = path
      parents.reduce(hash) { |h, k| h[k] ||= {} }[last] = value
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
      @clickables = []

      if @tick_count > 0
        @clickables.concat(@counters.values.map do |c|
          [
            c.primitives[:input],
            # c.primitives[:increment_button],
            # c.primitives[:decrement_button],
          ]
        end.flatten)
      end

      input(args)
      calc(args)
      render(args)
      @tick_count += 1
    end

    def input(args)
      if args.inputs.keyboard.key_down.tab
        idx = @state.views.find_index { |view| @state.view == view }
        idx += 1
        idx = 0 if idx >= @state.views.length

        @state.next_view = @state.views[idx]
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

      # args.outputs.debug << "#{@state.tile_selection}"
      # args.outputs.debug << "#{args.inputs.mouse}"

      @primitives = []

      cursor_y = 20.from_top
      cursor_x = 20
      gap = 8

      controls = [
        @buttons.view_file_tree.call,
        { text: "brush: {" },
        @counters.tile_selection_w,
        @counters.tile_selection_h,
        { text: "}" } ,
        @counters.offset_x,
        @counters.offset_y,
        @counters.column_gap,
        @counters.row_gap,
      ]

      # puts @clickables[-1]

      if @state.current_sprite
        controls.concat([
          @buttons.gap_button.call,
          @counters.source_x,
          @counters.source_y,
          @counters.source_w,
          @counters.source_h,
          { text: StringHelper.truncate("path: #{@state.current_sprite.path}", max_width: @w - cursor_x - 5) },
          @buttons.copy_to_clipboard.call,
          { text: "Spritesheet Properties:" },
          { text: "w: #{@state.current_sprite.spritesheet.w}" },
          { text: "h: #{@state.current_sprite.spritesheet.h}" },
        ])
      end

      controls.each do |c|
        calc_size(c)
        c.x = cursor_x
        c.y = cursor_y - c.h # y is the bottom edge, so subtract first
        c.run_tick(args) if c.respond_to?(:run_tick)

        if c.is_a?(Hash) && c[:run_tick].is_a?(Proc)
          c.run_tick.call(args)
        end

        padding = 0
        if can_respond?(c, :padding)
          padding = (c.padding || 0) * 2
        end
        cursor_y = c.y - gap - padding

        if (primitives = attr(c, :primitives))
          render_primitives(primitives.values, @primitives)
        else
          render_primitives(c, @primitives)
        end
      end

      if args.inputs.mouse.click
        @clickables.concat(controls.select do |c|
          c.x && c.y && c.h && c.w
        end)

        clicked_item = Geometry.find_intersect_rect(args.inputs.mouse, @clickables)

        if clicked_item
          if @focus && @focus != attr(clicked_item, :input)
            @focus.blur if @focus.can_respond?(:blur)
          end


          if (on_click = attr(clicked_item, :on_click))
            on_click.call if on_click.is_a?(Proc)
          end

          putz clicked_item.inspect if clicked_item
          if clicked_item.is_a?(Hash)
            clicked_item.focus
            @focus = clicked_item
            # prims = clicked_item.primitives || {}
            # prims&.input&.focus
            # @focus = clicked_item&.primitives&.input
            # puts "#{prims}"
          else
            @focus = nil
          end
        else
          @focus&.blur
        end
      end

      @state.draw_buffer[@render_path]
        .concat(@primitives)


      # prev_y = 0
      # label_gap = 14
      # text.each_with_index do |label, index|
      #   label_w, label_h = GTK.calcstringbox(label.text)
      #   label.w = label_w
      #   label.h = label_h
      #   label.x = label_offset_x
      #   label.y = @h - label_offset_y - prev_y - label_h - (label_gap * index)
      #   label.primitive_marker = :label
      #   label.anchor_y = 0
      #   prev_y += label_h
      # end

      # if args.inputs.mouse.click
      #   focus = Geometry.find_intersect_rect(args.inputs.mouse, text)

      #   if focus
      #     @focus = focus
      #   else
      #     @focus = nil
      #   end
      # end

      # label_offset_x = 20
      # counter_buttons = []
      # button_borders = []

      # @buttons.each do |key, button|
      #   label = text.find { |hash| hash[:id] == key }
      #   if label
      #     button_borders.concat(Primitives.borders(label, padding: 8).values)
      #     if args.inputs.click && args.inputs.mouse.intersect_rect?(label)
      #       button.on_click.call
      #     end
      #   end
      # end

      # @counters.each do |key, counter|
      #   hash = text.find { |hash| hash[:id] == key }

      #   next if !hash

      #   row_gap = 8
      #   btn_x = hash.x + row_gap + hash.w
      #   btn_y = hash.y

      #   gap = 20
      #   decrement_button = {
      #     x: btn_x + gap,
      #     y: btn_y + 5,
      #     w: 16,
      #     h: 16,
      #     path: SpriteKit.to_load_path("sprites/minus-sprite.png")
      #   }

      #   gap = 20
      #   increment_button = decrement_button.merge({
      #     x: decrement_button.x + decrement_button.w + gap,
      #     y: decrement_button.y,
      #     path: SpriteKit.to_load_path("sprites/plus-sprite.png")
      #   })

      #   counter_buttons << increment_button
      #   counter_buttons << decrement_button

      #   if args.inputs.mouse.click || args.inputs.mouse.buttons.left.held
      #     if args.inputs.mouse.intersect_rect?(increment_button)
      #       if args.inputs.mouse.click
      #         counter.increment.call
      #       elsif args.inputs.mouse.buttons.left.held
      #         start_tick = args.inputs.mouse.buttons.left.click_at
      #         current_tick = Kernel.tick_count

      #         diff = (current_tick - (start_tick + 30))
      #         if diff > 0
      #           counter.increment.call
      #         end
      #       end
      #     elsif args.inputs.mouse.intersect_rect?(decrement_button)
      #       if args.inputs.mouse.click
      #         counter.decrement.call
      #       elsif args.inputs.mouse.buttons.left.held
      #         start_tick = args.inputs.mouse.buttons.left.click_at
      #         current_tick = Kernel.tick_count

      #         diff = (current_tick - (start_tick + 30))
      #         if diff > 0
      #           counter.decrement.call
      #         end
      #       end
      #     end
      #   end
      # end

      # @state.draw_buffer[@render_path]
      #   .concat(button_borders)
      #   .concat(text)
      #   .concat(counter_buttons)

      # if @focus
      #   @focus = text.find { |obj| obj.id == @focus.id }
      #   if @focus
      #     @state.draw_buffer[@render_path].concat(
      #       Primitives.borders(@focus, padding: 8).values
      #     )
      #   end
      # end


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
      #         path: :solid
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

    def render_primitives(c, ary = [])
      stack = [c]
      until stack.empty?
        item = stack.pop
        next if item.nil?

        if item.is_a?(Array)
          stack.concat(item.reverse)   # keep original order after pop
        elsif item.is_a?(Hash)
          ary << item                  # a primitive, not a container
        elsif (prims = attr(item, :primitives))
          stack.push(prims)
        else
          ary << item                  # a primitive, not a container
        end
      end
      ary
    end

    def calc_size(c)
      if c.is_a?(Hash)
        if !c.h || !c.w
          c_w, c_h = GTK.calcstringbox(c.text)
          c.w ||= c_w + ((c.padding || 0) * 2)
          c.h ||= c_h + ((c.padding || 0) * 2)
        end
        c[:anchor_y] ||= 0
      end
    end

    def attr(obj, key)
      if obj.respond_to?(:[])
        obj[key]
      elsif obj.respond_to?(key)
        obj.send(key)
      end
    end

    def can_respond?(obj, key)
      if obj.respond_to?(:key?)
        true
      else
        obj.respond_to?(key)
      end
    end
  end
end


