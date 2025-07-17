module SpriteKit
  class Camera
    SCREEN_WIDTH = 1280
    SCREEN_HEIGHT = 720
    WORLD_SIZE = 1500
    WORLD_SIZE_HALF = WORLD_SIZE / 2
    OFFSET_X = (SCREEN_WIDTH - WORLD_SIZE) / 2
    OFFSET_Y = (SCREEN_HEIGHT - WORLD_SIZE) / 2

    attr_accessor :x, :y, :target_x, :target_y, :scale, :target_scale

    def initialize
      @x = 0
      @y = 0
      @target_x = 0
      @target_y = 0
      @target_scale = 2
      @scale = 2
    end

    def to_rect
      viewport.merge({ x: @x, y: @y })
    end

    def self.viewport
      {
        x: OFFSET_X,
        y: OFFSET_Y,
        w: WORLD_SIZE,
        h: WORLD_SIZE
      }
    end

    def viewport
      self.class.viewport
    end

    # @param {#x, #y, #w, #h, #scale} camera
    # @param {#x, #y, #w, #h} rect
    def self.to_world_space(camera, rect)
      x = (rect.x - WORLD_SIZE_HALF + camera.x * camera.scale - OFFSET_X) / camera.scale
      y = (rect.y - WORLD_SIZE_HALF + camera.y * camera.scale - OFFSET_Y) / camera.scale
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
      x = rect.x * camera.scale - camera.x * camera.scale + WORLD_SIZE_HALF
      y = rect.y * camera.scale - camera.y * camera.scale + WORLD_SIZE_HALF
      w = rect.w * camera.scale
      h = rect.h * camera.scale
      rect.merge x: x, y: y, w: w, h: h
    end

    def to_screen_space(rect)
      self.class.to_screen_space(self, rect)
    end

    # @param {#x, #y, #w, #h, #scale} camera
    def self.viewport_world(camera)
      to_world_space(camera, viewport)
    end

    def viewport_world
      self.class.viewport_world(self)
    end

    def self.find_all_intersect_viewport(camera, os)
      Geometry.find_all_intersect_rect(viewport_world(camera), os)
    end

    def find_all_intersect_viewport(os)
      self.class.find_all_intersect_viewport(self, os)
    end

    def self.intersect_viewport?(camera, rect)
      viewport_world(camera).intersect_rect?(rect)
    end

    def intersect_viewport?(rect)
      self.class.intersect_viewport?(self, rect)
    end
  end
end
