          new_sprite.prefab = prefab




          starting_sprite = @state.current_sprite.prefab[0]
          starting_x = starting_sprite.source_x
          starting_y = starting_sprite.source_y
          prefab = @state.current_sprite.prefab.map do |sprite|
            sprite.x = (current_sprite.x + sprite.source_x - starting_x - sprite.source_x_offset - (sprite.column_gap.idiv(@state.camera.scale)))
            sprite.y = (current_sprite.y + sprite.source_y - starting_y - sprite.source_y_offset - (sprite.row_gap.idiv(@state.camera.scale)))
            sprite.w = sprite.source_w
            sprite.h = sprite.source_h
            @state.camera.to_screen_space(sprite)
          end
          @state.draw_buffer[@state.camera_path].sprites.concat(prefab)
