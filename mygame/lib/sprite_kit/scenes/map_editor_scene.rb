require SpriteKit.to_load_path("map_editor")

module SpriteKit
  module Scenes
    class MapEditorScene
      attr_accessor :camera, :draw_buffer, :scene_manager, :state, :canvas, :tool_drawer

      def initialize(scene_manager = nil)
        @scene_manager = scene_manager
        @camera = ::SpriteKit::Camera.new
        @draw_buffer = ::SpriteKit::DrawBuffer.new

        @views = [:map_editor]
        @state = {
          draw_buffer: @draw_buffer,
          camera: @camera,
          camera_path: :camera,
          view: @views[0],
          views: @views,
          show_grid: false,
          tile_selection: {
            w: 12, h: 12,
            # row_gap: 1, column_gap: 1,
            # offset_x: 1, offset_y: 1,
          },
          current_sprite: nil,
          viewport_boundary: nil,
          next_view: nil,
          file_path: nil,
          scene_manager: @scene_manager
        }

        @map_editor = SpriteKit::MapEditor.new(state: @state)
        @tool_drawer = ::SpriteKit::ToolDrawer.new(state: @state)
      end

      def tick(args)
        @state.outputs = args.outputs
        @state.draw_buffer.outputs = args.outputs

        if args.inputs.keyboard.key_down.g
          @state.show_grid = !@state.show_grid
        end

        @state.world_mouse = @camera.to_world_space(args.inputs.mouse)

        @state.viewport_boundary = {
          x: @tool_drawer.w,
          y: 0,
          w: args.grid.w - @tool_drawer.w,
          h: args.grid.h,
        }

        if @state.view == :map_editor
          @map_editor.viewport_boundary = @state.viewport_boundary
          @map_editor.tick(args)
        end

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
      end
    end
  end
end
