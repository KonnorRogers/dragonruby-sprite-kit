module SpriteKit
  # https://gist.github.com/KonnorRogers/6337311772ee53733d14a520d79ca4d5
  # A simple output buffer designed to limit the number of draw calls and "buffer" everything into arrays before drawing.
  class DrawBuffer
    attr_accessor :primitives, :outputs, :render_targets

    class RenderTargetArgumentError < StandardError; end

    def initialize
      @primitives = []
      @render_targets = {}
    end

    def [](key)
      raise RenderTargetArgumentError.new(key.inspect + " is not a string or symbol") if !(key.is_a?(String) || key.is_a?(Symbol))

      @render_targets[key] = [] if !@render_targets.key?(key)
      @render_targets[key]
    end

    def []=(key, value)
      raise RenderTargetArgumentError.new(key.inspect + " is not a string or symbol") if !(key.is_a?(String) || key.is_a?(Symbol))

      @render_targets[key] = value
    end

    # Renders each render target and output.
    def flush
      @render_targets.each do |key, value|
        @outputs[key].primitives.concat(value)
      end

      @outputs.primitives.concat(@primitives)
      clear
    end

    # Clears arrays / hashes without rendering.
    def clear
      # force nil to allow GC to run
      # @primitives = nil
      # @render_targets = nil
      # @primitives = []
      # @render_targets = {}

      @render_targets.clear
      @primitives.clear
    end
  end
end
