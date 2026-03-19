module SpriteKit
  class Camera
    # SCREEN_WIDTH = 1280
    # SCREEN_HEIGHT = 720

    attr_accessor :x, :y, :target_x, :target_y, :scale, :target_scale
    attr_writer :w, :h, :offset_x, :offset_y

    def initialize(
      x: 0, y: 0,
      target_x: 0, target_y: 0,
      target_scale: 2, scale: 2,
      w: nil, h: nil,
      offset_x: nil, offset_y: nil
    )
      @x = x
      @y = y
      @target_x = target_x
      @target_y = target_y
      @target_scale = target_scale
      @scale = scale

      @w = w
      @h = h
      @offset_x = offset_x
      @offset_y = offset_y
    end

    def w
      @w || viewport_w
    end

    def h
      @h || viewport_h
    end

    def half_width
      return @w.fdiv(2).ceil if @w

      viewport_w_half
    end

    def half_height
      return @h.fdiv(2).ceil if @h

      viewport_h_half
    end

    def viewport_h
      Grid.allscreen_h
    end

    def viewport_w
      Grid.allscreen_w
    end

    def viewport_w_half
      if Grid.origin_center?
        0
      else
        viewport_w.fdiv(2).ceil
      end
    end

    def viewport_h_half
      if Grid.origin_center?
        0
      else
        viewport_h.fdiv(2).ceil
      end
    end

    def offset_x
      return @offset_x if @offset_x

      # old offset_x functionality when defining an @w
      return (viewport_w - @w / 2) if @w

      if Grid.origin_center?
        0
      else
        Grid.allscreen_x
      end
    end

    def offset_y
      return @offset_x if @offset_x

      # old offset_y functionality when defining an @h
      return (viewport_h - @h / 2) if @h

      if Grid.origin_center?
        0
      else
        Grid.allscreen_y
      end
    end

    def viewport
      if @w && @h
        return {
          x: offset_x,
          y: offset_y,
          w: w,
          h: h,
        }
      end

      if Grid.origin_center?
        {
          x: offset_x,
          y: offset_y,
          w: w,
          h: h,
          anchor_x: 0.5,
          anchor_y: 0.5
        }
      else
        {
          x: offset_x,
          y: offset_y,
          w: w,
          h: h,
        }
      end
    end

    # @param {#x, #y, #w, #h, #scale} camera
    # @param {#x, #y, #w, #h} rect
    def self.to_world_space(camera, rect)
      to_world_space!(camera, rect.merge({}))
    end

    def self.to_world_space!(camera, rect)
      x = (rect.x - (camera.half_width) + camera.x * camera.scale - camera.offset_x) / camera.scale
      y = (rect.y - (camera.half_height) + camera.y * camera.scale - camera.offset_y) / camera.scale
      w = rect.w / camera.scale
      h = rect.h / camera.scale

      rect.x = x
      rect.y = y
      rect.w = w
      rect.h = h
      rect
    end

    def to_world_space(rect)
      self.class.to_world_space(self, rect)
    end

    def to_world_space!(rect)
      self.class.to_world_space!(self, rect)
    end

    # @param {#x, #y, #w, #h, #scale} camera
    # @param {#x, #y, #w, #h} rect
    def self.to_screen_space(camera, rect)
      to_screen_space!(camera, rect.merge({}))
    end

    # @param {#x, #y, #w, #h, #scale} camera
    # @param {#x, #y, #w, #h} rect
    def self.to_screen_space!(camera, rect)
      x = rect.x * camera.scale - camera.x * camera.scale + (camera.half_width)
      y = rect.y * camera.scale - camera.y * camera.scale + (camera.half_height)
      w = rect.w * camera.scale
      h = rect.h * camera.scale

      rect.x = x
      rect.y = y
      rect.w = w
      rect.h = h
      rect
    end

    def to_screen_space(rect)
      self.class.to_screen_space(self, rect)
    end

    def to_screen_space!(rect)
      self.class.to_screen_space(self, rect)
    end

    def viewport_world
      to_world_space(viewport)
    end

    def find_all_intersect_viewport(rects)
      Geometry.find_all_intersect_rect(viewport_world, rects)
    end

    def intersect_viewport?(rect)
      viewport_world.intersect_rect?(rect)
    end
  end
end
