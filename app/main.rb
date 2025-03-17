require "../lib/dragonruby_sprite_manager"

def tick(args)
  SpriteManager::Canvas.new.tick(args)
end
