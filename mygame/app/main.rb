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
  attr_accessor :game

  def tick(args)
    if !@game
      SpriteKit::LOADED_FILES.clear
      SpriteKit.load
      @game = Game.new
    end
    # @game.tick(args)
    # Create an input
    args.state.input ||= Input::Text.new(args, x: 100, y: 600, w: 300, focussed: false)

    # Allow the input to process inputs and render text (render_target)
    args.state.input.tick

    # Get the value
    args.state.input_value = args.state.input.value

    if args.inputs.mouse.click
      args.state.input.focus if args.inputs.mouse.inside_rect?(args.state.input)
    end

    # Output the input
    args.outputs.primitives.concat([
      args.state.input,
      *SpriteKit::Primitives.borders(args.state.input).values
    ])

    # Output the value
    args.outputs.debug << { x: 100, y: 100, text: args.state.input_value }.label!
  end

  def reset
    @game = nil
  end
end

$gtk.reset
