module SpriteKit
  class NodesetDrawer
    attr_accessor :nodesets, :canvas, :world_mouse, :render_path, :draw_buffer, :w, :h, :x, :y

    def initialize(canvas:)
      @canvas = canvas
      @nodesets = [
        { name: "tab1", nodes: [] },
        { name: "tab2", nodes: [] }
      ]
      @render_path = :nodeset_drawer

      @w = 0
      @h = 0
      @y = 0
      @x = 0
    end

    def serialize
      {
        x: @x,
        y: @y,
        w: @w,
        h: @h,
      }
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
      @render_target.background_color = [255, 255, 255, 255]
      @render_target.w = @w
      @render_target.h = @h

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
      @draw_buffer[@render_path] << node_background

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
      @draw_buffer[@render_path].concat(active_nodes)

      tab_buttons = {
        left_button: {
          text: "<"
        },
        right_button: {
          text: ">"
        },
        drop_button: {
          text: "+"
        }
      }

      node_buttons = {
        left_button: {
          text: "<"
        },
        right_button: {
          text: ">",
        },
        drop_button: {
          text: "+"
        }
      }

      tab_buttons.values.tap do |buttons|
        buttons.each_with_index do |hash, index|
          hash.x = (20 * index)
          hash.y = @render_target.h
          hash.primitive_marker = :label
        end
      end

      node_buttons.values.tap do |buttons|
        buttons.each_with_index do |hash, index|
          hash.x = (20 * index)
          hash.y = @render_target.h / 2
          hash.primitive_marker = :label
        end
      end

      @draw_buffer[@render_path].concat(tab_buttons.values).concat(node_buttons.values)

      mouse = args.inputs.mouse
      if mouse.intersect_rect?({
          x: @x,
          y: @y,
          w: @w,
          h: @h - 16
      })
        args.outputs.debug << @current_sprite.to_s
        @draw_buffer[@render_path] << @current_sprite.merge({
          x: (mouse.x - 32).clamp(0, @w - 64),
          y: (mouse.y - 32).clamp(0, @h - 64),
          w: 64,
          h: 64,
        })
      end

      @draw_buffer.primitives << {
        x: 0,
        y: 0,
        w: @render_target.w,
        h: @render_target.h,
        path: @render_path,
      }
    end
  end
end
