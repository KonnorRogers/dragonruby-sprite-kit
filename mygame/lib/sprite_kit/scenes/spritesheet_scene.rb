require SpriteKit.to_load_path("canvas")
require SpriteKit.to_load_path("nodeset_drawer")
require SpriteKit.to_load_path("draw_buffer")

module SpriteKit
  module Scenes
    class SpritesheetScene
      def initialize
        @camera = ::SpriteKit::Camera.new
        @canvas = ::SpriteKit::Canvas.new(camera: @camera)
        @nodeset_drawer = ::SpriteKit::NodesetDrawer.new(canvas: @canvas)
        @draw_buffer = ::SpriteKit::DrawBuffer.new

        @tickables = [
          @canvas,
          @nodeset_drawer
        ]

        @tickables.each { |tickable| tickable.draw_buffer = @draw_buffer }
      end

      def tick(args)
        @draw_buffer.outputs = args.outputs
        @world_mouse = @camera.to_world_space(args.inputs.mouse)

        @nodeset_drawer.h = (args.grid.h / 4).ceil
        @nodeset_drawer.w = args.grid.w

        @viewport_boundary = {
          x: 0,
          y: @nodeset_drawer.h,
          w: args.grid.w,
          h: args.grid.h - @nodeset_drawer.h,
        }
        @canvas.viewport_boundary = @viewport_boundary

        @tickables.each do |tickable|
          tickable.world_mouse = @world_mouse
          tickable.tick(args)
        end

        @draw_buffer.flush

        args.outputs.primitives.concat(args.gtk.framerate_diagnostics_primitives.map do |primitive|
          primitive.x = args.grid.w - 500 + primitive.x
          primitive
        end)
      end
    end
  end
end
