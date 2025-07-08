module Spritekit
  class NodeDrawer
    attr_accessor :nodesets

    def initialize
      @nodesets = []
    end

    def tick(args)
      @args = args
      @outputs = args.outputs
      @inputs = args.inputs

      input
      calc
      render
    end

    def input

    end

    def calc
    end

    def render
      @nodesets.each do |nodeset|
        # display tab at the top
        # render the nodes in the nodeset.
      end
    end
  end
end
