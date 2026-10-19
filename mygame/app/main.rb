require "lib/sprite_kit.rb"

class Game
  def initialize
    @scene_manager = SpriteKit::SceneManager.new(
      current_scene: :main_scene,
      scenes: {
        main_scene: SpriteKit::Scenes::SpritesheetScene,
        map_editor_scene: SpriteKit::Scenes::MapEditorScene,
      }
    )
  end

  def tick(args)
    # F1: spritesheets, F2: map editor
    if args.inputs.keyboard.key_down.f1
      @scene_manager.next_scene = :main_scene
    elsif args.inputs.keyboard.key_down.f2
      @scene_manager.next_scene = :map_editor_scene
    end

    @scene_manager.tick(args)
  end
end

module Main
  def tick(args)
    $game ||= Game.new
    $game.tick(args)
  end

  def reset
    $game = nil
  end
end

$gtk.reset
