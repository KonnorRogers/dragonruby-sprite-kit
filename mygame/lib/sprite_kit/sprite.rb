# Simple helper for making sprites complete with a "serialize" method.
module SpriteKit
  class Sprite
    attr_sprite

    def initialize(**kwargs)
      kwargs.each do |kwarg, value|
        instance_variable_set("@#{kwarg}", value)
      end
    end

    def serialize
      hash = {}
      instance_variables.each do |var|
        # Remove the '@' prefix from the instance variable name for the hash key
        key = var.to_s.delete('@').to_sym
        value = instance_variable_get(var)
        hash[key] = value
      end
      hash
    end
  end
end
