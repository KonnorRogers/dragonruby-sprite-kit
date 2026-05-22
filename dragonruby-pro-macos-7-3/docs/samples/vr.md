### Skybox - main.rb
```ruby
  # ./samples/14_vr/01_skybox/app/main.rb
  require 'app/tick.rb'

  def tick args
    DR.start_server! port: 9001, enable_in_prod: true
    tick_game args
  end

```

### Skybox - tick.rb
```ruby
  # ./samples/14_vr/01_skybox/app/tick.rb
  def skybox args, x, y, z, size
    sprite = { a: 80, path: 'sprites/box.png' }

    front      = { x: x, y: y, z: z, w: size, h: size, **sprite }
    front_720  = { x: x, y: y, z: z + 1, w: size, h: size * 9.fdiv(16), **sprite }
    back       = { x: x, y: y, z: z + size, w: size, h: size, **sprite }
    bottom     = { x: x, y: y - size.half, z: z + size.half, w: size, h: size, angle_x: 90, **sprite }
    top        = { x: x, y: y + size.half, z: z + size.half, w: size, h: size, angle_x: 90, **sprite }
    left       = { x: x - size.half, y: y, w: size, h: size, z: z + size.half, angle_y: 90, **sprite }
    right      = { x: x + size.half, y: y, w: size, h: size, z: z + size.half, angle_y: 90, **sprite }

    args.outputs.sprites << [back,
                             left,
                             top,
                             bottom,
                             right,
                             front,
                             front_720]
  end

  def tick_game args
    args.outputs.background_color = [0, 0, 0]

    args.state.z     ||= 0
    args.state.scale ||= 0.05

    if args.inputs.controller_one.key_down.a
      if args.grid.name == :bottom_left
        args.grid.origin_center!
      else
        args.grid.origin_bottom_left!
      end
    end

    args.state.scale += args.inputs.controller_one.right_analog_x_perc * 0.01
    args.state.z -= args.inputs.controller_one.right_analog_y_perc * 1.5

    args.state.scale = args.state.scale.clamp(0.05, 1.0)
    args.state.z = 0    if args.state.z < 0
    args.state.z = 1280 if args.state.z > 1280

    skybox args, 0, 0, args.state.z, 1280 * args.state.scale

    render_guides args
  end

  def render_guides args
    label_style = { alignment_enum: 1,
                    size_enum: -2,
                    vertical_alignment_enum: 0, r: 255, g: 255, b: 255 }

    instructions = [
      "controller position: #{args.inputs.controller_one.left_hand.x} #{args.inputs.controller_one.left_hand.y} #{args.inputs.controller_one.left_hand.z}",
      "scale: #{args.state.scale.to_sf} (right analog left/right)",
      "z: #{args.state.z.to_sf} (right analog up/down)",
      "origin: :#{args.grid.name} (A button)",
    ]

    args.outputs.labels << instructions.map_with_index do |text, i|
      { x: 640,
        y: 100 + ((instructions.length - (i + 3)) * 22),
        z: args.state.z + 2,
        a: 255,
        text: text,
        ** label_style,
        alignment_enum: 1,
        vertical_alignment_enum: 0 }
    end

    # lines for scaled box
    size      = 1280 * args.state.scale
    size_16_9 = size * 9.fdiv(16)

    args.outputs.primitives << [
      { x: size - 1280, y: size,        z:            0, w: 1280 * 2, r: 128, g: 128, b: 128, a:  64 }.line!,
      { x: size - 1280, y: size,        z: args.state.z + 2, w: 1280 * 2, r: 128, g: 128, b: 128, a: 255 }.line!,

      { x: size - 1280, y: size_16_9,   z:            0, w: 1280 * 2, r: 128, g: 128, b: 128, a:  64 }.line!,
      { x: size - 1280, y: size_16_9,   z: args.state.z + 2, w: 1280 * 2, r: 128, g: 128, b: 128, a: 255 }.line!,

      { x: size,        y: size - 1280, z:            0, h: 1280 * 2, r: 128, g: 128, b: 128, a:  64 }.line!,
      { x: size,        y: size - 1280, z: args.state.z + 2, h: 1280 * 2, r: 128, g: 128, b: 128, a: 255 }.line!,

      { x: size,        y: size,        z: args.state.z + 3, size_enum: -2,
        vertical_alignment_enum: 0,
        text: "#{size.to_sf}, #{size.to_sf}, #{args.state.z.to_sf}",
        r: 255, g: 255, b: 255, a: 255 }.label!,

      { x: size,        y: size_16_9,   z: args.state.z + 3, size_enum: -2,
        vertical_alignment_enum: 0,
        text: "#{size.to_sf}, #{size_16_9.to_sf}, #{args.state.z.to_sf}",
        r: 255, g: 255, b: 255, a: 255 }.label!,
    ]

    xs = [
      { description: "left",   x:    0, alignment_enum: 0 },
      { description: "center", x:  640, alignment_enum: 1 },
      { description: "right",  x: 1280, alignment_enum: 2 },
    ]

    ys = [
      { description: "bottom",        y:    0, vertical_alignment_enum: 0 },
      { description: "center",        y:  640, vertical_alignment_enum: 1 },
      { description: "center (720p)", y:  360, vertical_alignment_enum: 1 },
      { description: "top",           y: 1280, vertical_alignment_enum: 2 },
      { description: "top (720p)",    y:  720, vertical_alignment_enum: 2 },
    ]

    args.outputs.primitives << xs.product(ys).map do |(xdef, ydef)|
      [
        { x: xdef.x,
          y: ydef.y,
          z: args.state.z + 3,
          text: "#{xdef.x.to_sf}, #{ydef.y.to_sf} #{args.state.z.to_sf}",
          **label_style,
          alignment_enum: xdef.alignment_enum,
          vertical_alignment_enum: ydef.vertical_alignment_enum
        },
        { x: xdef.x,
          y: ydef.y - 20,
          z: args.state.z + 3,
          text: "#{ydef.description}, #{xdef.description}",
          **label_style,
          alignment_enum: xdef.alignment_enum,
          vertical_alignment_enum: ydef.vertical_alignment_enum
        }
      ]
    end

    args.outputs.primitives << xs.product(ys).map do |(xdef, ydef)|
      [
        {
          x: xdef.x - 1280,
          y: ydef.y,
          w: 1280 * 2,
          a: 64,
          r: 128, g: 128, b: 128
        }.line!,
        {
          x: xdef.x,
          y: ydef.y - 720,
          h: 720 * 2,
          a: 64,
          r: 128, g: 128, b: 128
        }.line!,
      ].map do |p|
        [
          p.merge(z:            0, a:  64),
          p.merge(z: args.state.z + 2, a: 255)
        ]
      end
    end
  end

  DR.reset

```

### Top Down Rpg - main.rb
```ruby
  # ./samples/14_vr/02_top_down_rpg/app/main.rb
  require 'app/tick.rb'

  def tick args
    DR.start_server! port: 9001, enable_in_prod: true
    tick_game args
  end

```

### Top Down Rpg - tick.rb
```ruby
  # ./samples/14_vr/02_top_down_rpg/app/tick.rb
  class Game
    attr_dr

    def tick
      outputs.background_color = [0, 0, 0]
      args.state.tile_size     = 80
      args.state.player_speed  = 4
      args.state.player      ||= tile(args, 7, 3, 0, 128, 180)
      generate_map args

      # adds walls, goal, and player to args.outputs.solids so they appear on screen
      args.outputs.solids << args.state.goal
      args.outputs.solids << args.state.walls
      args.outputs.solids << args.state.player

      args.outputs.solids << args.state.walls.map { |s| s.to_hash.merge(z: 2, g: 80) }
      args.outputs.solids << args.state.walls.map { |s| s.to_hash.merge(z: 10, g: 255, a: 50) }

      # if player's box intersects with goal, a label is output onto the screen
      if args.state.player.intersect_rect? args.state.goal
        args.outputs.labels << { x: 640,
                                 y: 360,
                                 z: 10,
                                 text: "YOU'RE A GOD DAMN WIZARD, HARRY.",
                                 size_enum: 10,
                                 alignment_enum: 1,
                                 vertical_alignment_enum: 1,
                                 r: 255,
                                 g: 255,
                                 b: 255 }
      end

      move_player args, -1,  0 if args.inputs.keyboard.left  || args.inputs.controller_one.left # x position decreases by 1 if left key is pressed
      move_player args,  1,  0 if args.inputs.keyboard.right || args.inputs.controller_one.right # x position increases by 1 if right key is pressed
      move_player args,  0, -1 if args.inputs.keyboard.up    || args.inputs.controller_one.down # y position increases by 1 if up is pressed
      move_player args,  0,  1 if args.inputs.keyboard.down  || args.inputs.controller_one.up # y position decreases by 1 if down is pressed
    end

    # Sets position, size, and color of the tile
    def tile args, x, y, *color
      [x * args.state.tile_size, # sets definition for array using method parameters
       y * args.state.tile_size, # multiplying by tile_size sets x and y to correct position using pixel values
       args.state.tile_size,
       args.state.tile_size,
       *color]
    end

    # Creates map by adding tiles to the wall, as well as a goal (that the player needs to reach)
    def generate_map args
      return if args.state.area

      # Creates the area of the map. There are 9 rows running horizontally across the screen
      # and 16 columns running vertically on the screen. Any spot with a "1" is not
      # open for the player to move into (and is green), and any spot with a "0" is available
      # for the player to move in.
      args.state.area = [
        [1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1,],
        [1, 1, 1, 2, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1,], # the "2" represents the goal
        [1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1,],
        [1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1,],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,],
        [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1,],
        [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1,],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
      ].reverse # reverses the order of the area collection

      # By reversing the order, the way that the area appears above is how it appears
      # on the screen in the game. If we did not reverse, the map would appear inverted.

      #The wall starts off with no tiles.
      args.state.walls = []

      # If v is 1, a green tile is added to args.state.walls.
      # If v is 2, a black tile is created as the goal.
      args.state.area.map_2d do |y, x, v|
        if    v == 1
          args.state.walls << tile(args, x, y, 0, 255, 0) # green tile
        elsif v == 2 # notice there is only one "2" above because there is only one single goal
          args.state.goal   = tile(args, x, y, 180,  0, 0) # black tile
        end
      end
    end

    # Allows the player to move their box around the screen
    def move_player args, *vector
      box = args.state.player.shift_rect(vector) # box is able to move at an angle

      # If the player's box hits a wall, it is not able to move further in that direction
      return if args.state.walls
                  .any_intersect_rect?(box)

      # Player's box is able to move at angles (not just the four general directions) fast
      args.state.player =
        args.state.player
          .shift_rect(vector.x * args.state.player_speed, # if we don't multiply by speed, then
                      vector.y * args.state.player_speed) # the box will move extremely slow
    end
  end

  $game = Game.new

  def tick_game args
    $game.args = args
    $game.tick
  end

  DR.reset

```

### Space Invaders - main.rb
```ruby
  # ./samples/14_vr/03_space_invaders/app/main.rb
  require 'app/tick.rb'

  def tick args
    DR.start_server! port: 9001, enable_in_prod: true
    tick_game args
  end

```

### Space Invaders - tick.rb
```ruby
  # ./samples/14_vr/03_space_invaders/app/tick.rb
  class Game
    attr_dr

    def tick
      grid.origin_center!
      defaults
      outputs.background_color = [0, 0, 0]
      args.outputs.sprites << state.enemies.map { |e| enemy_prefab e }.to_a
    end

    def defaults
      state.enemy_sprite_size = 64
      state.row_size = 16
      state.max_rows = 20
      state.enemies ||= 32.map_with_index do |i|
        x = i % 16
        y = i.idiv 16
        { row: y, col: x }
      end
    end

    def enemy_prefab enemy
      if enemy.row > state.max_rows
        raise "#{enemy}"
      end
      relative_row = enemy.row + 1
      z = 50 - relative_row * 10
      x = (enemy.col * state.enemy_sprite_size) - (state.enemy_sprite_size * state.row_size).idiv(2)
      enemy_sprite(x, enemy.row * 10 + 100, z * 10, enemy)
    end

    def enemy_sprite x, y, z, meta
      index = 0.frame_index count: 2, hold_for: 50, repeat: true
      { x: x,
        y: y,
        z: z,
        w: state.enemy_sprite_size,
        h: state.enemy_sprite_size,
        path: 'sprites/enemy.png',
        source_x: 128 * index,
        source_y: 0,
        source_w: 128,
        source_h: 128,
        meta: meta }
    end
  end

  $game = Game.new

  def tick_game args
    $game.args = args
    $game.tick
  end

  DR.reset

```

### Let There Be Light - main.rb
```ruby
  # ./samples/14_vr/04_let_there_be_light/app/main.rb
  require 'app/tick.rb'

  def tick args
    DR.start_server! port: 9001, enable_in_prod: true
    tick_game args
  end

```

### Let There Be Light - tick.rb
```ruby
  # ./samples/14_vr/04_let_there_be_light/app/tick.rb
  class Game
    attr_dr

    def tick
      grid.origin_center!
      defaults
      state.angle_shift_x ||= 180
      state.angle_shift_y ||= 180

      if inputs.controller_one.right_analog_y_perc.round(2) != 0.00
        args.state.star_distance += (inputs.controller_one.right_analog_y_perc * 0.25) ** 2 * inputs.controller_one.right_analog_y_perc.sign
        state.star_distance = state.star_distance.clamp(state.min_star_distance, state.max_star_distance)
        state.star_sprites = calc_star_primitives
      elsif inputs.controller_one.down
        args.state.star_distance += (1.0 * 0.25) ** 2
        state.star_distance = state.star_distance.clamp(state.min_star_distance, state.max_star_distance)
        state.star_sprites = calc_star_primitives
      elsif inputs.controller_one.up
        args.state.star_distance -= (1.0 * 0.25) ** 2
        state.star_distance = state.star_distance.clamp(state.min_star_distance, state.max_star_distance)
        state.star_sprites = calc_star_primitives
      end

      render
    end

    def calc_star_primitives
      args.state.stars.map do |s|
        w = (32 * state.star_distance).clamp(1, 32)
        h = (32 * state.star_distance).clamp(1, 32)
        x = (state.max.x * state.star_distance) * s.xr
        y = (state.max.y * state.star_distance) * s.yr
        z = state.center.z + (state.max.z * state.star_distance * 10 * s.zr)

        angle_x = Math.atan2(z - 600, y).to_degrees + 90
        angle_y = Math.atan2(z - 600, x).to_degrees + 90

        draw_x = x - w.half
        draw_y = y - 40 - h.half
        draw_z = z

        { x: draw_x,
          y: draw_y,
          z: draw_z,
          b: 255,
          w: w,
          h: h,
          angle_x: angle_x,
          angle_y: angle_y,
          path: 'sprites/star.png' }
      end
    end

    def render
      outputs.background_color = [0, 0, 0]
      if state.star_distance <= 1.0
        text_alpha = (1 - state.star_distance) * 255
        args.outputs.labels << { x: 0, y: 50, text: "Let there be light.", r: 255, g: 255, b: 255, size_enum: 1, alignment_enum: 1, a: text_alpha }
        args.outputs.labels << { x: 0, y: 25, text: "(right analog: up/down)", r: 255, g: 255, b: 255, size_enum: -2, alignment_enum: 1, a: text_alpha }
      end

      args.outputs.sprites << state.star_sprites
    end

    def random_point
      r = { xr: 2.randomize(:ratio) - 1,
            yr: 2.randomize(:ratio) - 1,
            zr: 2.randomize(:ratio) - 1 }
      if (r.xr ** 2 + r.yr ** 2 + r.zr ** 2) > 1.0
        return random_point
      else
        return r
      end
    end

    def defaults
      state.max_star_distance ||= 100
      state.min_star_distance ||= 0.001
      state.star_distance     ||= 0.001
      state.star_angle        ||= 0

      state.center.x       ||= 0
      state.center.y       ||= 0
      state.center.z       ||= 30
      state.max.x          ||= 640
      state.max.y          ||= 640
      state.max.z          ||= 50

      state.stars ||= 1500.map do
        random_point
      end

      state.star_sprites ||= calc_star_primitives
    end
  end

  $game = Game.new

  def tick_game args
    $game.args = args
    $game.tick
  end

  DR.reset

```

### Draw A Cube - main.rb
```ruby
  # ./samples/14_vr/05_draw_a_cube/app/main.rb
  require 'app/tick.rb'

  def tick args
    DR.start_server! port: 9001, enable_in_prod: true
    tick_game args
  end

```

### Draw A Cube - tick.rb
```ruby
  # ./samples/14_vr/05_draw_a_cube/app/tick.rb
  def cube args, x, y, z, size
    sprite = { w: size, h: size, path: 'sprites/square/blue.png', a: 80 }
    back   = { x: x,                 y: y,                 z: z - size.half + 1,              **sprite }
    front  = { x: x,                 y: y,                 z: z + size.half - 1,              **sprite }
    top    = { x: x,                 y: y + size.half - 1, z: z,                 angle_x: 90, **sprite }
    bottom = { x: x,                 y: y - size.half + 1, z: z,                 angle_x: 90, **sprite }
    left   = { x: x - size.half + 1, y: y,                 z: z,                 angle_y: 90, **sprite }
    right  = { x: x + size.half - 1, y: y,                 z: z,                 angle_y: 90, **sprite }

    args.outputs.sprites << [back, left, top, bottom, right, front]
  end

  def tick_game args
    args.grid.origin_center!
    args.outputs.background_color = [0, 0, 0]

    args.state.x ||= 0
    args.state.y ||= 0

    args.state.x += 10 * args.inputs.controller_one.right_analog_x_perc
    args.state.y += 10 * args.inputs.controller_one.right_analog_y_perc

    cube args, args.state.x, args.state.y, 0, 100
  end

```

### Draw A Cube With Triangles - main.rb
```ruby
  # ./samples/14_vr/05_draw_a_cube_with_triangles/app/main.rb
  require 'app/tick.rb'

  def tick args
    DR.start_server! port: 9001, enable_in_prod: true
    tick_game args
  end

```

### Draw A Cube With Triangles - tick.rb
```ruby
  # ./samples/14_vr/05_draw_a_cube_with_triangles/app/tick.rb
  include MatrixFunctions

  def tick args
    args.grid.origin_center!

    # model A
    args.state.a = [
      [vec4(0, 0, 0, 1),   vec4(0.1, 0, 0, 1),   vec4(0, 0.1, 0, 1)],
      [vec4(0.1, 0, 0, 1), vec4(0.1, 0.1, 0, 1), vec4(0, 0.1, 0, 1)]
    ]

    # model to world
    args.state.back = mul_triangles args,
                                    args.state.a,
                                    (translate -0.05, -0.05, 0),
                                    (translate 0, 0, -0.05),
                                    (rotate_x Kernel.tick_count),
                                    (rotate_y Kernel.tick_count),
                                    (rotate_z Kernel.tick_count)

    args.state.front = mul_triangles args,
                                     args.state.a,
                                     (translate -0.05, -0.05, 0),
                                     (translate 0, 0, 0.05),
                                     (rotate_x Kernel.tick_count),
                                     (rotate_y Kernel.tick_count),
                                     (rotate_z Kernel.tick_count)

    args.state.left = mul_triangles args,
                                    args.state.a,
                                    (translate -0.05, -0.05, 0),
                                    (rotate_y 90),
                                    (translate -0.05, 0, 0),
                                    (rotate_x Kernel.tick_count),
                                    (rotate_y Kernel.tick_count),
                                    (rotate_z Kernel.tick_count)

    args.state.right = mul_triangles args,
                                     args.state.a,
                                     (translate -0.05, -0.05, 0),
                                     (rotate_y 90),
                                     (translate  0.05, 0, 0),
                                     (rotate_x Kernel.tick_count),
                                     (rotate_y Kernel.tick_count),
                                     (rotate_z Kernel.tick_count)

    args.state.top = mul_triangles args,
                                   args.state.a,
                                   (translate -0.05, -0.05, 0),
                                   (rotate_x 90),
                                   (translate 0, 0.05, 0),
                                   (rotate_x Kernel.tick_count),
                                   (rotate_y Kernel.tick_count),
                                   (rotate_z Kernel.tick_count)

    args.state.bottom = mul_triangles args,
                                      args.state.a,
                                      (translate -0.05, -0.05, 0),
                                      (rotate_x 90),
                                      (translate 0, -0.05, 0),
                                      (rotate_x Kernel.tick_count),
                                      (rotate_y Kernel.tick_count),
                                      (rotate_z Kernel.tick_count)

    render_square args, args.state.back
    render_square args, args.state.front
    render_square args, args.state.left
    render_square args, args.state.right
    render_square args, args.state.top
    render_square args, args.state.bottom
  end

  def render_square args, triangles
    args.outputs.sprites << { x:  triangles[0][0].x * 1280,
                              y:  triangles[0][0].y * 1280,
                              z:  triangles[0][0].z * 1280,
                              x2: triangles[0][1].x * 1280,
                              y2: triangles[0][1].y * 1280,
                              z2: triangles[0][1].z * 1280,
                              x3: triangles[0][2].x * 1280,
                              y3: triangles[0][2].y * 1280,
                              z3: triangles[0][2].z * 1280,
                              a: 255,
                              source_x:   0,
                              source_y:   0,
                              source_x2: 80,
                              source_y2:  0,
                              source_x3:  0,
                              source_y3: 80,
                              path: 'sprites/square/red.png' }

    args.outputs.sprites << { x:  triangles[1][0].x * 1280,
                              y:  triangles[1][0].y * 1280,
                              z:  triangles[1][0].z * 1280,
                              x2: triangles[1][1].x * 1280,
                              y2: triangles[1][1].y * 1280,
                              z2: triangles[1][1].z * 1280,
                              x3: triangles[1][2].x * 1280,
                              y3: triangles[1][2].y * 1280,
                              z3: triangles[1][2].z * 1280,
                              a: 255,
                              source_x:  80,
                              source_y:   0,
                              source_x2: 80,
                              source_y2: 80,
                              source_x3:  0,
                              source_y3: 80,
                              path: 'sprites/square/red.png' }
  end

  def mul_triangles args, triangles, *mul_def
    triangles.map do |vecs|
      vecs.map do |vec|
        mul vec, *mul_def
      end
    end
  end

  def scale scale
    mat4 scale,     0,     0,   0,
             0, scale,     0,   0,
             0,     0, scale,   0,
             0,     0,     0,   1
  end

  def rotate_y angle_d
    cos_t = Math.cos angle_d.to_radians
    sin_t = Math.sin angle_d.to_radians
    mat4  cos_t,  0, sin_t, 0,
          0,      1, 0,     0,
          -sin_t, 0, cos_t, 0,
          0,      0, 0,     1
  end

  def rotate_z angle_d
    cos_t = Math.cos angle_d.to_radians
    sin_t = Math.sin angle_d.to_radians
    mat4 cos_t, -sin_t, 0, 0,
         sin_t,  cos_t, 0, 0,
         0,      0,     1, 0,
         0,      0,     0, 1
  end

  def translate dx, dy, dz
    mat4 1, 0, 0, dx,
         0, 1, 0, dy,
         0, 0, 1, dz,
         0, 0, 0,  1
  end


  def rotate_x angle_d
    cos_t = Math.cos angle_d.to_radians
    sin_t = Math.sin angle_d.to_radians
    mat4  1,     0,      0, 0,
          0, cos_t, -sin_t, 0,
          0, sin_t,  cos_t, 0,
          0,     0,      0, 1
  end

```

### Gimbal Lock - main.rb
```ruby
  # ./samples/14_vr/05_gimbal_lock/app/main.rb
  require 'app/tick.rb'

  def tick args
    DR.start_server! port: 9001, enable_in_prod: true
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

```

### Gimbal Lock - tick.rb
```ruby
  # ./samples/14_vr/05_gimbal_lock/app/tick.rb
  class Game
    attr_dr

    def tick
      grid.origin_center!
      state.angle_x ||= 0
      state.angle_y ||= 0
      state.angle_z ||= 0

      if inputs.left
        state.angle_z += 1
      elsif inputs.right
        state.angle_z -= 1
      end

      if inputs.up
        state.angle_x += 1
      elsif inputs.down
        state.angle_x -= 1
      end

      if inputs.controller_one.a
        state.angle_y += 1
      elsif inputs.controller_one.b
        state.angle_y -= 1
      end

      outputs.sprites << {
        x: 0,
        y: 0,
        w: 100,
        h: 100,
        path: 'sprites/square/blue.png',
        angle_x: state.angle_x,
        angle_y: state.angle_y,
        angle: state.angle_z,
      }
    end
  end

```

### Citadels - main.rb
```ruby
  # ./samples/14_vr/06_citadels/app/main.rb
  require 'app/tick.rb'

  def tick args
    DR.start_server! port: 9001, enable_in_prod: true
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

```

### Citadels - tick.rb
```ruby
  # ./samples/14_vr/06_citadels/app/tick.rb
  class Game
    attr_dr

    def citadel x, y, z
      angle = Kernel.tick_count.idiv(10) % 360
      adjacent = 40
      adjacent = adjacent.ceil
      angle = Math.atan2(40, 70).to_degrees
      y += 500
      x -= 40
      back_sprites = [
        { z: z - 40 + adjacent.half,
          x: x,
          y: y + 75,
          w: 80, h: 80, angle_x: angle, path: "sprites/triangle/equilateral/blue.png" },
        { z: z - 40,
          x: x,
          y: y - 400 + 80,
          w: 80, h: 400, path: "sprites/square/blue.png" },
      ]

      left_sprites = [
        { z: z,
          x: x - 40 + adjacent.half,
          y: y + 75,
          w: 80, h: 80, angle_x: -angle, angle_y: 90, path: "sprites/triangle/equilateral/blue.png" },
        { z: z,                      x: x - 40,
          y: y - 400 + 80,
          w: 80, h: 400, angle_y: 90, path: "sprites/square/blue.png" },
      ]

      right_sprites = [
        { z: z,
          x: x + 40 - adjacent.half,
          y: y + 75,
          w: 80, h: 80, angle_x: angle, angle_y: 90, path: "sprites/triangle/equilateral/blue.png" },
        { z: z,
          x: x + 40,
          y: y - 400 + 80,
          w: 80, h: 400, angle_y: 90, path: "sprites/square/blue.png" },
      ]

      front_sprites = [
        { z: z + 40 - adjacent.half,
          x: x,
          y: y + 75,
          w: 80, h: 80, angle_x: -angle, path: "sprites/triangle/equilateral/blue.png" },
        { z: z + 40,
          x: x,
          y: y - 400 + 80,
          w: 80, h: 400, path: "sprites/square/blue.png" },
      ]

      if x > 700
        [
          back_sprites,
          right_sprites,
          front_sprites,
          left_sprites,
        ]
      elsif x < 600
        [
          back_sprites,
          left_sprites,
          front_sprites,
          right_sprites,
        ]
      else
        [
          back_sprites,
          left_sprites,
          right_sprites,
          front_sprites,
        ]
      end

    end

    def tick
      state.z ||= 200
      state.z += inputs.controller_one.right_analog_y_perc
      state.columns ||= 100.map do
        {
          x: rand(12) * 400,
          y: 0,
          z: rand(12) * 400,
        }
      end

      outputs.sprites << state.columns.map do |col|
        citadel(col.x - 640, col.y - 400, state.z - col.z)
      end
    end
  end

  $game = Game.new

  def tick_game args
    $game.args = args
    $game.tick
  end

  DR.reset

```

### Flappy main.rb
```ruby
  # ./samples/14_vr/07_flappy_vr/app/main.rb
  require 'app/tick.rb'

  def tick args
    DR.start_server! port: 9001, enable_in_prod: true
    tick_game args
  end

```

### Flappy tick.rb
```ruby
  # ./samples/14_vr/07_flappy_vr/app/tick.rb
  class FlappyDragon
    attr_accessor :grid, :inputs, :state, :outputs

    def background_z
      -640
    end

    def flappy_sprite_z
      -120
    end

    def game_text_z
      0
    end

    def menu_overlay_z
      10
    end

    def menu_text_z
      menu_overlay_z + 1
    end

    def flash_z
      1
    end

    def tick
      defaults
      render
      calc
      process_inputs
    end

    def defaults
      state.flap_power              = 11
      state.gravity                 = 0.9
      state.ceiling                 = 600
      state.ceiling_flap_power      = 6
      state.wall_countdown_length   = 100
      state.wall_gap_size           = 100
      state.wall_countdown        ||= 0
      state.hi_score              ||= 0
      state.score                 ||= 0
      state.walls                 ||= []
      state.x_starting_point      ||= 640
      state.x                     ||= state.x_starting_point
      state.y                     ||= 500
      state.z                     ||= -120
      state.dy                    ||= 0
      state.scene                 ||= :menu
      state.scene_at              ||= 0
      state.difficulty            ||= :normal
      state.new_difficulty        ||= :normal
      state.countdown             ||= 4.seconds
      state.flash_at              ||= 0
    end

    def render
      outputs.sounds << "sounds/flappy-song.ogg" if Kernel.tick_count == 1
      render_score
      render_menu
      render_game
    end

    def render_score
      outputs.primitives << { x: 10, y: 710, z: game_text_z, text: "HI SCORE: #{state.hi_score}", **large_white_typeset }
      outputs.primitives << { x: 10, y: 680, z: game_text_z, text: "SCORE: #{state.score}", **large_white_typeset }
      outputs.primitives << { x: 10, y: 650, z: game_text_z, text: "DIFFICULTY: #{state.difficulty.upcase}", **large_white_typeset }
    end

    def render_menu
      return unless state.scene == :menu
      render_overlay

      outputs.labels << { x: 640, y: 700, z: menu_text_z, text: "Flappy Dragon", size_enum: 50, alignment_enum: 1, **white }
      outputs.labels << { x: 640, y: 500, z: menu_text_z, text: "Instructions: Press Spacebar to flap. Don't die.", size_enum: 4, alignment_enum: 1, **white }
      outputs.labels << { x: 430, y: 430, z: menu_text_z, text: "[Tab]    Change difficulty", size_enum: 4, alignment_enum: 0, **white }
      outputs.labels << { x: 430, y: 400, z: menu_text_z, text: "[Enter]  Start at New Difficulty ", size_enum: 4, alignment_enum: 0, **white }
      outputs.labels << { x: 430, y: 370, z: menu_text_z, text: "[Escape] Cancel/Resume ", size_enum: 4, alignment_enum: 0, **white }
      outputs.labels << { x: 640, y: 300, z: menu_text_z, text: "(mouse, touch, and game controllers work, too!) ", size_enum: 4, alignment_enum: 1, **white }
      outputs.labels << { x: 640, y: 200, z: menu_text_z, text: "Difficulty: #{state.new_difficulty.capitalize}", size_enum: 4, alignment_enum: 1, **white }

      outputs.labels << { x: 10, y: 100, z: menu_text_z, text: "Code:   @amirrajan",     **white }
      outputs.labels << { x: 10, y:  80, z: menu_text_z, text: "Art:    @mobypixel",     **white }
      outputs.labels << { x: 10, y:  60, z: menu_text_z, text: "Music:  @mobypixel",     **white }
      outputs.labels << { x: 10, y:  40, z: menu_text_z, text: "Engine: DragonRuby DR", **white }
    end

    def render_overlay
      overlay_rect = grid.rect.scale_rect(1.5, 0, 0)
      outputs.primitives << { x: overlay_rect.x - overlay_rect.w,
                              y: overlay_rect.y - overlay_rect.h,
                              w: overlay_rect.w * 4,
                              h: overlay_rect.h * 2,
                              z: menu_overlay_z,
                              r: 0, g: 0, b: 0, a: 230 }.solid!
    end

    def render_game
      outputs.background_color = [0, 0, 0]
      render_game_over
      render_background
      render_walls
      render_dragon
      render_flash
    end

    def render_game_over
      return unless state.scene == :game
      outputs.labels << { x: 638, y: 358, text: score_text,     z: game_text_z - 1,  size_enum: 20, alignment_enum: 1 }
      outputs.labels << { x: 635, y: 360, text: score_text,     z: game_text_z,  size_enum: 20, alignment_enum: 1, r: 255, g: 255, b: 255 }
      outputs.labels << { x: 638, y: 428, text: countdown_text, z: game_text_z - 1,  size_enum: 20, alignment_enum: 1 }
      outputs.labels << { x: 635, y: 430, text: countdown_text, z: game_text_z,  size_enum: 20, alignment_enum: 1, r: 255, g: 255, b: 255 }
    end

    def render_background
      scroll_point_at   = Kernel.tick_count
      scroll_point_at   = state.scene_at if state.scene == :menu
      scroll_point_at   = state.death_at if state.countdown > 0
      scroll_point_at ||= 0

      outputs.sprites << { x: -640, y: -360, z: background_z, w: 1280 * 2, h: 720 * 2, path: 'sprites/background.png' }
      outputs.sprites << scrolling_background(scroll_point_at, 'sprites/parallax_back.png',   0.25, 1)
      outputs.sprites << scrolling_background(scroll_point_at, 'sprites/parallax_middle.png', 0.50, 50)
      outputs.sprites << scrolling_background(scroll_point_at, 'sprites/parallax_front.png',  1.00, 100, -80)
    end

    def scrolling_background at, path, rate, z, y = 0
      rate *= 2
      w = 1440 * 2
      h =  720 * 2
      [
        { x: w - at.*(rate) % w - w.half.half, y: y * 2 - 360, z: background_z + z, w: w, h: h, path: path },
        { x: 0 - at.*(rate) % w - w.half.half, y: y * 2 - 360, z: background_z + z, w: w, h: h, path: path },
      ]
    end

    def render_walls
      state.walls.each do |w|
        w.top_section = { x: w.x,
                          y: w.bottom_height - 720,
                          z: -120,
                          w: 100,
                          h: 720,
                          path: 'sprites/wall.png',
                          angle: 180 }

        w.bottom_section = { x: w.x,
                             y: w.top_y,
                             z: -120,
                             w: 100,
                             h: 720,
                             path: 'sprites/wallbottom.png',
                             angle: 0}
        w.sprites = [
          model_for(w.top_section),
          model_for(w.bottom_section)
        ]
      end

      outputs.sprites << state.walls.find_all { |w| w.x >= state.x }.reverse.map(&:sprites)
      outputs.sprites << state.walls.find_all { |w| w.x <  state.x }.map(&:sprites)
    end

    def model_for wall
      ratio = (wall.x - state.x_starting_point).abs.fdiv(2560 + state.x_starting_point)
      z_ratio = ratio ** 2
      z_offset = (2560 * 2) * z_ratio
      x_offset = z_offset * 0.25

      if wall.x < state.x
        x_offset *= -1
      end

      distance_from_background_to_flappy = (background_z - flappy_sprite_z).abs
      distance_to_front = z_offset

      if -z_offset < background_z + 100 + wall.w * 2
        a = 0
      else
        percentage_to_front = distance_to_front / distance_from_background_to_flappy
        a = 255 * (1 - percentage_to_front)
      end


      back  = { x:     wall.x + x_offset,
                y:     wall.y,
                z:     wall.z - wall.w.half - z_offset,
                a:     a,
                w:     wall.w,
                h:     wall.h,
                path:  wall.path,
                angle: wall.angle }
      front = { x:     wall.x + x_offset,
                y:     wall.y,
                z:     wall.z + wall.w.half - z_offset,
                a:     a,
                w:     wall.w,
                h:     wall.h,
                path:  wall.path,
                angle: wall.angle }
      left  = { x:     wall.x - wall.w.half + x_offset,
                y:     wall.y,
                z:     wall.z - z_offset,
                a:     a,
                angle_y: 90,
                w:     wall.w,
                h:     wall.h,
                path:  wall.path,
                angle: wall.angle }
      right = { x:     wall.x + wall.w.half + x_offset,
                y:     wall.y,
                z:     wall.z - z_offset,
                a:     a,
                angle_y: 90,
                w:     wall.w,
                h:     wall.h,
                path:  wall.path,
                angle: wall.angle }
      if    (wall.x - wall.w - state.x).abs < 200
        [back, left, right, front]
      elsif wall.x < state.x
        [back, left, front, right]
      else
        [back, right, front, left]
      end
    end

    def render_dragon
      state.show_death = true if state.countdown == 3.seconds

      if state.show_death == false || !state.death_at
        animation_index = state.flapped_at.frame_index 6, 2, false if state.flapped_at
        sprite_name = "sprites/dragon_fly#{(animation_index || 0) + 1}.png"
        state.dragon_sprite = { x: state.x, y: state.y, z: state.z, w: 100, h: 80, path: sprite_name, angle: state.dy * 1.2 }
      else
        sprite_name = "sprites/dragon_die.png"
        state.dragon_sprite = { x: state.x, y: state.y, z: state.z, w: 100, h: 80, path: sprite_name, angle: state.dy * 1.2 }
        sprite_changed_elapsed    = state.death_at.elapsed_time - 1.seconds
        state.dragon_sprite.angle += (sprite_changed_elapsed ** 1.3) * state.death_fall_direction * -1
        state.dragon_sprite.x     += (sprite_changed_elapsed ** 1.2) * state.death_fall_direction
        state.dragon_sprite.y     += (sprite_changed_elapsed * 14 - sprite_changed_elapsed ** 1.6)
        state.z     += 0.3
      end

      outputs.sprites << state.dragon_sprite
    end

    def render_flash
      return unless state.flash_at

      outputs.primitives << { **grid.rect.to_hash,
                              **white,
                              z: flash_z,
                              a: 255 * state.flash_at.ease(20, :flip) }.solid!

      state.flash_at = 0 if state.flash_at.elapsed_time > 20
    end

    def calc
      return unless state.scene == :game
      reset_game if state.countdown == 1
      state.countdown -= 1 and return if state.countdown > 0
      calc_walls
      calc_flap
      calc_game_over
    end

    def calc_walls
      state.walls.each { |w| w.x -= 8 }

      walls_count_before_removal = state.walls.length

      state.walls.reject! { |w| w.x < -2560 + state.x_starting_point }

      state.score += 1 if state.walls.count < walls_count_before_removal

      state.wall_countdown -= 1 and return if state.wall_countdown > 0

      state.walls << state.new_entity(:wall) do |w|
        w.x             = 2560 + state.x_starting_point
        w.opening       = grid.top
                              .randomize(:ratio)
                              .greater(200)
                              .lesser(520)
        w.opening -= w.opening * 0.5
        w.bottom_height = w.opening - state.wall_gap_size
        w.top_y         = w.opening + state.wall_gap_size
      end

      state.wall_countdown = state.wall_countdown_length
    end

    def calc_flap
      state.y += state.dy
      state.dy = state.dy.lesser state.flap_power
      state.dy -= state.gravity
      return if state.y < state.ceiling
      state.y  = state.ceiling
      state.dy = state.dy.lesser state.ceiling_flap_power
    end

    def calc_game_over
      return unless game_over?

      state.death_at = Kernel.tick_count
      state.death_from = state.walls.first
      state.death_fall_direction = -1
      state.death_fall_direction =  1 if state.x > state.death_from.x
      outputs.sounds << "sounds/hit-sound.wav"
      begin_countdown
    end

    def process_inputs
      process_inputs_menu
      process_inputs_game
    end

    def process_inputs_menu
      return unless state.scene == :menu

      changediff = inputs.keyboard.key_down.tab || inputs.controller_one.key_down.select
      if inputs.mouse.click
        p = inputs.mouse.click.point
        if (p.y >= 165) && (p.y < 200) && (p.x >= 500) && (p.x < 800)
          changediff = true
        end
      end

      if changediff
        case state.new_difficulty
        when :easy
          state.new_difficulty = :normal
        when :normal
          state.new_difficulty = :hard
        when :hard
          state.new_difficulty = :flappy
        when :flappy
          state.new_difficulty = :easy
        end
      end

      if inputs.keyboard.key_down.enter || inputs.controller_one.key_down.start || inputs.controller_one.key_down.a
        state.difficulty = state.new_difficulty
        change_to_scene :game
        reset_game false
        state.hi_score = 0
        begin_countdown
      end

      if inputs.keyboard.key_down.escape || (inputs.mouse.click && !changediff) || inputs.controller_one.key_down.b
        state.new_difficulty = state.difficulty
        change_to_scene :game
      end
    end

    def process_inputs_game
      return unless state.scene == :game

      clicked_menu = false
      if inputs.mouse.click
        p = inputs.mouse.click.point
        clicked_menu = (p.y >= 620) && (p.x < 275)
      end

      if clicked_menu || inputs.keyboard.key_down.escape || inputs.keyboard.key_down.enter || inputs.controller_one.key_down.start
        change_to_scene :menu
      elsif (inputs.mouse.down || inputs.mouse.click || inputs.keyboard.key_down.space || inputs.controller_one.key_down.a) && state.countdown == 0
        state.dy = 0
        state.dy += state.flap_power
        state.flapped_at = Kernel.tick_count
        outputs.sounds << "sounds/fly-sound.wav"
      end
    end

    def white
      { r: 255, g: 255, b: 255 }
    end

    def large_white_typeset
      { size_enum: 5, alignment_enum: 0, r: 255, g: 255, b: 255 }
    end

    def at_beginning?
      state.walls.count == 0
    end

    def dragon_collision_box
      { x: state.dragon_sprite.x,
        y: state.dragon_sprite.y,
        w: state.dragon_sprite.w,
        h: state.dragon_sprite.h }
           .scale_rect(1.0 - collision_forgiveness, 0.5, 0.5)
           .rect_shift_right(10)
           .rect_shift_up(state.dy * 2)
    end

    def game_over?
      return true if state.y <= 0.-(500 * collision_forgiveness) && !at_beginning?

      state.walls
           .find_all { |w| w.top_section && w.bottom_section }
           .flat_map { |w| [w.top_section, w.bottom_section] }
           .any?     { |s| s.intersect_rect?(dragon_collision_box) }
    end

    def collision_forgiveness
      case state.difficulty
      when :easy
        0.9
      when :normal
        0.7
      when :hard
        0.5
      when :flappy
        0.3
      else
        0.9
      end
    end

    def countdown_text
      state.countdown ||= -1
      return ""          if state.countdown == 0
      return "GO!"       if state.countdown.idiv(60) == 0
      return "GAME OVER" if state.death_at
      return "READY?"
    end

    def begin_countdown
      state.countdown = 4.seconds
    end

    def score_text
      return ""                        unless state.countdown > 1.seconds
      return ""                        unless state.death_at
      return "SCORE: 0 (LOL)"          if state.score == 0
      return "HI SCORE: #{state.score}" if state.score == state.hi_score
      return "SCORE: #{state.score}"
    end

    def reset_game set_flash = true
      state.flash_at = Kernel.tick_count if set_flash
      state.walls = []
      state.y = 500
      state.x =  state.x_starting_point
      state.z = flappy_sprite_z
      state.dy = 0
      state.hi_score = state.hi_score.greater(state.score)
      state.score = 0
      state.wall_countdown = state.wall_countdown_length.fdiv(2)
      state.show_death = false
      state.death_at = nil
    end

    def change_to_scene scene
      state.scene = scene
      state.scene_at = Kernel.tick_count
      inputs.keyboard.clear
      inputs.controller_one.clear
    end
  end

  $flappy_dragon = FlappyDragon.new

  def tick_game args
    $flappy_dragon.grid = args.grid
    $flappy_dragon.inputs = args.inputs
    $flappy_dragon.state = args.state
    $flappy_dragon.outputs = args.outputs
    $flappy_dragon.tick
  end

  DR.reset

```

### Cubeworld main.rb
```ruby
  # ./samples/14_vr/08_cubeworld_vr/app/main.rb
  require 'app/tick.rb'

  def tick args
    DR.start_server! port: 9001, enable_in_prod: true
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

```

### Cubeworld tick.rb
```ruby
  # ./samples/14_vr/08_cubeworld_vr/app/tick.rb
  class Game
    include MatrixFunctions

    attr_dr

    def cube x:, y:, z:, angle_x:, angle_y:, angle_z:;
      combined = mul (rotate_x angle_x),
                     (rotate_y angle_y),
                     (rotate_z angle_z),
                     (translate x, y, z)

      face_1 = mul_triangles state.baseline_cube.face_1, combined
      face_2 = mul_triangles state.baseline_cube.face_2, combined
      face_3 = mul_triangles state.baseline_cube.face_3, combined
      face_4 = mul_triangles state.baseline_cube.face_4, combined
      face_5 = mul_triangles state.baseline_cube.face_5, combined
      face_6 = mul_triangles state.baseline_cube.face_6, combined

      [
        face_1,
        face_2,
        face_3,
        face_4,
        face_5,
        face_6
      ]
    end

    def random_point
      r = { xr: 2.randomize(:ratio) - 1,
            yr: 2.randomize(:ratio) - 1,
            zr: 2.randomize(:ratio) - 1 }
      if (r.xr ** 2 + r.yr ** 2 + r.zr ** 2) > 1.0
        return random_point
      else
        return r
      end
    end

    def random_cube_attributes
      state.cube_count.map_with_index do |i|
        point_on_sphere = random_point
        radius = rand * 10 + 3
        {
          x: point_on_sphere.xr * radius,
          y: point_on_sphere.yr * radius,
          z: 6.4 + point_on_sphere.zr * radius
        }
      end
    end

    def defaults
      state.cube_count ||= 1
      state.cube_attributes ||= random_cube_attributes
      if !state.baseline_cube
        state.baseline_cube = {
          face_1: [
            [vec4(0, 0, 0, 1),   vec4(0.5, 0, 0, 1),   vec4(0, 0.5, 0, 1)],
            [vec4(0.5, 0, 0, 1), vec4(0.5, 0.5, 0, 1), vec4(0, 0.5, 0, 1)]
          ],
          face_2: [
            [vec4(0, 0, 0, 1),   vec4(0.5, 0, 0, 1),   vec4(0, 0.5, 0, 1)],
            [vec4(0.5, 0, 0, 1), vec4(0.5, 0.5, 0, 1), vec4(0, 0.5, 0, 1)]
          ],
          face_3: [
            [vec4(0, 0, 0, 1),   vec4(0.5, 0, 0, 1),   vec4(0, 0.5, 0, 1)],
            [vec4(0.5, 0, 0, 1), vec4(0.5, 0.5, 0, 1), vec4(0, 0.5, 0, 1)]
          ],
          face_4: [
            [vec4(0, 0, 0, 1),   vec4(0.5, 0, 0, 1),   vec4(0, 0.5, 0, 1)],
            [vec4(0.5, 0, 0, 1), vec4(0.5, 0.5, 0, 1), vec4(0, 0.5, 0, 1)]
          ],
          face_5: [
            [vec4(0, 0, 0, 1),   vec4(0.5, 0, 0, 1),   vec4(0, 0.5, 0, 1)],
            [vec4(0.5, 0, 0, 1), vec4(0.5, 0.5, 0, 1), vec4(0, 0.5, 0, 1)]
          ],
          face_6: [
            [vec4(0, 0, 0, 1),   vec4(0.5, 0, 0, 1),   vec4(0, 0.5, 0, 1)],
            [vec4(0.5, 0, 0, 1), vec4(0.5, 0.5, 0, 1), vec4(0, 0.5, 0, 1)]
          ]
        }

        state.baseline_cube.face_1 = mul_triangles state.baseline_cube.face_1,
                                                   (translate -0.25, -0.25, 0),
                                                   (translate  0, 0, 0.25)

        state.baseline_cube.face_2 = mul_triangles state.baseline_cube.face_2,
                                                   (translate -0.25, -0.25, 0),
                                                   (translate  0, 0, -0.25)

        state.baseline_cube.face_3 = mul_triangles state.baseline_cube.face_3,
                                                   (translate -0.25, -0.25, 0),
                                                   (rotate_y 90),
                                                   (translate -0.25,  0, 0)

        state.baseline_cube.face_4 = mul_triangles state.baseline_cube.face_4,
                                                   (translate -0.25, -0.25, 0),
                                                   (rotate_y 90),
                                                   (translate  0.25,  0, 0)

        state.baseline_cube.face_5 = mul_triangles state.baseline_cube.face_5,
                                                   (translate -0.25, -0.25, 0),
                                                   (rotate_x 90),
                                                   (translate  0,  0.25, 0)

        state.baseline_cube.face_6 = mul_triangles state.baseline_cube.face_6,
                                                   (translate -0.25, -0.25, 0),
                                                   (rotate_x 90),
                                                   (translate  0,  -0.25, 0)
      end
    end

    def tick
      args.grid.origin_center!
      defaults

      if inputs.controller_one.key_down.a
        state.cube_count += 1
        state.cube_attributes = random_cube_attributes
      elsif inputs.controller_one.key_down.b
        state.cube_count -= 1 if state.cube_count > 1
        state.cube_attributes = random_cube_attributes
      end

      state.cube_attributes.each do |c|
        render_cube (cube x: c.x, y: c.y, z: c.z,
                          angle_x: Kernel.tick_count,
                          angle_y: Kernel.tick_count,
                          angle_z: Kernel.tick_count)
      end

      args.outputs.background_color = [255, 255, 255]
      framerate_primitives = DR.current_framerate_primitives
      framerate_primitives.find { |p| p.text }.each { |p| p.z = 1 }
      framerate_primitives[-1].text = "cube count: #{state.cube_count} (#{state.cube_count * 12} triangles)"
      args.outputs.primitives << framerate_primitives
    end

    def translate dx, dy, dz
      mat4 1, 0, 0, dx,
           0, 1, 0, dy,
           0, 0, 1, dz,
           0, 0, 0,  1
    end

    def rotate_x angle_d
      cos_t = Math.cos angle_d.to_radians
      sin_t = Math.sin angle_d.to_radians
      mat4  1,     0,      0, 0,
            0, cos_t, -sin_t, 0,
            0, sin_t,  cos_t, 0,
            0,     0,      0, 1
    end

    def rotate_y angle_d
      cos_t = Math.cos angle_d.to_radians
      sin_t = Math.sin angle_d.to_radians
      mat4  cos_t,  0, sin_t, 0,
            0,      1, 0,     0,
            -sin_t, 0, cos_t, 0,
            0,      0, 0,     1
    end

    def rotate_z angle_d
      cos_t = Math.cos angle_d.to_radians
      sin_t = Math.sin angle_d.to_radians
      mat4 cos_t, -sin_t, 0, 0,
           sin_t,  cos_t, 0, 0,
           0,      0,     1, 0,
           0,      0,     0, 1
    end

    def mul_triangles model, *mul_def
      model.map do |vecs|
        vecs.map do |vec|
          vec = mul vec, *mul_def
        end
      end
    end

    def render_cube cube
      render_face cube[0]
      render_face cube[1]
      render_face cube[2]
      render_face cube[3]
      render_face cube[4]
      render_face cube[5]
    end

    def render_face face
      triangle_1 = face[0]
      args.outputs.sprites << {
        x:  triangle_1[0].x * 100,   y: triangle_1[0].y * 100,  z: triangle_1[0].z * 100,
        x2: triangle_1[1].x * 100,  y2: triangle_1[1].y * 100, z2: triangle_1[1].z * 100,
        x3: triangle_1[2].x * 100,  y3: triangle_1[2].y * 100, z3: triangle_1[2].z * 100,
        source_x:   0, source_y:   0,
        source_x2: 80, source_y2:  0,
        source_x3:  0, source_y3: 80,
        path: 'sprites/square/blue.png'
      }

      triangle_2 = face[1]
      args.outputs.sprites << {
        x:  triangle_2[0].x * 100,   y: triangle_2[0].y * 100,  z: triangle_2[0].z * 100,
        x2: triangle_2[1].x * 100,  y2: triangle_2[1].y * 100, z2: triangle_2[1].z * 100,
        x3: triangle_2[2].x * 100,  y3: triangle_2[2].y * 100, z3: triangle_2[2].z * 100,
        source_x:  80, source_y:   0,
        source_x2: 80, source_y2: 80,
        source_x3:  0, source_y3: 80,
        path: 'sprites/square/blue.png'
      }
    end
  end

```
