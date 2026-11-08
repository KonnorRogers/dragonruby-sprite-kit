# Simple helper for making sprites complete with a "serialize" method.
module SpriteKit
  class Sprite
    attr_sprite

    def initialize(**kwargs)
      kwargs.each { |k, v| send("#{k}=", v) }
    end

    def [](key)
      send(key)
    end

    def []=(key, value)
      send("#{key}=", value)
    end

    def key?(key)
      respond_to?(key) || instance_variable_defined?(key)
    end

    def method_missing(m, *args, &block)
      name = m.to_s
      return super if name.end_with?("?", "!") || block

      if name.end_with?("=") && !name.end_with?("==") && args.length == 1
        self.class.attr_accessor(name.chomp("="))   # first write defines the accessor
        send(m, *args)
      elsif args.empty?
        instance_variable_get("@#{name}")   # nil if unset, the value if set
      else
        super
      end
    end

    def respond_to_missing?(m, include_private = false)
      name = m.to_s
      if name.end_with?("=") && !name.end_with?("==")
        true
      elsif name.end_with?("?", "!")
        false
      else
        instance_variable_defined?("@#{name}")
      end
    end

    def serialize
      instance_variables.to_h do |var|
        [var.to_s.delete_prefix("@").to_sym, instance_variable_get(var)]
      end
    end
  end
end
