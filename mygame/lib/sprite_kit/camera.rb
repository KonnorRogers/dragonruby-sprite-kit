module SpriteKit
  class Camera
    SCREEN_WIDTH = 1280
    SCREEN_HEIGHT = 720

    attr_accessor :x, :y, :w, :h, :target_x, :target_y, :scale, :target_scale

    def initialize(
      x: 0, y: 0,
      target_x: 0, target_y: 0,
      target_scale: 2, scale: 2,
      w: 1500,
      h: 1500
    )
      @x = x
      @y = y
      @target_x = target_x
      @target_y = target_y
      @target_scale = target_scale
      @scale = scale

      @w = w
      @h = h
    end

    def offset_x
      (SCREEN_WIDTH - @w) / 2
    end

    def offset_y
      (SCREEN_HEIGHT - @h) / 2
    end

    def viewport
      {
        x: offset_x,
        y: offset_y,
        w: @w,
        h: @h
      }
    end

    # @param {#x, #y, #w, #h, #scale} camera
    # @param {#x, #y, #w, #h} rect
    def self.to_world_space(camera, rect)
      x = (rect.x - (camera.w / 2) + camera.x * camera.scale - camera.offset_x) / camera.scale
      y = (rect.y - (camera.h / 2) + camera.y * camera.scale - camera.offset_y) / camera.scale
      w = rect.w / camera.scale
      h = rect.h / camera.scale
      rect.merge(x: x, y: y, w: w, h: h)
    end

    def to_world_space(rect)
      self.class.to_world_space(self, rect)
    end

    # @param {#x, #y, #w, #h, #scale} camera
    # @param {#x, #y, #w, #h} rect
    def self.to_screen_space(camera, rect)
      x = rect.x * camera.scale - camera.x * camera.scale + (camera.w / 2)
      y = rect.y * camera.scale - camera.y * camera.scale + (camera.h / 2)
      w = rect.w * camera.scale
      h = rect.h * camera.scale
      rect.merge x: x, y: y, w: w, h: h
    end

    def to_screen_space(rect)
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
