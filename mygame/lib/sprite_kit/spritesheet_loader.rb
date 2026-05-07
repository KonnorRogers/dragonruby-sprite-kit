module SpriteKit
  class SpritesheetLoader
    def initialize
      @loadable_extensions = [
        "jpeg",
        "jpg",
        "png"
      ]
    end

    def load_directory(directory, parent_node: nil, spritesheets: [])
      return [] if directory.to_s == ""

      # Create root node if none provided
      root_node = Node.new(parent: nil, value: { type: :directory, name: directory })
      parent_node ||= root_node

      GTK.list_files(directory).each do |file|
        stat = GTK.stat_file(File.join(directory, file))
        next if !stat

        if stat[:file_type] == :directory
          # Create a directory node and recurse
          dir_node = Node.new(parent: parent_node, value: { type: :directory, name: stat[:name], path: stat[:path] })
          parent_node.children << dir_node
          load_directory(stat[:path], parent_node: dir_node, spritesheets: spritesheets)
        end

        extension = file.split(".").last
        if @loadable_extensions.include?(extension)
          loaded = load_file(name: stat[:name], path: stat[:path])
          spritesheets << loaded

          # Create a leaf node for this spritesheet
          file_node = Node.new(parent: parent_node, value: loaded.merge(type: :file))
          parent_node.children << file_node
        end
      end

      {
        tree: Tree.new(root_node: root_node),
        spritesheets: spritesheets
      }
    end

    # @param [String] name - The name of the tilesheet
    # @param [String] path - The file path of the tilesheet
    def load_file(name:, path:)
      file_width, file_height = GTK.calcspritebox(path)

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

  class Tree
    attr_accessor :root_node

    def initialize(root_node:)
      @root_node = root_node
    end
  end

  class Node
    attr_accessor :children
    attr_reader :parent, :value

    def initialize(parent:, value:, children: [])
      @parent = parent
      @value = value
      @children = children
    end
  end
end
