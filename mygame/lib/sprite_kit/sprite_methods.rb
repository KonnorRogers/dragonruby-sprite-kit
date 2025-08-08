
module SpriteKit
  module SpriteMethods
    def self.generate_prefab(sprite, state)
      prefab = []

      rect_size = state.tile_selection
      column_gap = state.tile_selection.column_gap
      row_gap = state.tile_selection.row_gap

      columns = (sprite.source_w + column_gap).idiv(rect_size.w + column_gap)
      rows = (sprite.source_h + row_gap).idiv(rect_size.h + row_gap)

      sprite.columns = columns
      sprite.rows = rows

      columns.times do |column|
        rows.times do |row|
          # column_gap = column == 0 ? 0 : column_gap
          # row_gap = row == 0 ? 0 : row_gap
          offset_x = column * column_gap
          offset_y = row * row_gap
          prefab << {
            source_x: sprite.source_x + offset_x + (column * rect_size.w),
            source_y: sprite.source_y + offset_y + (row * rect_size.h),
            source_w: rect_size.w,
            source_h: rect_size.h,
            path: sprite.path,
            offset_x: offset_x,
            offset_y: offset_y,
          }
        end
      end

      prefab
    end

    def self.render_prefab(current_sprite)
      if current_sprite.prefab.nil? || current_sprite.prefab.length <= 0
        return [current_sprite]
      end

      starting_x = current_sprite.source_x
      starting_y = current_sprite.source_y
      current_sprite.prefab.map do |node|
        node.dup.tap do |sprite|
          sprite.x = current_sprite.x - starting_x + node.source_x - node.offset_x
          sprite.y = current_sprite.y - starting_y + node.source_y - node.offset_y
          sprite.w = node.source_w
          sprite.h = node.source_h
        end
      end
    end
  end

end
