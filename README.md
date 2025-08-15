# DragonRuby Sprite Kit

## What is this?

Right now Sprite Kit is a basic utility helper for me with things I want to carry between projects.

Things like

- Making spritesheets easier to work with (Most asset packs ship as spritesheets and are annoying to work with)
- Map editors / Level Editors
- Who knows what else?

Sprite Kit is built for DragonRuby with the intent of you extending it. Its designed to take the place of external tools you may use.

## Using degit

npx degit konnorrogers/dragonruby-sprite-kit/mygame/lib ./mygame/vendor/sprite-kit

## TODO: Download a zip from releases

## Working with Spritesheets

I personally found working with Spritesheets (images containing multiple assets inside) particularly painful with DragonRuby.

So lets start with the basics. Not everyone will need a Map Editor. But everyone will probably end up working with a spritesheets full of many sprites.

### Rendering the Canvas

The SpriteCanvas is a scene designed for viewing your sprites. Its a large "infinite" canvas where you can drop spritesheets and see them appear.

```rb
require "vendor/sprite-kit"

def tick(args)
  spritesheet_scene ||= SpriteKit::SpritesheetScene.new
  spritesheet_scene.tick(args)
end
```

The above will render a canvas for you to select your sprites from a canvas and copy them your clipboard.

## Scene Manager

If you would like, DragonRuby Sprite Kit also ships with Scene Manager and Scenes.

```rb
class MainScene < SpriteKit::Scene
  def render
    draw_buffer.primitives << {
      x: 0,
      y: 0,
      w: Grid.w / 2,
      h: Grid.h / 2,
      text: "Hello World"
    }.label!
  end
end

class Game
  def initialize(args)
    @scene_manager = SpriteKit::SceneManager.new(
      current_scene: :main_scene,
      scenes: {
        main_scene: MainScene,
      }
    )
  end

  def tick(args)
    @scene_manager.tick(args)
  end
end

def tick(args)
  $game ||= Game.new(args)
  $game.tick(args)
end

def reset
  $game = nil
end

$gtk.reset
```

## Map Editor (Maybe?)
