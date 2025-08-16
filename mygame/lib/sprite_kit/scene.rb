require SpriteKit.to_load_path("draw_buffer")

module SpriteKit
  class Scene
    attr_accessor :draw_buffer, :outputs, :inputs, :state, :args, :audio, :events, :mouse, :keyboard, :top_layer

    def initialize(scene_manager)
      @scene_manager = scene_manager
      @draw_buffer = DrawBuffer.new
    end

    def tick(args)
      @args = args
      @outputs = args.outputs
      @inputs = args.inputs
      @state = args.state
      @audio = args.audio
      @events = args.events
      @gtk = args.gtk
      @mouse = args.inputs.mouse
      @keyboard = args.inputs.keyboard
      @top_layer = {
        w: Grid.w,
        h: Grid.h,
        x: 0,
        y: 0,
        path: :top_layer,
      }
      @draw_buffer.outputs = @outputs

      input
      calc
      render
      draw
    end

    def input
    end

    def calc
    end

    def render
    end

    def render_top_layer
      # Goes on top of everything.
      @top_layer.w = Grid.w
      @top_layer.h = Grid.h

      @outputs[:top_layer].w = @top_layer.w
      @outputs[:top_layer].h = @top_layer.h
      @outputs[:top_layer].transient!
      @draw_buffer.primitives << @top_layer
    end

    def draw
      render_top_layer
      GTK.warn_array_primitives!

      GTK.framerate_diagnostics_primitives.map.with_index do |primitive, index|
        primitive.y = 1 + index * 16
      end

      @draw_buffer.flush
    end
  end
end
