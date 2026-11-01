require SpriteKit.to_load_path("hash_methods")
require SpriteKit.to_load_path("serializer")

module SpriteKit
  # The data side of the map editor. Holds layers of tiles, an undo / redo history, and handles saving / loading.
  # Rendering and input live in `SpriteKit::MapEditor`.
  #
  # @example
  #   map = SpriteKit::Map.load("data/map.json")
  #   map.layers.each do |layer|
  #     args.outputs.sprites.concat(layer.tiles) if layer.visible
  #   end
  #
  # Tiles are plain sprite hashes in world space:
  #   { x:, y:, w:, h:, path:, source_x:, source_y:, source_w:, source_h: }
  class Map
    VERSION = 1
    MAX_HISTORY = 200

    attr_accessor :path, :layers, :tile_w, :tile_h, :current_layer_index
    attr_reader :undo_stack, :redo_stack

    def initialize(path: "data/map.json", tile_w: 16, tile_h: 16, layers: nil)
      @path = path
      @tile_w = tile_w
      @tile_h = tile_h
      @layers = layers || []
      @undo_stack = []
      @redo_stack = []

      if @layers.length < 1
        @layers << create_layer
      end

      @commands = {
        tiles: {
          execute: -> (change) {
            layer = layer_by_id(change.layer_id)
            change.removed.each { |tile| layer.tiles.delete(tile) }
            layer.tiles.concat(change.added)
          },
          undo: -> (change) {
            layer = layer_by_id(change.layer_id)
            change.added.each { |tile| layer.tiles.delete(tile) }
            layer.tiles.concat(change.removed)
          }
        },
        add_layer: {
          execute: -> (change) {
            @layers.insert(change[:index], change[:layer])
            @current_layer_index = change[:index]
          },
          undo: -> (change) {
            @layers.delete_at(change[:index])
            clamp_current_layer
          }
        },
        remove_layer: {
          execute: -> (change) {
            @layers.delete_at(change[:index])
            clamp_current_layer
          },
          undo: -> (change) {
            @layers.insert(change[:index], change[:layer])
            @current_layer_index = change[:index]
          }
        },
        move_layer: {
          execute: -> (change) {
            swap_layers(change[:from], change[:to])
            @current_layer_index = change[:to]
          },
          undo: -> (change) {
            swap_layers(change[:to], change[:from])
            @current_layer_index = change[:from]
          }
        }
      }
      @current_layer_index = @layers.length - 1
    end

    # Returns a new map from the file at `path`, or an empty map if the file doesn't exist.
    def self.load(path, **kwargs)
      map = new(path: path, **kwargs)
      map.load
      map
    end

    def current_layer
      @layers[@current_layer_index]
    end

    def layer_by_id(id)
      @layers.find { |layer| layer.id == id }
    end

    def create_layer(name: nil)
      {
        id: GTK.create_uuid,
        name: name || "Layer #{@layers.length + 1}",
        visible: true,
        tiles: []
      }
    end

    # Inserts a new layer above the current layer and makes it current.
    def add_layer(name: nil)
      layer = create_layer(name: name)
      index = @current_layer_index + 1
      @layers.insert(index, layer)
      @current_layer_index = index
      push_history({ command: :add_layer, layer: layer, index: index })
      layer
    end

    def remove_layer(index = @current_layer_index)
      # Can't remove the last layer, the editor always needs something to draw on.
      return if @layers.length <= 1

      layer = @layers.delete_at(index)
      return if !layer

      clamp_current_layer
      push_history({ command: :remove_layer, layer: layer, index: index })
      layer
    end

    # Moves a layer up (+1) or down (-1) the draw order.
    def move_layer(index, direction)
      to = index + direction
      return if to < 0 || to > @layers.length - 1

      swap_layers(index, to)
      @current_layer_index = to
      push_history({ command: :move_layer, from: index, to: to })
    end

    def toggle_layer_visibility(index = @current_layer_index)
      layer = @layers[index]
      layer.visible = !layer.visible if layer
    end

    # Starts a new set of tile changes against a layer. Pass it to `place_tile` / `erase`, then `commit` it.
    # All changes in a single commit get undone / redone together (ie: a brush stroke).
    def begin_change(layer = current_layer)
      { command: :tiles, layer_id: layer.id, added: [], removed: [] }
    end

    # Places a tile, replacing anything it overlaps on the same layer.
    def place_tile(tile, change)
      layer = layer_by_id(change.layer_id)
      erase(tile, change)
      layer.tiles << tile
      change.added << tile
      tile
    end

    # Removes every tile on the change's layer that intersects `rect`.
    def erase(rect, change)
      layer = layer_by_id(change.layer_id)
      intersecting_tiles = Geometry.find_all_intersect_rect(rect, layer.tiles)
      return intersecting_tiles if intersecting_tiles.length <= 0

      intersecting_tiles.each { |tile| remove_tile(layer, tile, change) }
      intersecting_tiles
    end

    def commit(change)
      return false if change.added.length <= 0 && change.removed.length <= 0

      push_history(change)
      true
    end

    # Finds the top-most visible tile containing the point.
    # @return [Hash, nil] { tile:, layer_index: }
    def tile_at(point)
      (@layers.length - 1).downto(0) do |index|
        layer = @layers[index]
        next if !layer.visible

        tile = layer.tiles.reverse_each.find do |t|
          point.x >= t.x && point.x < t.x + t.w && point.y >= t.y && point.y < t.y + t.h
        end

        return { tile: tile, layer_index: index } if tile
      end

      nil
    end

    def tile_count
      @layers.sum { |layer| layer.tiles.length }
    end

    def can_undo?
      @undo_stack.length > 0
    end

    def can_redo?
      @redo_stack.length > 0
    end

    def undo
      change = @undo_stack.pop
      return false if !change

      revert_change(change)
      @redo_stack << change
      true
    end

    def redo
      change = @redo_stack.pop
      return false if !change

      execute_change(change)
      @undo_stack << change
      true
    end

    def serialize
      {
        version: VERSION,
        tile_w: @tile_w,
        tile_h: @tile_h,
        layers: @layers.map do |layer|
          {
            id: layer.id,
            name: layer.name,
            visible: layer.visible,
            tiles: layer.tiles
          }
        end
      }
    end

    def to_json
      SpriteKit::Serializer.to_json(serialize)
    end

    def save(path = @path)
      GTK.write_file(path, to_json)
    end

    # @return [Boolean] true if a map file was loaded.
    def load(path = @path)
      return false if !GTK.stat_file(path)

      json = GTK.parse_json_file(path)
      return false if !json

      data = HashMethods.symbolize_keys(json)

      @tile_w = data.tile_w || @tile_w
      @tile_h = data.tile_h || @tile_h

      layers = (data.layers || []).map.with_index do |layer, index|
        {
          id: layer.id || GTK.create_uuid,
          name: layer.name || "Layer #{index + 1}",
          visible: layer.visible != false,
          tiles: layer.tiles || []
        }
      end

      @layers = layers if layers.length > 0
      @current_layer_index = @layers.length - 1
      @undo_stack.clear
      @redo_stack.clear
      true
    rescue => e
      puts "SpriteKit::Map: Unable to load #{path}: #{e}"
      false
    end

    private

    def remove_tile(layer, tile, change)
      # A tile placed and removed in the same change cancels out.
      if change.added.delete(tile)
        layer.tiles.delete(tile)
        return
      end

      layer.tiles.delete(tile)
      change.removed << tile
    end

    def push_history(change)
      @undo_stack << change
      @undo_stack.shift if @undo_stack.length > MAX_HISTORY
      @redo_stack.clear
    end

    def execute_change(change)
      @commands[change.command].execute.call(change)
    end

    def revert_change(change)
      @commands[change.command].undo.call(change)
    end

    def swap_layers(a, b)
      @layers[a], @layers[b] = @layers[b], @layers[a]
    end

    def clamp_current_layer
      @current_layer_index = @current_layer_index.clamp(0, @layers.length - 1)
    end
  end
end
