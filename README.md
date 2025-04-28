# DragonRuby Sprite Kit

## What is this?

Right now Sprite Kit aims to provide GUI interactions within your DragonRuby project.

Things like

- Making spritesheets easier to work with (Most asset packs ship as spritesheets and are annoying to work with)
- Map editors / Level Editors
- Who knows what else?

Sprite Kit is built for DragonRuby with the intent of you extending it. Its designed to take the place of external tools you may use.

## Working with Spritesheets

I personally found working with Spritesheets (images containing multiple assets inside) particularly painful with DragonRuby.

So lets start with the basics. Not everyone will need a Map Editor. But everyone will probably end up working with a spritesheets full of many sprites.

### Rendering the Canvas

The SpriteCanvas is a scene designed for viewing your sprites. Its a large "infinite" canvas where you can drop spritesheets and see them appear.

```rb
require "vendor/sprite_kit"

def tick(args)
  sprite_canvas ||= SpriteKit::Canvas.new
  sprite_canvas.tick(args)
end
```

### Using your created nodesets with multiple scenes

```rb
require "vendor/dragon_gui"

def tick(args)
  args.state.scenes ||= {
    sprite_canvas: SpriteKit::Canvas.new,
    game: Game.new
  }

  args.state.current_scene ||= :game

  args.state.scenes[args.state.current_scene].tick(args)

  # if next scene was set/requested, then transition the current scene to the next scene

  # Use whatever keybind you're comfortable with. "Tab" will cycle through scenes in this case.
  if args.inputs.keyboard.key_down.tab
    scene_keys = args.state.scenes.keys
    next_scene_index = scene_keys.find_index { |k| k == args.state.current_scene } + 1

    if next_scene_index > scene_keys.length - 1
      next_scene_index = 0
    end

    args.state.next_scene = args.state.scenes[scene_keys[next_scene_index]]
  end

  if args.state.next_scene
    args.state.current_scene = args.state.next_scene
    args.state.next_scene = nil
  end
end

class Game
  def initialize
  end

  def tick(args)
    if !@node_loader
        @node_loader = SpriteKit::NodeLoader.new
        @node_loader.load("data/nodes.json")
    end

    # Find a node
    # There are 2 keys to be aware of. First is the name of "nodeset" your node is a part of. The second piece is the "node name" within the nodeset.
    grass_top_left = args.state.sprite_manager.nodesets[:grass][:top_left].merge({
        x: 640,
        y: 360,
    })

    args.outputs.sprites << grass_top_left
  end
end
```

## Map Editor (Coming Soon...ish)
