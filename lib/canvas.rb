require "lib/camera.rb"

module SpriteManager
  class Canvas
    def initialize
      @camera = Camera.new
    end

    def tick(args)
      calc_camera(args)
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
        args.state.camera.target_x -= speed
      elsif inputs.keyboard.right_arrow
        args.state.camera.target_x += speed
      end

      if inputs.keyboard.down_arrow
        args.state.camera.target_y -= speed
      elsif inputs.keyboard.up_arrow
        args.state.camera.target_y += speed
      end

      # Zoom
      state = args.state
      if args.inputs.keyboard.key_down.equal_sign || args.inputs.keyboard.key_down.plus
        state.camera.target_scale += 0.25
      elsif args.inputs.keyboard.key_down.minus
        state.camera.target_scale -= 0.25
        state.camera.target_scale = 0.25 if state.camera.target_scale < 0.25
      elsif args.inputs.keyboard.zero
        state.camera.target_scale = 1
      end
    end

    def calc_camera(args)
      state = args.state

      if !state.camera
        state.camera = {
          x: 0,
          y: 0,
          target_x: 0,
          target_y: 0,
          target_scale: 2,
          scale: 2
        }

        args.state.start_camera = { scale: state.camera.scale }
      end

      ease = 0.1
      state.camera.scale += (state.camera.target_scale - state.camera.scale) * ease

      state.camera.x += (state.camera.target_x - state.camera.x) * ease
      state.camera.y += (state.camera.target_y - state.camera.y) * ease
    end
  end
end
