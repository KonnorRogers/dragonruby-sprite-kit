# stat = {
#   path: String,
#   file_size: Int,
#   mod_time: Int,
#   create_time: Int,
#   access_time: Int,
#   readonly: Boolean,
#   file_type: Symbol (:regular, :directory, :symlink, :other),
# }

module SpriteKit
  class FileWatcher
    attr_accessor :cache, :files_per_tick

    def initialize(&block)
      @cache = {}
      @modified_files = []
      @callback = block || proc {}
      @files_per_tick = 100
    end

    def tick_watch(*directories)
      if @fiber_watch && @fiber_watch.alive?
        @fiber_watch.resume
      else
        @fiber_watch = Fiber.new { watch(*directories, fiber: true) }
      end
    end

    def watch(*directories, fiber: false)
      directories.flatten.each do |directory|
        SpriteKit.list_files_recursive(directory, fiber: fiber, max_iterations_for_fiber: @files_per_tick).each do |stat|
          add(stat)
        end
      end
    end

    def watched_files
      @cache.values
    end

    # Flushes any modified files and calls your block on it.
    def flush
      while stat = @modified_files.pop()
        @callback.call(stat)
      end
    end

    # Will add a stat to the cache.
    def add(stat)
      if !stat
        return
      end

      existing_stat = @cache[stat.path]

      if !existing_stat || existing_stat.mod_time != stat.mod_time || existing_stat.file_size != stat.file_size
        @cache[stat.path] = stat
        @modified_files << stat
      end
    end

    def delete(stat)
      @cache.delete(stat.path)
    end
  end
end
