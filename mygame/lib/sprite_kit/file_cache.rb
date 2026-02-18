module SpriteKit
  class FileCache
    def initialize
      @cache = {}
    end

    def add(path)
      stats = GTK.stat_file
      if stats && @cache[path].to_i < stats.mod_time
        GTK.reset_sprite(path)
        @cache[path] = stats.mod_time
      end
    end

    def delete(path)
      @cache.delete(path)
    end

    def has?(path)
      @cache[path] != nil
    end

    def get(path)
      @cache.fetch(path)
    end
  end
end
