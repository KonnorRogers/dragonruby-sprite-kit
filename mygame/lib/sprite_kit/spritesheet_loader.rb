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
              tile_width: tile_width,
              tile_height: tile_height
          )
        end
      end
      spritesheets
    end

    # @param [String] name - The name of the tilesheet
    # @path [String] path - The file path of the tilesheet
    # @param [Number] [tile_width=16] - The width of each tile
    # @param [Number] [tile_height=16] - The height of each tile
    def load_file(name:, path:, tile_width: 16, tile_height: 16)
      file_width, file_height = $gtk.calcspritebox(path)
      tiles = []

      rows = file_height.idiv(tile_height)
      columns = file_width.idiv(tile_width)

      rows.times do |y|
        columns.times do |x|
          tile_name = "#{name}__#{x.to_s.rjust(3, "0")}"

          source_x = x * tile_width
          source_y = y * tile_height

          tiles << {
            tilemap_name: name,
            tile_name: tile_name,
            source_x: source_x,
            source_y: source_y,
            source_h: tile_height,
            source_w: tile_width,
            path: path,
            animation_duration: nil,
            animation_frames: nil,
            x: x,
            y: y,
            h: tile_height,
            w: tile_width,
          }
        end
      end

      {
        name: name,
        tiles: tiles,
        columns: columns,
        rows: rows,
        path: path,
        file_width: file_width,
        file_height: file_height,
        w: file_width,
        h: file_height,
      }
    end
  end
end
