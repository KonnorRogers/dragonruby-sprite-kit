# frozen_string_literal: true

require SpriteKit.to_load_path("canvas.rb")
require SpriteKit.to_load_path("tool_drawer.rb")
require SpriteKit.to_load_path("draw_buffer.rb")

module SpriteKit
  module Scenes
    class SpritesheetScene
      def initialize(scene_manager)
        @scene_manager = scene_manager
        @camera = ::SpriteKit::Camera.new
        @draw_buffer = ::SpriteKit::DrawBuffer.new

        @state = {
          draw_buffer: @draw_buffer,
          camera: @camera,
          camera_path: :camera,
          tile_selection: {
            w: 12, h: 12,
            row_gap: 1, column_gap: 1,
            offset_x: 1, offset_y: 1,
          },
          current_sprite: nil,
          viewport_boundary: nil,
        }

        @canvas = ::SpriteKit::Canvas.new(state: @state)
        @tool_drawer = ::SpriteKit::ToolDrawer.new(state: @state)
      end


      def tick(args)
        @state.outputs = args.outputs
        @state.draw_buffer.outputs = args.outputs

        @state.world_mouse = @camera.to_world_space(args.inputs.mouse)

        @state.viewport_boundary = {
          x: @tool_drawer.w,
          y: 0,
          w: args.grid.w - @tool_drawer.w,
          h: args.grid.h,
        }
        @canvas.viewport_boundary = @state.viewport_boundary

        @canvas.tick(args)
        @tool_drawer.tick(args)

        top_layer = {
          w: 1280,
          h: 720,
          x: 0,
          y: 0,
          path: :top_layer
        }
        args.outputs[:top_layer].w = top_layer.w
        args.outputs[:top_layer].h = top_layer.h
        args.outputs[:top_layer].transient!
        @draw_buffer.primitives << top_layer

        @draw_buffer.flush

        args.outputs.primitives.concat(args.gtk.framerate_diagnostics_primitives.map do |primitive|
          primitive.x = args.grid.w - 500 + primitive.x
          primitive
        end)
      end
    end
  end
end
