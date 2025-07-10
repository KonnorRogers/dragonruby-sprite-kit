module SpriteKit
  class NodesetDrawer
    attr_accessor :nodesets, :canvas, :camera, :world_mouse, :render_path

    def initialize(canvas:, camera:)
      @camera = camera
      @canvas = canvas
      @nodesets = [
        "tab1",
        "tab2"
      ]
      @render_path = :nodeset_drawer
    end

    def tick(args)
      @args = args
      @outputs = args.outputs
      @inputs = args.inputs

      input(args)
      calc(args)
      render(args)
    end

    def input(args)
    end

    def calc(args)
    end

    def render(args)
      render_target = args.outputs[@render_path]
      render_target.w = args.grid.w
      render_target.h = (args.grid.h / 3).ceil

      args.outputs.sprites << {
        x: 0,
        y: 0,
        w: render_target.w,
        h: render_target.h - 75,
        r: 255,
        g: 0,
        b: 0,
        a: 64,
        path: :pixel
      }

      labels = []
      @nodesets.each_with_index do |nodeset, index|
        labels << {
          text: nodeset,
          x: 50 + (labels[index - 1]&.x || 0),
          y: render_target.h - 50,
        }
      end

      render_target.labels.concat(labels)

      args.outputs << {
        x: 0,
        y: 0,
        w: render_target.w,
        h: render_target.h,
        path: @render_path
      }
    end
  end
end
