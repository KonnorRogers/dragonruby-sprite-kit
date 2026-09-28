require SpriteKit.to_load_path("camera")
# require SpriteKit.to_load_path("primitives")
# require SpriteKit.to_load_path(File.join("ui", "semantic_palette"))
# require SpriteKit.to_load_path("serializer")
require SpriteKit.to_load_path("sprite_methods")

module SpriteKit
  class MapEditor
    attr_accessor :hover_rect, :rect_size, :state, :viewport_boundary

    def initialize(state:)
      @hover_rect = nil
      @hover_rect_screen = nil

      # @show_grid = false

      # used to calculate where clicks are registered.
      @viewport_boundary = {
        x: 0,
        y: 0,
        h: Grid.h,
        w: Grid.w
      }
      @state = state
    end

    def camera_render_target(args)
      rt = args.outputs[@state.camera_path]
      viewport = @state.camera.viewport
      args.outputs[@state.camera_path].w = viewport.w
      args.outputs[@state.camera_path].h = viewport.h
      rt
    end

    def camera_speed
      3 + (12 / @state.camera.scale)
    end

    def tick(args)
      input(args)
      calc(args)
      render(args)
    end

    def input(args)
      move_camera(args)

      if args.inputs.keyboard.key_down.escape
        @state.current_sprite = nil
      end

    end

    def calc(args)
      calc_camera(args)
    end

    def render(args)
      render_camera(args)
      if @state.show_grid
        @state.draw_buffer[@state.camera_path].concat(
          render_grid(w: @state.tile_selection.w, h: @state.tile_selection.h)
        )
      end

      if @hover_rect_screen
        @state.draw_buffer[@state.camera_path] << @hover_rect_screen
      end
    end

    def move_camera(args)
      inputs = args.inputs

      speed = camera_speed

      # Movement
      if inputs.keyboard.left_arrow
        @state.camera.target_x -= speed
      elsif inputs.keyboard.right_arrow
        @state.camera.target_x += speed
      end

      if inputs.keyboard.down_arrow
        @state.camera.target_y -= speed
      elsif inputs.keyboard.up_arrow
        @state.camera.target_y += speed
      end

      # Zoom
      if args.inputs.keyboard.key_down.equal_sign || args.inputs.keyboard.key_down.plus
        @state.camera.target_scale += 0.25
      elsif args.inputs.keyboard.key_down.minus
        @state.camera.target_scale -= 0.25
        @state.camera.target_scale = 0.25 if @state.camera.target_scale < 0.25
      elsif args.inputs.keyboard.zero
        @state.camera.target_scale = 1
      end
    end

    def calc_camera(_args)
      ease = 0.1
      @state.camera.scale += (@state.camera.target_scale - @state.camera.scale) * ease

      @state.camera.x += (@state.camera.target_x - @state.camera.x) * ease
      @state.camera.y += (@state.camera.target_y - @state.camera.y) * ease
    end

    def render_camera(args)
      camera_render_target(args)
      @state.draw_buffer.primitives << { **@state.camera.viewport, path: @state.camera_path }
    end

    def render_grid(w: 32, h: 32)
      if w < 1
        w = 1
      end

      if h < 1
        h = 1
      end

      world = @state.camera.to_world_space!(@state.camera.viewport.dup)

      min_x = (world.x / w).floor * w
      min_y = (world.y / h).floor * h
      max_x = world.x + world.w
      max_y = world.y + world.h

      solids = []

      x = min_x
      while x <= max_x
        s = { x: x, y: min_y, w: 1, h: max_y - min_y }
        @state.camera.to_screen_space!(s)
        solids << { x: s.x, y: s.y, w: 1, h: s.h, r: 255, g: 255, b: 255, a: 255, path: :solid }
        x += w
      end

      y = min_y
      while y <= max_y
        s = { x: min_x, y: y, w: max_x - min_x, h: 1 }
        @state.camera.to_screen_space!(s)
        solids << { x: s.x, y: s.y, w: s.w, h: 1, r: 255, g: 255, b: 255, a: 255, path: :solid }
        y += h
      end

      solids
    end
  end # MapEditor
end # SpriteKit

