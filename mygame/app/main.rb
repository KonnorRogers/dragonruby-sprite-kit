require "lib/sprite_kit.rb"

class Game
  def initialize
    @scene_manager = SpriteKit::SceneManager.new(
      current_scene: :sprite_viewer_scene,
      scenes: {
        sprite_viewer_scene: SpriteKit::Scenes::SpritesheetScene,
        map_editor_scene: SpriteKit::Scenes::MapEditorScene
      }
    )
  end

  def tick(args)
    @scene_manager.tick(args)

    args.outputs.primitives.concat(args.gtk.framerate_diagnostics_primitives.map do |primitive|
      primitive.x = args.grid.w - 500 + primitive.x
      primitive
    end)
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
