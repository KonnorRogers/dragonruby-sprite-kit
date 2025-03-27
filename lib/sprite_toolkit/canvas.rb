require_relative "camera.rb"

module SpriteToolkit
  class Canvas
    attr_accessor :camera

    def initialize
      @camera = Camera.new
    end

    def tick(args)
      calc_camera
      move_camera(args)

      args.outputs.sprites << { **Camera.viewport, path: :scene }

      args.outputs[:scene].w = 1500
      args.outputs[:scene].h = 1500
    end

    def move_camera(args)
      inputs = args.inputs

      speed = 3 + (3 / @camera.scale)

      # Movement
      if inputs.keyboard.left_arrow
        @camera.target_x -= speed
      elsif inputs.keyboard.right_arrow
        @camera.target_x += speed
      end

      if inputs.keyboard.down_arrow
        @camera.target_y -= speed
      elsif inputs.keyboard.up_arrow
        @camera.target_y += speed
      end

      # Zoom
      if args.inputs.keyboard.key_down.equal_sign || args.inputs.keyboard.key_down.plus
        @camera.target_scale += 0.25
      elsif args.inputs.keyboard.key_down.minus
        @camera.target_scale -= 0.25
        @camera.target_scale = 0.25 if @camera.target_scale < 0.25
      elsif args.inputs.keyboard.zero
        @camera.target_scale = 1
      end
    end

    def calc_camera
      ease = 0.1
      @camera.scale += (@camera.target_scale - @camera.scale) * ease

      @camera.x += (@camera.target_x - @camera.x) * ease
      @camera.y += (@camera.target_y - @camera.y) * ease
    end
  end
end
