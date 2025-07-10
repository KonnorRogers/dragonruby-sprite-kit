require SpriteKit.to_load_path("canvas")
require SpriteKit.to_load_path("nodeset_drawer")

module SpriteKit
  module Scenes
    class SpritesheetScene
      def initialize
        @camera = ::SpriteKit::Camera.new
        @canvas = ::SpriteKit::Canvas.new(camera: @camera)
        @nodeset_drawer = ::SpriteKit::NodesetDrawer.new(camera: @camera, canvas: @canvas)

        @tickables = [
          @canvas,
          @nodeset_drawer
        ]
      end

      def tick(args)
        @world_mouse = @camera.to_world_space(args.inputs.mouse)
        @tickables.each { |tickable| tickable.world_mouse = @world_mouse }
        @canvas.tick(args)
        @nodeset_drawer.tick(args)
      end
    end
  end
end
