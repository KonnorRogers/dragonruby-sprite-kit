module SpriteKit
  class NodesetDrawer
    attr_accessor :nodesets, :canvas, :camera, :world_mouse, :render_path

    def initialize(canvas:, camera:)
      @camera = camera
      @canvas = canvas
      @nodesets = [
        { name: "tab1", nodes: [] },
        { name: "tab2", nodes: [] }
      ]
      @render_path = :nodeset_drawer
    end

    def tick(args)
      input(args)
      calc(args)
      render(args)
    end

    def input(args)
      @current_sprite = @canvas.current_sprite

      # if @render_target && @current_sprite && args.inputs.click && @world_mouse.intersect_rect?(@render_path)
      #   @world_mouse
      # end
    end

    def calc(args)
    end

    def render(args)
      @render_target = args.outputs[@render_path]
      # render_target.background_color = { r: 255, g: 255, b: 255, a: 255 }
      @render_target.background_color = [255, 255, 255]
      @render_target.w = args.grid.w
      @render_target.h = (args.grid.h / 4).ceil

      node_background = {
        x: 0,
        y: 0,
        w: @render_target.w,
        h: @render_target.h - 75,
        path: :solid,
        r: 255,
        g: 0,
        b: 0,
        a: 64,
      }
      @render_target.sprites << node_background

      @tabs = []
      @nodesets.each_with_index do |nodeset, index|
        @tabs << {
          text: nodeset.name,
          x: 100 + (@tabs[index - 1]&.x || 0),
          y: @render_target.h - 50,
        }
      end

      @render_target.labels.concat(@tabs)
      active_tab = 0
      active_nodes = @nodesets[active_tab].nodes.map.with_index do |original_node, index|
        original_node.dup.tap do |node|
          node.x = 16 + (index * 48) + 8
          node.y = 12
          node.h = 48
          node.w = 48
        end
      end
      @render_target.sprites.concat(active_nodes)

      node_buttons = {
        left_button: {
          y: @render_target.h / 2,
          w: 64,
          h: 64,
          text: "<"
        },
        right_button: {
          text: ">",
          w: 64,
          h: 64,
          y: @render_target.h / 2,
        },
        drop_button: {
          x: 180,
          y: @render_target.h / 2,
          w: 64,
          h: 64,
          text: "+"
        }
      }

      tab_buttons = {
        left_button: {
          x: 30,
          y: @render_target.h,
          w: 64,
          h: 64,
          text: "<"
        },
        right_button: {
          text: ">",
          x: 120,
          w: 64,
          h: 64,
          y: @render_target.h,
        },
        drop_button: {
          x: 180,
          y: @render_target.h,
          w: 64,
          h: 64,
          text: "+"
        }
      }

      @render_target.labels.concat(tab_buttons.values).concat(node_buttons.values)
      args.outputs << {
        x: 0,
        y: 0,
        w: @render_target.w,
        h: @render_target.h,
        path: @render_path,
      }
    end
  end
end
