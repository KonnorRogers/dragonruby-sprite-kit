module SpriteKit
  class Primitives
    attr_accessor :created_buttons

    def self.button(
      text: nil,
      w: nil,
      h: nil,
      x: nil,
      y: nil,
      size_enum: nil,
      font: nil,
      padding: 0,
      border_width: 0
    )
      if !padding
        padding = 0
      end

      if padding.is_a?(Numeric)
        padding = {
          top: padding,
          right: padding,
          bottom: padding,
          left: padding
        }
      end

      if w == nil && h == nil
        w, h = GTK.calcstringbox(text, size_enum: size_enum || 0, font: font || nil)
        w += (border_width * 2) + padding.left + padding.right
        h += (border_width * 2) + padding.top + padding.bottom
      end

      rect = {
        w: w,
        h: h,
        x: 0,
        y: 0,
        primitive_marker: :sprite,
      }

      # create a label centered vertically and horizontally within the texture
      label = {
        x: x + border_width + padding.left,
        y: y + border_width + padding.bottom,
        text: text,
        size_enum: size_enum,
        anchor_x: 0,
        anchor_y: 0
      }.label!

      primitives = [
        label,
        *Primitives.borders(rect, border_width: border_width, padding: 0).values
      ]

      rect.primitives = primitives

      rect
    end

    def self.borders(rect, padding: nil, border_width: 1, color: { r: 0, b: 0, g: 0, a: 255 })
      if padding && padding.is_a?(Numeric) && padding >= 0
        padding = {
          top: padding,
          right: padding,
          bottom: padding,
          left: padding
        }
      else
        padding = {
          top: 0,
          left: 0,
          right: 0,
          bottom: 0
        }
      end

      {
        top: {
          # top
          x: rect.x - padding.left,
          w: rect.w + padding.left + padding.right,
          y: rect.y + rect.h + padding.top - border_width,
          h: border_width,
          **color,
        },
        right: {
          # right
          x: rect.x + rect.w + padding.right - border_width,
          w: border_width,
          y: rect.y - padding.bottom,
          h: rect.h + padding.bottom + padding.top,
          **color,
        },
        bottom: {
          # bottom
          x: rect.x - padding.left,
          w: rect.w + padding.left + padding.right,
          y: rect.y - padding.bottom,
          h: border_width,
          **color,
        },
        left: {
          # left
          x: rect.x - padding.left,
          w: border_width,
          y: rect.y - padding.bottom,
          h: rect.h + padding.top + padding.bottom,
          **color,
        }
      }.each_value do |hash|
        hash[:primitive_marker] = :sprite
        hash[:path] = :pixel
      end
    end
  end
end
