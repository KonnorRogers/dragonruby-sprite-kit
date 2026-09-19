module SpriteKit
  DR = Object.const_get("DR") || Object.const_get("GTK")

  def self.load_path
    File.join(File.dirname(__FILE__), "sprite_kit")
  end

  def self.to_load_path(file)
    File.join(self.load_path, file)
  end

  # This can get potentially deep if you have a lot of files or directories. Consider a fiber if its taking up too much time.
  def self.list_files_recursive(directory, max_iterations_for_fiber: 100, fiber: false)
    idx = 0
    files = []
    all_files = []

    # Seed with FULL paths so we never lose directory context.
    # reverse_each makes pop() yield entries in listing order,
    # matching the recursive version's traversal order.
    DR.list_files(directory).reverse_each do |f|
      files << File.join(directory, f)
      Fiber.yield if fiber && idx % max_iterations_for_fiber == 0
    end

    while file_path = files.pop
      idx += 1
      # file_path is a full path now, so check the basename for the hidden rule.
      next if File.basename(file_path).start_with?(".")

      stat = DR.stat_file(file_path)
      next if !stat
      stat.path = file_path

      if stat[:file_type] == :directory
        # Directories aren't part of the result; just descend.
        DR.list_files(file_path).reverse_each do |f|
          idx += 1
          files << File.join(file_path, f)
          Fiber.yield if fiber && idx % max_iterations_for_fiber == 0
        end

        next
      end

      all_files << stat

      Fiber.yield if fiber && idx % max_iterations_for_fiber == 0
    end

    all_files
  end

  def self.load(dir = self.load_path)
    files = self.list_files_recursive(dir)
    self.list_files_recursive(dir).each do |stat|
      if stat.file_type != :directory && stat.path.end_with?(".rb")
        require stat.path
      end
    end
  end
end

SpriteKit.load


