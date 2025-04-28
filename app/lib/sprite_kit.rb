class ::Array
  original_concat = instance_method(:concat)

  define_method(:concat) do |*arrays|
    bound_original_concat = original_concat.bind(self)
    arrays.each { |array| bound_original_concat.call(array) }
    self
  end
end

module SpriteKit
  def self.load_path
    File.join(File.dirname(__FILE__), "sprite_kit")
  end

  def self.to_load_path(file)
    File.join(self.load_path, file)
  end

  def self.load(dir = self.load_path)
    GTK.list_files(dir).each do |file|
      next if file.start_with?(".") || File.basename(file).start_with?(".")

      file = File.join(dir, file)
      stat = GTK.stat_file(file)

      next if !stat

      if stat[:file_type] == :directory
        self.load(stat[:path])
        next
      end

      if stat[:path].end_with?(".rb")
        puts "LOADING: ", stat[:path]
        require stat[:path]
      end
    end
  end
end

SpriteKit.load
