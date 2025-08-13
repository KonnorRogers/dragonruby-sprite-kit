# DragonRuby Sprite Kit

## What is this?

Right now Sprite Kit is a basic utility helper for me with things I want to carry between projects.

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
  spritesheet_scene ||= SpriteKit::SpritesheetScene.new
  spritesheet_scene.tick(args)
end
```

The above will render a canvas for you to select your sprites from a canvas and copy them your clipboard.




## Map Editor (Maybe?)
