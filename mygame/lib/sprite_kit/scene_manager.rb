module SpriteKit
  class SceneManager
    attr_writer :next_scene
    attr_reader :current_scene
    attr_accessor :scenes

    def initialize(scenes:, current_scene:)
      @scenes = scenes
      @next_scene = nil
      @current_scene = @scenes[current_scene].new(self)
    end

    def tick(args)
      scene_before_tick = @current_scene
      @current_scene.tick(args)

      if scene_before_tick != @current_scene
        raise "Scene was changed incorrectly. Set @next_scene or scene.next_scene to change scenes."
      end

      @current_scene = @scenes[@next_scene].new(self) if @next_scene
    end
  end
end
