# frozen_string_literal: true

require SpriteKit.to_load_path("canvas.rb")
require SpriteKit.to_load_path("tool_drawer.rb")
require SpriteKit.to_load_path("draw_buffer.rb")
require SpriteKit.to_load_path("spritesheet_loader")
require SpriteKit.to_load_path("tree_renderer")

module SpriteKit
  module Scenes
    class SpritesheetScene
      attr_accessor :camera, :draw_buffer, :scene_manager, :state, :canvas, :tool_drawer

      def initialize(scene_manager = nil, sprite_directory: "sprites")
        @scene_manager = scene_manager
        @camera = ::SpriteKit::Camera.new
        @draw_buffer = ::SpriteKit::DrawBuffer.new

        @views = [:file_tree, :canvas]
        @state = {
          draw_buffer: @draw_buffer,
          camera: @camera,
          camera_path: :camera,
          view: @views[0],
          views: @views,
          show_grid: false,
          tile_selection: {
            w: 12, h: 12,
            row_gap: 1, column_gap: 1,
            offset_x: 1, offset_y: 1,
          },
          current_sprite: nil,
          viewport_boundary: nil,
          next_view: nil,
          file_path: nil,
        }

        @spritesheet_loader = SpriteKit::SpritesheetLoader.new
        spritesheets = @spritesheet_loader.load_directory(sprite_directory)
        @tree = spritesheets.tree
        @tree_renderer = TreeRenderer.new(@tree, state: @state)
        @spritesheets = spritesheets.spritesheets

        @state.spritesheets = @spritesheets

        @canvas = ::SpriteKit::Canvas.new(state: @state, spritesheets: [])
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

        if @state.view == :canvas
          @canvas.viewport_boundary = @state.viewport_boundary
          @canvas.tick(args)
        end

        if @state.view == :file_tree
          @draw_buffer.primitives.concat(@tree_renderer.render(args, offset_x: @tool_drawer.x + @tool_drawer.w))
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

        args.outputs.primitives.concat(args.gtk.framerate_diagnostics_primitives.map do |primitive|
          primitive.x = args.grid.w - 500 + primitive.x
          primitive
        end)

        if @state.next_view
          if @state.next_view == :canvas
            spritesheet = @spritesheets[@state.file_path]
            if spritesheet
              @canvas.spritesheets = [spritesheet]
              @camera.reset
            else
              @state.next_view = :file_tree
            end
          end

          if @state.next_view == :file_tree
            @state.current_sprite = nil
          end

          @state.view = @state.next_view
          @state.next_view = nil
        end
      end
    end
  end
end
