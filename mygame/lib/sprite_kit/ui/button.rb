require SpriteKit.to_load_path("primitives")

module SpriteKit
  module UI
    class Button
      attr_sprite
      attr_accessor :id,
                    :label,
                    :sprite,
                    :args,
                    :background,
                    :text_color,
                    :border_color,
                    :border_width,
                    :padding,
                    :font,
                    :created_at

      def self.buttons
        @buttons ||= {}
      end

      def new(*splat, args:, id: nil, **kwargs, &block)
        return super(*splat, args: args, id: nil, **kwargs, &block) if !id

        cached_button = Button.buttons[id.to_sym]
        cached_button.args = args
        return cached_button if cached_button

        super(*splat, args: args, id: id, **kwargs, &block)
      end

      def initialize(
        **kwargs
      )
        if id
          id = id.to_sym
        end
        # render_targets only need to be created once, we use the the id to determine if the texture
        # has already been created
        cached_button = Button.buttons[id]
        if cached_button
          cached_button.args = args
          return
        end

        force_render(**kwargs)
      end

      def force_render(
        args:,
        label:,
        id: nil,
        w: nil,
        h: nil,
        path: nil,
        background: {r: 0, g: 0, b: 0, a: 0},
        text_color: {r: 0, g: 0, b: 0, a: 255},
        border_color: {r: 0, g: 0, b: 0, a: 255},
        border_width: 1,
        padding: {
          top: 8,
          right: 8,
          bottom: 8,
          left: 8,
        },
        font: nil,
        **kwargs
      )
        kwargs.each do |key, value|
          instance_variable_set(("@" + key.to_s).to_sym, value)
        end

        if padding.is_a?(::Numeric)
          padding = {
            top: padding,
            left: padding,
            right: padding,
            bottom: padding,
          }
        end

        @label = label
        if w.nil? && h.nil?
          w, h = GTK.calcstringbox(@label.text, size_enum: @label.size_enum || 0, font: @label.font || @font)
          w += padding.left + padding.right
          h += padding.top + padding.bottom
        end

        # original_w = w
        @w = w
        @h = h

        @id = (id.to_sym || GTK.create_uuid.to_sym)
        @path = path || ("SpriteKit::Button__" + self.id.to_s).to_sym

        @background = background
        @text_color = text_color
        @border_color = border_color
        @border_width = border_width
        @padding = padding
        @font = font

        # define the w/h of the texture
        @args = args
        @args.outputs[@path].w = @w
        @args.outputs[@path].h = @h

        label = {
          x: @w / 2,
          y: @h / 2,
          vertical_alignment_enum: 1, alignment_enum: 1,
          primitive_marker: :label,
          text: @label.text,
          # **@text_color
        }

        @args.outputs[@path].labels << label

        # create a label centered vertically and horizontally within the texture
        # args.outputs[render_target_id].labels <<

        # if the render_target hasn't been created, then generate it and store it in the created_buttons cache
        @created_at = Kernel.tick_count
        Button.buttons[id] = self
        self
      end

      def prefab
        label = {
          x: @w / 2,
          y: @h / 2,
          vertical_alignment_enum: 1, alignment_enum: 1,
          primitive_marker: :label,
          text: @label.text,
          # **@text_color
        }

        border_width_half = @border_width.idiv(2)
        solid_background = {
          x: border_width_half, y: 0,
          w: @w - @border_width,
          h: @h - @border_width,
          path: :pixel,
          **@background,
          r: 255,
          g: 0,
          b: 0,
          a: 64,
        }

        [
          # solid_background,
          # *Primitives.borders(solid_background, border_width: border_width, color: border_color).values,
          label,
        ]
      end
    end
  end
end
