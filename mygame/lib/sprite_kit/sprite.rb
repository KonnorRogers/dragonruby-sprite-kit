# Simple helper for making sprites complete with a "serialize" method.
module SpriteKit
  class Sprite
    attr_sprite

    def method_missing(m, *args, **kwargs, &block)
      name = m.to_s
      return super if name.end_with?("?", "!")

      name = name.chomp("=")
      ivar = "@#{name}"

      self.class.define_method(name) { instance_variable_get(ivar) }
      self.class.define_method("#{name}=") { |val| instance_variable_set(ivar, val) }

      send(m, *args, **kwargs, &block)
    end

    def respond_to_missing?(m, include_private = false)
      !m.to_s.end_with?("?", "!") || super
    end

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
