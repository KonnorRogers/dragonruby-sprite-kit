# DragonRuby Sprite Kit

## What is this?

Right now Sprite Kit is a basic utility helper for me with things I want to carry between projects.

Things like

- Making spritesheets easier to work with (Most asset packs ship as spritesheets and are annoying to work with)
- Map editors / Level Editors
- Who knows what else?

Sprite Kit is built for DragonRuby with the intent of you extending it. Its designed to take the place of external tools you may use.

## Using degit

`npx degit konnorrogers/dragonruby-sprite-kit/mygame/lib ./mygame/vendor/sprite_kit`

## Download a zip from releases

## Working with Spritesheets

I personally found working with Spritesheets (images containing multiple assets inside) particularly painful with DragonRuby.

So lets start with the basics. Not everyone will need a Map Editor. But everyone will probably end up working with a spritesheets full of many sprites.

### Rendering the Canvas

The SpriteCanvas is a scene designed for viewing your sprites. Its a large "infinite" canvas where you can drop spritesheets and see them appear.

```rb
require "vendor/sprite_kit/sprite_kit.rb"

def tick(args)
  args.state.spritesheet_scene ||= SpriteKit::Scenes::SpritesheetScene.new
  args.state.spritesheet_scene.tick(args)
end
```

The above will render a canvas for you to select your sprites from a canvas and copy them your clipboard.

## Scene Manager

If you would like, DragonRuby Sprite Kit also ships with Scene Manager and Scenes.

```rb
class MainScene < SpriteKit::Scene
  def render
    draw_buffer.primitives << {
      x: Grid.w / 2,
      y: Grid.h / 2,
      text: "Hello World"
    }.label!
  end
end

class Game
  def initialize
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
  $game ||= Game.new
  $game.tick(args)
end

def reset
  $game = nil
end

$gtk.reset
```

## Map Editor

The `MapEditorScene` combines the spritesheet canvas with a layered tile map editor.

```rb
require "vendor/sprite_kit/sprite_kit.rb"

def tick(args)
  args.state.map_editor_scene ||= SpriteKit::Scenes::MapEditorScene.new(nil, sprite_directory: "sprites", map_path: "data/map.json")
  args.state.map_editor_scene.tick(args)
end
```

To add tiles, click **Choose tile** in the panel (or press `Tab`), double click a spritesheet in the file tree, click a tile on the canvas, then press `Enter` to go back to the map and paint with it. `Tab` cycles between the map, the file tree, and the canvas. The grid size is the brush `w` / `h` from the tool drawer, so set it to your tileset's tile size.

- Tools: Paint (`B`), Erase (`E`), Rect fill (`R`), Pick tile (`I`). Right click always erases.
- Pan with middle mouse or `Space` + drag, zoom with the mouse wheel or `+` / `-` / `0`.
- Layers: `N` new layer, `V` hide / show, `[` / `]` change layer, or use the layers panel.
- `Ctrl+Z` / `Ctrl+Shift+Z` to undo / redo. The map saves after every change (and with `Ctrl+S`).

Maps are saved as JSON. Load them into your game with `SpriteKit::Map`:

```rb
map = SpriteKit::Map.load("data/map.json")

map.layers.each do |layer|
  args.outputs.sprites.concat(layer.tiles) if layer.visible
end
```

Each tile is a plain sprite hash: `{ x:, y:, w:, h:, path:, source_x:, source_y:, source_w:, source_h: }`.
