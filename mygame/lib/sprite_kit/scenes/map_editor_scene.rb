# frozen_string_literal: true

require SpriteKit.to_load_path("canvas.rb")
require SpriteKit.to_load_path("tool_drawer.rb")
require SpriteKit.to_load_path("draw_buffer.rb")
require SpriteKit.to_load_path("spritesheet_loader")
require SpriteKit.to_load_path("tree_renderer")
require SpriteKit.to_load_path("map_editor")
require SpriteKit.to_load_path("string_helper")

module SpriteKit
  module Scenes
    # Pick tiles from your spritesheets on the canvas, then paint them on the map.
    #
    # Views (cycle with Tab):
    #   :map       - paint tiles onto layers. Saves to `map_path`.
    #   :file_tree - browse `sprite_directory`. Double click a spritesheet to open it on the canvas.
    #   :canvas    - click a tile to select it as the brush.
    class MapEditorScene
      attr_accessor :camera, :draw_buffer, :scene_manager, :state, :canvas, :tool_drawer, :map_editor

      def initialize(scene_manager = nil, sprite_directory: "sprites", map_path: "data/map.json")
        @scene_manager = scene_manager
        @camera = ::SpriteKit::Camera.new
        @draw_buffer = ::SpriteKit::DrawBuffer.new

        @views = [:map, :file_tree, :canvas]
        @state = {
          draw_buffer: @draw_buffer,
          camera: @camera,
          camera_path: :camera,
          view: @views[0],
          views: @views,
          show_grid: false,
          tile_selection: {
            w: 16, h: 16,
            row_gap: 0, column_gap: 0,
            offset_x: 0, offset_y: 0,
          },
          current_sprite: nil,
          viewport_boundary: nil,
          next_view: nil,
          file_path: nil,
          text_input_focused: false,
        }

        @spritesheet_loader = SpriteKit::SpritesheetLoader.new
        spritesheets = @spritesheet_loader.load_directory(sprite_directory)
        @tree = spritesheets.tree
        @tree_renderer = TreeRenderer.new(@tree, state: @state)
        @spritesheets = spritesheets.spritesheets

        @state.spritesheets = @spritesheets

        @canvas = ::SpriteKit::Canvas.new(state: @state, spritesheets: [])
        @tool_drawer = ::SpriteKit::ToolDrawer.new(state: @state)
        @map_editor = ::SpriteKit::MapEditor.new(state: @state, map_path: map_path)
      end

      def tick(args)
        @state.outputs = args.outputs
        @state.draw_buffer.outputs = args.outputs
        @state.text_input_focused = !!@tool_drawer.focus

        # The map editor has its own grid toggle.
        if @state.view == :canvas && args.inputs.keyboard.key_down.g
          @state.show_grid = !@state.show_grid
        end

        @state.world_mouse = @camera.to_world_space(args.inputs.mouse)

        @state.viewport_boundary = {
          x: @tool_drawer.w,
          y: 0,
          w: args.grid.w - @tool_drawer.w - ::SpriteKit::MapEditor::PANEL_W,
          h: args.grid.h,
        }

        if @state.view == :map
          @map_editor.viewport_boundary = @state.viewport_boundary
          @map_editor.tick(args)
        end

        if @state.view == :canvas
          @canvas.viewport_boundary = @state.viewport_boundary
          @canvas.tick(args)

          if args.inputs.keyboard.key_down.enter && !@state.text_input_focused
            @state.next_view = :map
          end
        end

        if @state.view == :file_tree
          @draw_buffer.primitives.concat(@tree_renderer.render(args, offset_x: @tool_drawer.x + @tool_drawer.w, width: @state.viewport_boundary.w))
        end

        # The map editor's side panel (brush, layers, tools) stays visible while picking tiles.
        if @state.view != :map
          @map_editor.tick_panel(args)
        end

        render_hint(args)

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

        transition_view
      end

      # Explains how to get a tile back to the map while picking one.
      def render_hint(args)
        text = if @state.view == :file_tree
                 "Double click a spritesheet to pick tiles from it. Tab: back to the map"
               elsif @state.view == :canvas && @state.current_sprite
                 "Tile selected! Press Enter (or \"Back to map\") to paint with it. Shift+click selects more"
               elsif @state.view == :canvas
                 "Click a tile to paint with it. Enter: back to the map"
               end

        return if !text

        bar = { x: @state.viewport_boundary.x, y: 0, w: @state.viewport_boundary.w, h: 32 }
        @draw_buffer.primitives.concat([
          bar.merge({ path: :solid, r: 0, g: 112, b: 239, a: 255 }),
          {
            x: bar.x + 12,
            y: bar.y + bar.h / 2,
            text: StringHelper.truncate(text, size_px: 18, max_width: bar.w - 24),
            size_px: 18,
            anchor_y: 0.5,
            r: 255, g: 255, b: 255, a: 255
          }.label!
        ])
      end

      def transition_view
        return if !@state.next_view

        if @state.next_view == :canvas
          spritesheet = @spritesheets[@state.file_path]

          if spritesheet
            if @canvas.spritesheets[0] != spritesheet
              @canvas.spritesheets = [spritesheet]
              @camera.reset
            end

            # The canvas expects the current sprite to come from the spritesheet it's showing.
            if @state.current_sprite && @state.current_sprite.spritesheet != spritesheet
              @state.current_sprite = nil
            end
          else
            # Nothing to show yet, skip over the canvas.
            @state.next_view = :map
          end
        end

        @state.view = @state.next_view
        @state.next_view = nil
      end
    end
  end
end
