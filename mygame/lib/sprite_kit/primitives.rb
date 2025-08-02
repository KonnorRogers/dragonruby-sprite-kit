module SpriteKit
  class Primitives
    attr_accessor :created_buttons

    def self.cache
      @cache ||= {}
    end

    def self.button(
      args,
      id: nil,
      text: nil,
      w: nil,
      h: nil,
      size_enum: nil,
      font: nil,
      path: nil
    )
      if !id
        id = GTK.create_uuid.to_s.to_sym
      else
        id = id.to_sym
      end

      path = (path || ("SpriteKit::Button__" + id.to_s)).to_sym

      # render_targets only need to be created once, we use the the id to determine if the texture
      # has already been created
      cached_button = self.cache[id]
      return cached_button if cached_button

      if w.nil? && h.nil?
        w, h = GTK.calcstringbox(text, size_enum: size_enum || 0, font: font || nil)
      end

      # if the render_target hasn't been created, then generate it and store it in the created_buttons cache
      self.cache[id] = {
        created_at: Kernel.tick_count,
        id: id,
        w: w,
        h: h,
        text: text,
        path: path,
      }

      # define the w/h of the texture
      args.outputs[path].w = w
      args.outputs[path].h = h

      # create a border
      borders = self.borders({x: 0, y: 0, w: w, h: h }).values
      args.outputs[path].sprites.concat(borders)

      # create a label centered vertically and horizontally within the texture
      args.outputs[path].labels << { x: w / 2, y: h / 2, text: text, vertical_alignment_enum: 1, alignment_enum: 1 }

      self.cache[id]
    end

    def self.borders(rect, padding: nil, border_width: 1, color: { r: 0, b: 0, g: 0, a: 255 })
      if padding && padding.is_a?(Numeric) && padding > 0
        padding = {
          top: padding,
          right: padding,
          bottom: padding,
          left: padding
        }
      end

      if padding.is_a?(Hash)
        rect = rect.merge({
          x: rect.x - padding.left,
          y: rect.y - padding.bottom,
          w: rect.w + padding.left + padding.right,
          h: rect.h + padding.top + padding.bottom
        })
      end

      {
        top: {
          # top
          x: rect.x,
          w: rect.w,
          y: rect.y + rect.h,
          h: border_width,
          **color,
        },
        right: {
          # right
          x: rect.x + rect.w - border_width,
          w: border_width,
          y: rect.y,
          h: rect.h,
          **color,
        },
        bottom: {
          # bottom
          x: rect.x,
          w: rect.w,
          y: rect.y,
          h: border_width,
          **color,
        },
        left: {
          # left
          x: rect.x,
          w: border_width,
          y: rect.y,
          h: rect.h,
          **color,
        }
      }.each_value do |hash|
        hash[:primitive_marker] = :sprite
        hash[:path] = :pixel
      end
    end
  end
end
