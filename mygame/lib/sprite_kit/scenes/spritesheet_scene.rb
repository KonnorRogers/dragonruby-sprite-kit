require SpriteKit.to_load_path("canvas")

module SpriteKit
  module Scenes
    class SpritesheetScene
      def initialize
        @canvas = ::SpriteKit::Canvas.new
      end

      def tick(args)
        @canvas.tick(args)
      end
    end
  end
end
