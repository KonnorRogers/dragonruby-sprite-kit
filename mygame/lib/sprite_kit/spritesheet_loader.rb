module SpriteKit
  class SpritesheetLoader
    def initialize
      @loadable_extensions = [
        "jpeg",
        "jpg",
        "png"
      ]
    end

    def load_directory(directory, tile_width: 16, tile_height: 16, spritesheets: [])
      return [] if directory.to_s == ""

      GTK.list_files(directory).each do |file|
        stat = GTK.stat_file(File.join(directory, file))

        next if !stat

        if stat[:file_type] == :directory
          load_directory(stat[:path], tile_width: tile_width, tile_height: tile_height, spritesheets: spritesheets)
        end

        extension = file.split(".").last

        if @loadable_extensions.include?(extension)
          spritesheets << load_file(
              name: stat[:name],
              path: stat[:path],
          )
        end
      end
      spritesheets
    end

    # @param [String] name - The name of the tilesheet
    # @param [String] path - The file path of the tilesheet
    def load_file(name:, path:)
      file_width, file_height = $gtk.calcspritebox(path)

      {
        name: name,
        path: path,
        file_width: file_width,
        file_height: file_height,
        w: file_width,
        h: file_height,
      }
    end
  end
end
