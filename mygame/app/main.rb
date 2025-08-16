require "lib/sprite_kit.rb"

class Game
  def initialize
    @scene_manager = SpriteKit::SceneManager.new(
      current_scene: :main_scene,
      scenes: {
        main_scene: SpriteKit::Scenes::SpritesheetScene,
      }
    )
  end

  def tick(args)
    @scene_manager.tick(args)
  end
end

def tick(args)
  $game ||= Game.new
  $game.tick(args)
end

def reset
  $game = nil
end

$gtk.reset
