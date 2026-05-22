### Sprites As Hash - main.rb
```ruby
  # ./samples/09_performance/01_sprites_as_hash/app/main.rb
  # Sprites represented as Hashes using the queue ~args.outputs.sprites~
  # code up, but are the "slowest" to render.
  # The reason for this is the access of the key in the Hash and also
  # because the data args.outputs.sprites is cleared every tick.
  def random_x
    rand * Grid.w * -1
  end

  def random_y
    rand * Grid.h * -1
  end

  def random_speed
    1 + 4 * rand
  end

  def new_star args
    {
      x: random_x,
      y: random_y,
      w: 4, h: 4, path: 'sprites/tiny-star.png',
      s: random_speed
    }
  end

  def move_star star
    star.x += star.s
    star.y += star.s
    if star.x > Grid.w || star.y > Grid.h
      star.x = random_x
      star.y = random_y
      star.s = random_speed
    end
  end

  def boot args
    args.state = {}
  end

  def tick args
    args.state.star_count ||= 0

    # sets console command when sample app initially opens
    if Kernel.global_tick_count == 0
      puts ""
      puts ""
      puts "========================================================="
      puts "* INFO: Sprites, Hashes"
      puts "* INFO: Please specify the number of sprites to render."
      DR.console.set_command "reset_with count: 100"
    end

    if args.inputs.keyboard.key_down.space
      reset_with count: 5000
    end

    # init
    if Kernel.tick_count == 0
      args.state.stars = args.state.star_count.map { |i| new_star args }
    end

    # update
    args.state.stars.each { |s| move_star s }

    # render
    args.outputs.sprites << args.state.stars
    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << DR.current_framerate_primitives
  end

  # resets game, and assigns star count given by user
  def reset_with count: count
    DR.reset
    DR.args.state.star_count = count
    DR.args.state.stars = DR.args.state.star_count.map { |i| new_star DR.args }
  end

```

### Sprites As Classes - main.rb
```ruby
  # ./samples/09_performance/05_sprites_as_classes/app/main.rb
  # Sprites represented as Classes using the queue ~args.outputs.sprites~.
  # gives you full control of property declaration and method invocation.
  # They are more performant than OpenEntities and StrictEntities, but more code upfront.
  class Star
    attr_sprite

    def initialize grid
      @grid = grid
      @x = (rand @grid.w) * -1
      @y = (rand @grid.h) * -1
      @w    = 4
      @h    = 4
      @s    = 1 + (4.randomize :ratio)
      @path = 'sprites/tiny-star.png'
    end

    def move
      @x += @s
      @y += @s
      @x = (rand @grid.w) * -1 if @x > @grid.right
      @y = (rand @grid.h) * -1 if @y > @grid.top
    end
  end

  # calls methods needed for game to run properly
  def tick args
    # sets console command when sample app initially opens
    if Kernel.global_tick_count == 0
      puts ""
      puts ""
      puts "========================================================="
      puts "* INFO: Sprites, Classes"
      puts "* INFO: Please specify the number of sprites to render."
      DR.console.set_command "reset_with count: 100"
    end

    args.state.star_count ||= 0

    # init
    if Kernel.tick_count == 0
      args.state.stars = args.state.star_count.map { |i| Star.new args.grid }
    end

    if args.inputs.keyboard.key_down.space
      reset_with count: 5000
    end

    # update
    args.state.stars.each(&:move)

    # render
    args.outputs.sprites << args.state.stars
    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << DR.current_framerate_primitives
  end

  # resets game, and assigns star count given by user
  def reset_with count: count
    DR.reset
    DR.args.state.star_count = count
  end

```

### Static Sprites As Classes - main.rb
```ruby
  # ./samples/09_performance/06_static_sprites_as_classes/app/main.rb
  # Sprites represented as Classes using the queue ~args.outputs.static_sprites~.
  # bypasses the queue behavior of ~args.outputs.sprites~. All instances are held
  # by reference. You get better performance, but you are mutating state of held objects
  # which is less functional/data oriented.
  class Star
    attr_sprite

    def initialize grid
      @grid = grid
      @x = (rand @grid.w) * -1
      @y = (rand @grid.h) * -1
      @w    = 4
      @h    = 4
      @s    = 1 + (4.randomize :ratio)
      @path = 'sprites/tiny-star.png'
    end

    def move
      @x += @s
      @y += @s
      @x = (rand @grid.w) * -1 if @x > @grid.right
      @y = (rand @grid.h) * -1 if @y > @grid.top
    end
  end

  # calls methods needed for game to run properly
  def tick args
    # sets console command when sample app initially opens
    if Kernel.global_tick_count == 0
      puts ""
      puts ""
      puts "========================================================="
      puts "* INFO: Static Sprites, Classes"
      puts "* INFO: Please specify the number of sprites to render."
      DR.console.set_command "reset_with count: 100"
    end

    if args.inputs.keyboard.key_down.space
      reset_with count: 5000
    end

    args.state.star_count ||= 0

    # init
    if Kernel.tick_count == 0
      args.state.stars = args.state.star_count.map { |i| Star.new args.grid }
      args.outputs.static_sprites << args.state.stars
    end

    # update
    args.state.stars.each(&:move)

    # render
    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << DR.current_framerate_primitives
  end

  # resets game, and assigns star count given by user
  def reset_with count: count
    DR.reset
    DR.args.state.star_count = count
  end

```

### Static Sprites As Classes With Custom Drawing - main.rb
```ruby
  # ./samples/09_performance/07_static_sprites_as_classes_with_custom_drawing/app/main.rb
  # Sprites represented as Classes, with a draw_override method, and using the queue ~args.outputs.static_sprites~.
  # is the fastest approach. This is comparable to what other game engines set as the default behavior.
  # There are tradeoffs for all this speed if the creation of a full blown class, and bypassing
  # functional/data-oriented practices.
  class Star
    def initialize
      @grid_w = Grid.w
      @grid_h = Grid.h
      @x = Numeric.rand(@grid_w) * -1
      @y = Numeric.rand(@grid_h) * -1
      @w = 4
      @h = 4
      @path = "sprites/tiny-star.png"
      @s = 1 + Numeric.rand(4.0) + Numeric.rand(1.0) ** 2
    end

    def tick
      @x += @s
      @y += @s
      @x = Numeric.rand(@grid_w) * -1 if @x > @grid_w
      @y = Numeric.rand(@grid_h) * -1 if @y > @grid_h
    end

    # if the object that is in args.outputs.sprites (or static_sprites)
    # respond_to? :draw_override, then the method is invoked giving you
    # access to the class used to draw to the canvas.
    def draw_override ffi_draw
      # general recommendation is to use ffi_draw.draw_sprite_ivar
      # the following ivars will be probed for values
      # @x, @y, @w, @h, @path, @angle, @a,
      # @r, @g, @b,
      # @flip_horizontally, @flip_vertically,
      # @anchor_x, @anchor_y,
      # @tile_x, @tile_y, @tile_w, @tile_h,
      # @angle_anchor_x,
      # @angle_anchor_y,
      # @angle_x, @angle_y,
      # @source_x, @source_y, @source_w, @source_h,
      # @blendmode_enum,
      # @source_x2, @source_y2, @source_x3, @source_y3,
      # @x2, @y2, @x3, @y3,
      # @r2, @g2, @b2, @a2,
      # @r3, @g3, @b3, @a3,
      # @scale_quality_enum, @blendmode
      ffi_draw.draw_sprite_ivar self

      # The argument order for ffi.draw_sprite is:
      # x, y, w, h, path
      # ffi_draw.draw_sprite @x, @y, @w, @h, @path

      # The argument order for ffi_draw.draw_sprite_2 is (pass in nil for default value):
      # x, y, w, h, path,
      # angle, alpha

      # The argument order for ffi_draw.draw_sprite_3 is:
      # x, y, w, h,
      # path,
      # angle,
      # alpha, red_saturation, green_saturation, blue_saturation
      # tile_x, tile_y, tile_w, tile_h,
      # flip_horizontally, flip_vertically,
      # angle_anchor_x, angle_anchor_y,
      # source_x, source_y, source_w, source_h

      # The argument order for ffi_draw.draw_sprite_4 is:
      # x, y, w, h,
      # path,
      # angle,
      # alpha, red_saturation, green_saturation, blue_saturation
      # tile_x, tile_y, tile_w, tile_h,
      # flip_horizontally, flip_vertically,
      # angle_anchor_x, angle_anchor_y,
      # source_x, source_y, source_w, source_h,
      # blendmode_enum

      # The argument order for ffi_draw.draw_sprite_5 is:
      # x, y, w, h,
      # path,
      # angle,
      # alpha, red_saturation, green_saturation, blue_saturation
      # tile_x, tile_y, tile_w, tile_h,
      # flip_horizontally, flip_vertically,
      # angle_anchor_x, angle_anchor_y,
      # source_x, source_y, source_w, source_h,
      # blendmode_enum
      # anchor_x
      # anchor_y

      # The argument order for ffi_draw.draw_sprite_6 is:
      # x, y, w, h,
      # path,
      # angle,
      # alpha, red_saturation, green_saturation, blue_saturation
      # tile_x, tile_y, tile_w, tile_h,
      # flip_horizontally, flip_vertically,
      # angle_anchor_x, angle_anchor_y,
      # source_x, source_y, source_w, source_h,
      # blendmode_enum
      # anchor_x
      # anchor_y
      # scale_quality_enum
    end
  end

  class Game
    attr_dr

    def tick
      if Kernel.global_tick_count == 0
        puts ""
        puts ""
        puts "========================================================="
        puts "* INFO: Static Sprites, Classes, Draw Override"
        puts "* INFO: Please specify the number of sprites to render."
        DR.console.set_command "$game.reset_with count: 100"
      end

      if inputs.keyboard.key_down.space
        reset_with count: 40000
      end

      state.star_count ||= 0

      # init
      if Kernel.tick_count == 0
        @stars = state.star_count.map { |i| Star.new }
        outputs.static_sprites << @stars
      end

      Array.each(@stars, &:tick)

      # render framerate
      outputs.background_color = [0, 0, 0]
      outputs.primitives << DR.current_framerate_primitives
    end

    # resets game, and assigns star count given by user
    def reset_with count: count
      DR.reset
      DR.args.state.star_count = count
    end
  end

  def self.boot args
    args.state = {}
  end

  def self.tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def self.reset args
    $game = nil
  end

  DR.reset

```

### Collision Limits - main.rb
```ruby
  # ./samples/09_performance/08_collision_limits/app/main.rb
  =begin

   Reminders:
   - find_all: Finds all elements of a collection that meet certain requirements.
     In this sample app, we're finding all bodies that intersect with the center body.

   - args.outputs.solids: An array. The values generate a solid.
     The parameters are [X, Y, WIDTH, HEIGHT, RED, GREEN, BLUE]
     For more information about solids, go to mygame/documentation/03-solids-and-borders.md.

   - args.outputs.labels: An array. The values generate a label.
     The parameters are [X, Y, TEXT, SIZE, ALIGNMENT, RED, GREEN, BLUE, ALPHA, FONT STYLE]
     For more information about labels, go to mygame/documentation/02-labels.md.

   - ARRAY#intersect_rect?: Returns true or false depending on if two rectangles intersect.

  =end

  # This code demonstrates moving objects that loop around once they exceed the scope of the screen,
  # which has dimensions of 1280 by 720, and also detects collisions between objects called "bodies".

  def body_count num
    DR.args.state.other_bodies = num.map { [1280 * rand, 720 * rand, 10, 10] } # other_bodies set using num collection
  end

  def tick args

    # Center body's values are set using an array
    # Map is used to set values of 5000 other bodies
    # All bodies that intersect with center body are stored in collisions collection
    args.state.center_body  ||= { x: 640 - 100, y: 360 - 100, w: 200, h: 200 } # calculations done to place body in center
    args.state.other_bodies ||= 5000.map do
      { x: 1280 * rand,
        y: 720 * rand,
        w: 2,
        h: 2,
        path: :pixel,
        r: 0,
        g: 0,
        b: 0 }
    end # 2000 bodies given random position on screen

    # finds all bodies that intersect with center body, stores them in collisions
    collisions = args.state.other_bodies.find_all { |b| b.intersect_rect? args.state.center_body }

    args.borders << args.state.center_body # outputs center body as a black border

    # transparency changes based on number of collisions; the more collisions, the redder (more transparent) the box becomes
    args.sprites  << { x: args.state.center_body.x,
                       y: args.state.center_body.y,
                       w: args.state.center_body.w,
                       h: args.state.center_body.h,
                       path: :pixel,
                       a: collisions.length.idiv(2), # alpha value represents the number of collisions that occurred
                       r: 255,
                       g: 0,
                       b: 0 } # center body is red solid
    args.sprites  << args.state.other_bodies # other bodies are output as (black) solids, as well

    args.labels  << [10, 30, DR.current_framerate.to_sf] # outputs frame rate in bottom left corner

    # Bodies are returned to bottom left corner if positions exceed scope of screen
    args.state.other_bodies.each do |b| # for each body in the other_bodies collection
      b.x += 5 # x and y are both incremented by 5
      b.y += 5
      b.x = 0 if b.x > 1280 # x becomes 0 if star exceeds scope of screen (goes too far right)
      b.y = 0 if b.y > 720 # y becomes 0 if star exceeds scope of screen (goes too far up)
    end
  end

  # Resets the game.
  DR.reset

```

### Collision Limits Aabb - main.rb
```ruby
  # ./samples/09_performance/09_collision_limits_aabb/app/main.rb
  def tick args
    args.state.id_seed    ||= 1
    args.state.boxes      ||= []
    args.state.terrain    ||= [
      {
        x: 40, y: 0, w: 1200, h: 40, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 1240, y: 0, w: 40, h: 720, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 0, y: 0, w: 40, h: 720, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 40, y: 680, w: 1200, h: 40, path: :pixel, r: 0, g: 0, b: 0
      },

      {
        x: 760, y: 420, w: 180, h: 40, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 720, y: 420, w: 40, h: 100, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 940, y: 420, w: 40, h: 100, path: :pixel, r: 0, g: 0, b: 0
      },

      {
        x: 660, y: 220, w: 280, h: 40, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 620, y: 220, w: 40, h: 100, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 940, y: 220, w: 40, h: 100, path: :pixel, r: 0, g: 0, b: 0
      },

      {
        x: 460, y: 40, w: 280, h: 40, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 420, y: 40, w: 40, h: 100, path: :pixel, r: 0, g: 0, b: 0
      },
      {
        x: 740, y: 40, w: 40, h: 100, path: :pixel, r: 0, g: 0, b: 0
      },
    ]

    if args.inputs.keyboard.space
      args.state.boxes << {
        id: args.state.id_seed,
        x: 60,
        y: 60,
        w: 10,
        h: 10,
        dy: Numeric.rand(10..30),
        dx: Numeric.rand(10..30),
        path: :solid,
        r: Numeric.rand(200),
        g: Numeric.rand(200),
        b: Numeric.rand(200)
      }

      args.state.id_seed += 1
    end

    if args.inputs.keyboard.backspace
      args.state.boxes.pop_back
    end

    terrain = args.state.terrain

    args.state.boxes.each do |b|
      if b.still
        b.dy = Numeric.rand(20)
        b.dx = Numeric.rand(-20..20)
        b.still = false
        b.on_floor = false
      end

      if b.on_floor
        b.dx *= 0.9
      end

      b.x += b.dx

      collision_x = Geometry.find_intersect_rect(b, terrain)

      if collision_x
        if b.dx > 0
          b.x = collision_x.x - b.w
        elsif b.dx < 0
          b.x = collision_x.x + collision_x.w
        end
        b.dx *= -0.8
      end

      b.dy -= 0.25
      b.y += b.dy

      collision_y = Geometry.find_intersect_rect(b, terrain)

      if collision_y
        if b.dy > 0
          b.y = collision_y.y - b.h
        elsif b.dy < 0
          b.y = collision_y.y + collision_y.h
        end

        if b.dy < 0 && b.dy.abs < 1
          b.on_floor = true
        end

        b.dy *= -0.8
      end

      if b.on_floor && (b.dy.abs + b.dx.abs) < 0.1
        b.still = true
      end
    end

    args.outputs.labels << { x: 60, y: 60.from_top, text: "Hold SPACEBAR to add boxes. Hold BACKSPACE to remove boxes." }
    args.outputs.labels << { x: 60, y: 90.from_top, text: "FPS: #{DR.current_framerate.to_sf}" }
    args.outputs.labels << { x: 60, y: 120.from_top, text: "Count: #{args.state.boxes.length}" }
    args.outputs.borders << args.state.terrain
    args.outputs.sprites << args.state.boxes
  end

  # DR.reset

```

### Collision Limits Find Single - main.rb
```ruby
  # ./samples/09_performance/09_collision_limits_find_single/app/main.rb
  def tick args
    if args.state.should_reset_framerate_calculation
      DR.reset_framerate_calculation
      args.state.should_reset_framerate_calculation = nil
    end

    if !args.state.rects
      args.state.rects = []
      add_10_000_random_rects args
    end

    args.state.player_rect ||= { x: 640 - 20, y: 360 - 20, w: 40, h: 40 }
    args.state.collision_type ||= :using_lambda

    if Kernel.tick_count == 0
      generate_scene args, args.state.quad_tree
    end

    # inputs
    # have a rectangle that can be moved around using arrow keys
    args.state.player_rect.x += args.inputs.left_right * 4
    args.state.player_rect.y += args.inputs.up_down * 4

    if args.inputs.mouse.click
      add_10_000_random_rects args
      args.state.should_reset_framerate_calculation = true
    end

    if args.inputs.keyboard.key_down.tab
      if args.state.collision_type == :using_lambda
        args.state.collision_type = :using_while_loop
      elsif args.state.collision_type == :using_while_loop
        args.state.collision_type = :using_find_intersect_rect
      elsif args.state.collision_type == :using_find_intersect_rect
        args.state.collision_type = :using_lambda
      end
      args.state.should_reset_framerate_calculation = true
    end

    # calc
    if args.state.collision_type == :using_lambda
      args.state.current_collision = args.state.rects.find { |r| r.intersect_rect? args.state.player_rect }
    elsif args.state.collision_type == :using_while_loop
      args.state.current_collision = nil
      idx = 0
      l = args.state.rects.length
      rects = args.state.rects
      player = args.state.player_rect
      while idx < l
        if rects[idx].intersect_rect? player
          args.state.current_collision = rects[idx]
          break
        end
        idx += 1
      end
    else
      args.state.current_collision = Geometry.find_intersect_rect args.state.player_rect, args.state.rects
    end

    # render
    render_instructions args
    args.outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: :scene }

    if args.state.current_collision
      args.outputs.sprites << args.state.current_collision.merge(path: :pixel, r: 255, g: 0, b: 0)
    end

    args.outputs.sprites << args.state.player_rect.merge(path: :pixel, a: 80, r: 0, g: 255, b: 0)
    args.outputs.labels  << {
      x: args.state.player_rect.x + args.state.player_rect.w / 2,
      y: args.state.player_rect.y + args.state.player_rect.h / 2,
      text: "player",
      alignment_enum: 1,
      vertical_alignment_enum: 1,
      size_enum: -4
    }

  end

  def add_10_000_random_rects args
    add_rects args, 10_000.map { { x: rand(1080) + 100, y: rand(520) + 100 } }
  end

  def add_rects args, points
    args.state.rects.concat(points.map { |point| { x: point.x, y: point.y, w: 5, h: 5 } })
    # args.state.quad_tree = Geometry.quad_tree_create args.state.rects
    generate_scene args, args.state.quad_tree
  end

  def add_rect args, x, y
    args.state.rects << { x: x, y: y, w: 5, h: 5 }
    # args.state.quad_tree = Geometry.quad_tree_create args.state.rects
    generate_scene args, args.state.quad_tree
  end

  def generate_scene args, quad_tree
    args.outputs[:scene].w = 1280
    args.outputs[:scene].h = 720
    args.outputs[:scene].solids << { x: 0, y: 0, w: 1280, h: 720, r: 255, g: 255, b: 255 }
    args.outputs[:scene].sprites << args.state.rects.map { |r| r.merge(path: :pixel, r: 0, g: 0, b: 255) }
  end

  def render_instructions args
    args.outputs.primitives << { x:  0, y: 90.from_top, w: 1280, h: 100, r: 0, g: 0, b: 0, a: 200 }.solid!
    args.outputs.labels << { x: 10, y: 10.from_top, r: 255, g: 255, b: 255, size_enum: -2, text: "Click to add 10,000 random rects. Tab to change collision algorithm." }
    args.outputs.labels << { x: 10, y: 40.from_top, r: 255, g: 255, b: 255, size_enum: -2, text: "Algorithm: #{args.state.collision_type}" }
    args.outputs.labels << { x: 10, y: 55.from_top, r: 255, g: 255, b: 255, size_enum: -2, text: "Rect Count: #{args.state.rects.length}" }
    args.outputs.labels << { x: 10, y: 70.from_top, r: 255, g: 255, b: 255, size_enum: -2, text: "FPS: #{DR.current_framerate.to_sf}" }
  end

```

### Collision Limits Many To Many - main.rb
```ruby
  # ./samples/09_performance/09_collision_limits_many_to_many/app/main.rb
  class Square
    attr_sprite

    def initialize x, y
      @x    = x
      @y    = y
      @w    = 8
      @h    = 8
      @path = 'sprites/square/blue.png'
      @dir = if x < 640
               -1.0
             else
               1.0
             end
    end

    def reset_collision
      @path = "sprites/square/blue.png"
    end

    def mark_collision
      @path = 'sprites/square/red.png'
    end

    def move
      @dir  = -1.0 if (@x + @w >= 1280) && @dir ==  1.0
      @dir  =  1.0 if (@x      <=    0) && @dir == -1.0
      @x   += @dir
    end
  end

  def generate_random_squares args, center_x, center_y
    100.times do
      angle = rand 360
      distance = rand(200) + 20
      x = center_x + angle.vector_x * distance
      y = center_y + angle.vector_y * distance
      if x > 0 && x < 1280 && y < 720 && y > 0
        args.state.squares << Square.new(x, y)
      end
    end

    args.outputs.static_sprites.clear
    args.outputs.static_sprites << args.state.squares
    args.state.square_count = args.state.squares.length
  end

  def tick args
    args.state.squares ||= []

    if Kernel.tick_count == 0
      generate_random_squares args, 640, 360
    end

    if args.inputs.mouse.click
      generate_random_squares args, args.inputs.mouse.x, args.inputs.mouse.y
    end

    Array.each(args.state.squares) do |s|
      s.reset_collision
      s.move
    end

    Geometry.each_intersect_rect(args.state.squares, args.state.squares) do |a, b|
      a.mark_collision
      b.mark_collision
    end

    args.outputs.background_color = [0, 0, 0]
    args.outputs.watch "FPS: #{DR.current_framerate.to_sf}"
    args.outputs.watch "Square Count: #{args.state.square_count.to_i}"
    args.outputs.watch "Instructions: click to add squares."
  end

```
