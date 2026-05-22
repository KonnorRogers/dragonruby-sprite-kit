### Jumping - main.rb
```ruby
  # ./samples/99_genre_mario/01_jumping/app/main.rb
  def tick args
    defaults args
    input args
    calc args
    render args
  end

  def defaults args
    args.state.player ||= {
      x: Grid.w / 2,
      y: 0,
      w: 100,
      h: 100,
      dy: 0,
      action: :standing
    }

    args.state.jump ||= {
      power: 20,
      increase_frames: 10,
      increase_power: 1
    }

    args.state.gravity ||= -1
  end

  def input args
    if args.inputs.keyboard.key_down.space
      if args.state.player.action == :standing
        args.state.player.action = :jumping
        args.state.player.dy = args.state.jump.power

        # record when the action took place
        current_frame = Kernel.tick_count
        args.state.player.action_at = current_frame
      end
    end

    # if the space bar is being held
    if args.inputs.keyboard.key_held.space
      # is the player jumping
      is_jumping = args.state.player.action == :jumping

      # when was the jump performed
      time_of_jump = args.state.player.action_at

      # how much time has passed since the jump
      jump_elapsed_time = time_of_jump.elapsed_time

      # how much time is allowed for increasing power
      time_allowed = args.state.jump.increase_frames

      # if the player is jumping
      # and the elapsed time is less than
      # the allowed time
      if is_jumping && jump_elapsed_time < time_allowed
         # increase the dy by the increase power
         power_to_add = args.state.jump.increase_power
         args.state.player.dy += power_to_add
      end
    end
  end

  def calc args
    if args.state.player.action == :jumping
      args.state.player.y  += args.state.player.dy
      args.state.player.dy += args.state.gravity
    end

    if args.state.player.y < 0
      args.state.player.y      = 0
      args.state.player.action = :standing
    end
  end

  def render args
    args.outputs.sprites << {
      x: args.state.player.x -
         args.state.player.w / 2,
      y: args.state.player.y,
      w: args.state.player.w,
      h: args.state.player.h,
      path: 'sprites/square/red.png'
    }
  end

```

### Jumping And Collisions - main.rb
```ruby
  # ./samples/99_genre_mario/02_jumping_and_collisions/app/main.rb
  class Game
    attr_dr

    def tick
      defaults
      input
      calc
      render
    end

    def defaults
      state.gravity              ||= -1

      player.x                   ||= 64
      player.y                   ||= 800
      player.w                   ||= 50
      player.h                   ||= 50
      player.dx                  ||= 0
      player.dy                  ||= 0
      player.on_ground           ||= false

      player.max_speed           ||= 20
      player.jump_power          ||= 15
      player.jump_air_time       ||= 15
      player.jump_increase_power ||= 1

      state.tile_size            ||= 64
      if !state.tiles
        state.tiles                = [
          { ordinal_x:  0, ordinal_y: 0 },
          { ordinal_x:  1, ordinal_y: 0 },
          { ordinal_x:  2, ordinal_y: 0 },
          { ordinal_x:  3, ordinal_y: 0 },
          { ordinal_x:  4, ordinal_y: 0 },
          { ordinal_x:  5, ordinal_y: 0 },
          { ordinal_x:  6, ordinal_y: 0 },
          { ordinal_x:  7, ordinal_y: 0 },
          { ordinal_x:  8, ordinal_y: 0 },
          { ordinal_x:  9, ordinal_y: 0 },
          { ordinal_x: 10, ordinal_y: 0 },
          { ordinal_x: 11, ordinal_y: 0 },
          { ordinal_x: 12, ordinal_y: 0 },
          { ordinal_x: 13, ordinal_y: 0 },

          { ordinal_x:  3, ordinal_y: 1 },
          { ordinal_x:  3, ordinal_y: 2 },
          { ordinal_x:  6, ordinal_y: 1 },
          { ordinal_x:  6, ordinal_y: 2 },

          { ordinal_x:  9, ordinal_y: 3 },
          { ordinal_x: 10, ordinal_y: 3 },
          { ordinal_x: 11, ordinal_y: 3 },

          { ordinal_x: 10, ordinal_y: 4 },
          { ordinal_x: 11, ordinal_y: 4 },

          { ordinal_x: 11, ordinal_y: 5 },

          { ordinal_x: 12, ordinal_y: 2 },
        ]

        state.tiles.each do |t|
          t.rect = { x: t.ordinal_x * state.tile_size,
                     y: t.ordinal_y * state.tile_size,
                     w: state.tile_size,
                     h: state.tile_size }
        end
      end
    end

    def input
      input_jump
      input_move
    end

    def input_jump
      if inputs.keyboard.key_down.space
        player_jump
      end

      if inputs.keyboard.key_held.space
        player_jump_increase_air_time
      end
    end

    def input_move
      if inputs.keyboard.left
        player.dx -= 2
      elsif inputs.keyboard.right
        player.dx += 2
      end
      player.dx = player.dx.clamp(-player.max_speed, player.max_speed)
    end

    def calc
      calc_physics
      calc_game_over
    end

    def calc_physics
      player.x  += player.dx
      collision = state.tiles.find { |t| player.intersect_rect? t.rect }
      if collision
        if player.dx > 0
          player.x = collision.rect.x - player.w
        elsif player.dx < 0
          player.x = collision.rect.x + collision.rect.w
        end
      end
      player.dx *= 0.8

      player.y += player.dy
      collision = state.tiles.find { |t| player.intersect_rect? t.rect }
      if collision
        if player.dy > 0
          player.y = collision.rect.y - player.h
        elsif player.dy < 0
          player.y = collision.rect.y + collision.rect.h
        end
        player.dy = 0
        player.jump_at = nil
        player.on_ground = true
      else
        player.on_ground = false
      end
      player.dy = player.dy + state.gravity
      player.dy = player.dy.clamp(-state.tile_size, state.tile_size)
    end

    def calc_game_over
      if player.y < -64
        player.y = 800
        player.dx = 0
        player.dy = 0
      end
    end

    def render
      render_player
      render_tiles
      # render_grid
    end

    def render_player
      outputs.sprites << {
        x: player.x,
        y: player.y,
        w: player.w,
        h: player.h,
        path: 'sprites/square/red.png'
      }
    end

    def render_tiles
      outputs.sprites << state.tiles.map do |t|
        t.merge path: 'sprites/square/white.png',
                x: t.ordinal_x * state.tile_size,
                y: t.ordinal_y * state.tile_size,
                w: state.tile_size,
                h: state.tile_size
      end
    end

    def render_grid
      if Kernel.tick_count == 0
        outputs[:grid].background_color = [0, 0, 0, 0]
        outputs[:grid].borders << available_brick_locations
        outputs[:grid].labels  << available_brick_locations.map do |b|
          [
            b.merge(text: "#{b.ordinal_x},#{b.ordinal_y}",
                    x: b.x + 2,
                    y: b.y + 2,
                    size_enum: -3,
                    vertical_alignment_enum: 0,
                    blendmode: 0),
            b.merge(text: "#{b.x},#{b.y}",
                    x: b.x + 2,
                    y: b.y + 2 + 20,
                    size_enum: -3,
                    vertical_alignment_enum: 0,
                    blendmode: 0)
          ]
        end
      end

      outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: :grid }
    end

    def available_brick_locations
      (0..19).to_a
        .product(0..11)
        .map do |(ordinal_x, ordinal_y)|
        { ordinal_x: ordinal_x,
          ordinal_y: ordinal_y,
          x: ordinal_x * state.tile_size,
          y: ordinal_y * state.tile_size,
          w: state.tile_size,
          h: state.tile_size }
      end
    end

    def player
      state.player ||= args.state.new_entity :player
    end

    def player_jump
      return if !player.on_ground
      player.dy = state.player.jump_power
      player.jump_at = Kernel.tick_count
    end

    def player_jump_increase_air_time
      return if !player.jump_at
      return if player.jump_at.elapsed_time >= player.jump_air_time
      player.dy += player.jump_increase_power
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  DR.reset

```
