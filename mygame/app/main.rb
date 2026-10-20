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
    # $game ||= Game.new
    # $game.tick(args)
    # Create an input
    args.state.input ||= ::SpriteKit::Input::Text.new(x: 100, y: 600, w: 300, focussed: true)

    # Allow the input to process inputs and render text (render_target)
    args.state.input.tick

    # Get the value
    args.state.input_value = args.state.input.value

    # Output the input
    args.outputs.primitives << args.state.input

    # Output the value
    args.outputs.debug << { x: 100, y: 100, text: args.state.input_value }.label!
  end

  def reset
    $game = nil
  end
end

$gtk.reset
