### Simple - main.rb
```ruby
  # ./samples/04_physics_and_collisions/01_simple/app/main.rb
  #  Reminders:
  #  - Geometry.intersect_rect?:
  #    Returns true or false depending on if the two rectangles intersect.
  #
  #  - args.outputs.sprites: give this collection a hash to render a sprite.
  #    Setting the sprite path to :solid will render a solid square
  #    The parameters are { x: X, y: Y, w: WIDTH, h: HEIGHT, sprite: PATH, r: RED, g: GREEN, b: BLUE }

  # This sample app shows collisions between two boxes. and screen edges.

  # entry point of the game
  def tick args
    defaults args
    calc args
    render args
  end

  # Sets default values.
  def defaults args
    # moving_box_size is set as the width and height
    args.state.moving_box ||= {
      x: 0,
      y: 0,
      w: 100,
      h: 100,
      path: :solid,
      r: 0,
      g: 0,
      b: 0,
      dx: 1,     # represents the current x movement direction
      dy: 1,     # represents the current y movement direction
      speed: 10  # speed of movement
    }

    # These values represent the center box.
    args.state.center_box ||= {
      x: 540,
      y: 260,
      w: 200,
      h: 200,
      path: :solid,
      r: 180,
      g: 0,
      b: 0
    }

    args.state.center_box_collision ||= false # initially no collision
  end

  def render args
    # If the game state denotes that a collision has occurred,
    # render a solid square, otherwise render a border instead.
    if args.state.center_box_collision
      args.outputs.sprites << args.state.center_box
    else
      args.outputs.borders << args.state.center_box
    end

    # Then render the moving box.
    args.outputs.sprites << args.state.moving_box
  end

  # Generally in a pipeline for a game engine, you have rendering,
  # game simulation (calculation), and input processing.
  # This fuction represents the game simulation.
  def calc args
    position_moving_box args.state.moving_box
    determine_collision_center_box args
  end

  # Changes the position of the moving box on the screen by multiplying the change in x (dx) and change in y (dy) by the speed,
  # and adding it to the current position.
  # dx and dy are positive if the box is moving right and up, respectively
  # dx and dy are negative if the box is moving left and down, respectively
  def position_moving_box box
    box.x += box.dx * box.speed
    box.y += box.dy * box.speed

    # 1280x720 are the virtual pixels you work with (essentially 720p).
    screen_width  = 1280
    screen_height = 720

    # Position of the box is denoted by the bottom left hand corner, in
    # that case, we have to subtract the width of the box so that it stays
    # in the scene (you can try deleting the subtraction to see how it
    # impacts the box's movement).
    if box.x + box.w > screen_width # if the box moves too far right
      box.dx = -1 # moves left
    elsif box.x < 0
      box.dx =  1 # moves right
    end

    # Here, we're making sure the moving box remains within the vertical scope of the screen
    if box.y + box.h > screen_height # if the box moves too high
      box.dy = -1 # moves down
    elsif box.y < 0 # if the box moves too low
      box.dy =  1 # moves up
    end
  end

  def determine_collision_center_box args
    # Collision is handled by the engine. You simply have to call the
    # `intersect_rect?` function.
    if Geometry.intersect_rect? args.state.moving_box, args.state.center_box # if the two boxes intersect
      args.state.center_box_collision = true # then a collision happened
    else
      args.state.center_box_collision = false # otherwise, no collision happened
    end
  end

  DR.reset

```

### Simple Aabb Collision - main.rb
```ruby
  # ./samples/04_physics_and_collisions/01_simple_aabb_collision/app/main.rb
  def tick args
    # define terrain of 32x32 sized squares
    args.state.terrain ||= [
      { x: 640,          y: 360,          w: 32, h: 32, path: 'sprites/square/blue.png' },
      { x: 640,          y: 360 - 32,     w: 32, h: 32, path: 'sprites/square/blue.png' },
      { x: 640,          y: 360 - 32 * 2, w: 32, h: 32, path: 'sprites/square/blue.png' },
      { x: 640 + 32,     y: 360 - 32 * 2, w: 32, h: 32, path: 'sprites/square/blue.png' },
      { x: 640 + 32 * 2, y: 360 - 32 * 2, w: 32, h: 32, path: 'sprites/square/blue.png' },
    ]

    # define player
    args.state.player ||= {
      x: 600,
      y: 360,
      w: 32,
      h: 32,
      dx: 0,
      dy: 0,
      path: 'sprites/square/red.png'
    }

    # render terrain and player
    args.outputs.sprites << args.state.terrain
    args.outputs.sprites << args.state.player

    # set dx and dy based on inputs
    args.state.player.dx = args.inputs.left_right * 2
    args.state.player.dy = args.inputs.up_down * 2

    # check for collisions on the x and y axis independently

    # increment the player's position by dx
    args.state.player.x += args.state.player.dx

    # check for collision on the x axis first
    collision = args.state.terrain.find { |t| t.intersect_rect? args.state.player }

    # if there is a collision, move the player to the edge of the collision
    # based on the direction of the player's movement and set the player's
    # dx to 0
    if collision
      if args.state.player.dx > 0
        args.state.player.x = collision.x - args.state.player.w
      elsif args.state.player.dx < 0
        args.state.player.x = collision.x + collision.w
      end
      args.state.player.dx = 0
    end

    # increment the player's position by dy
    args.state.player.y += args.state.player.dy

    # check for collision on the y axis next
    collision = args.state.terrain.find { |t| t.intersect_rect? args.state.player }

    # if there is a collision, move the player to the edge of the collision
    # based on the direction of the player's movement and set the player's
    # dy to 0
    if collision
      if args.state.player.dy > 0
        args.state.player.y = collision.y - args.state.player.h
      elsif args.state.player.dy < 0
        args.state.player.y = collision.y + collision.h
      end
      args.state.player.dy = 0
    end
  end

```

### Simple Aabb Collision Moving Walls - main.rb
```ruby
  # ./samples/04_physics_and_collisions/01_simple_aabb_collision_moving_walls/app/main.rb
  class Game
    attr_dr

    def initialize
      @dvd = {
        x: 640,
        y: 360,
        w: 64,
        h: 64,
        dx: 5,
        dy: 5,
        path: :solid,
        r: 80,
        g: 0,
        b: 0
      }

      @growth_speed = 10

      @blocks = {
        left: {
          x: 0,
          y: 0,
          target_x: 0,
          target_y: 0,
          dx: 0,
          dy: 0,
          w: 5,
          h: 720,
          target_w: 5,
          target_h: 720,
          dw: @growth_speed,
          dh: 0,
          path: :solid,
          r: 0,
          g: 0,
          b: 0
        },
        right: {
          x: 1275,
          y: 0,
          target_x: 1275,
          target_y: 0,
          dx: -@growth_speed,
          dy: 0,
          w: 5,
          h: 720,
          target_w: 5,
          target_h: 720,
          dw: @growth_speed,
          dh: 0,
          path: :solid,
          r: 0,
          g: 0,
          b: 0
        },
        top: {
          x: 0,
          y: 0,
          dx: 0,
          dy: 0,
          target_x: 0,
          target_y: 0,
          w: 1280,
          h: @growth_speed,
          target_w: 1280,
          target_h: 5,
          dw: 10,
          dh: 10,
          path: :solid,
          r: 0,
          g: 0,
          b: 0
        },
        bottom: {
          x: 0,
          y: 715,
          dx: 0,
          dy: -@growth_speed,
          target_x: 0,
          target_y: 715,
          w: 1280,
          h: 5,
          target_w: 1280,
          target_h: 5,
          dw: 10,
          dh: @growth_speed,
          path: :solid,
          r: 0,
          g: 0,
          b: 0
        },
      }
    end

    def align_x! target, to
      return if !to

      if target.x < to.x
        target.x = to.x - target.w
      else
        target.x = to.x + to.w
      end
    end

    def align_y! target, to
      return if !to

      if target.y > to.y
        target.y = to.y + to.h
      else
        target.y = to.y - target.h
      end
    end

    def tick
      outputs.background_color = [80, 80, 80]
      available_w = 1280 - (@blocks.left.target_w + @blocks.left.dw) - (@blocks.right.target_w + @blocks.right.dw)
      available_h = 720 - (@blocks.bottom.target_h + @blocks.bottom.dh) - (@blocks.top.target_h + @blocks.top.dh)

      if inputs.keyboard.key_down.j || inputs.keyboard.key_down.space
        @blocks.each do |_, block|
          if available_w > @dvd.w
            block.target_w += block.dw
            block.target_x += block.dx
          end

          if available_h > @dvd.h
            block.target_h += block.dh
            block.target_y += block.dy
          end
        end
      end

      @blocks.each do |_, block|
        block.w = block.w.lerp(block.target_w, 0.1)
        block.x = block.x.lerp(block.target_x, 0.1)
        collision = @blocks.values.find { |block| Geometry.intersect_rect?(@dvd, block) }
        align_x!(@dvd, collision)

        block.h = block.h.lerp(block.target_h, 0.1)
        block.y = block.y.lerp(block.target_y, 0.1)
        collision = @blocks.values.find { |block| Geometry.intersect_rect?(@dvd, block) }
        align_y!(@dvd, collision)
      end

      @dvd.x += @dvd.dx
      collision = @blocks.values.find { |block| Geometry.intersect_rect?(@dvd, block) }
      if collision
        align_x!(@dvd, collision)
        @dvd.dx = -@dvd.dx
      end

      @dvd.y += @dvd.dy
      collision = @blocks.values.find { |block| Geometry.intersect_rect?(@dvd, block) }
      if collision
        align_y!(@dvd, collision)
        @dvd.dy = -@dvd.dy
      end

      outputs.labels << { x: 640, y: 360, text: "Press J or Space to shrink the walls.", anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255 }
      outputs.sprites << @dvd
      outputs.sprites << @blocks.values
    end
  end

  def boot args
    args.state = {}
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
  end

  DR.reset

```

### Simple Aabb Collision With Map Editor - main.rb
```ruby
  # ./samples/04_physics_and_collisions/01_simple_aabb_collision_with_map_editor/app/main.rb
  # the sample app is an expansion of ./01_simple_aabb_collision
  # but includes an in game map editor that saves map data to disk
  def tick args
    # if it's the first tick, read the terrain data from disk
    # and create the player
    if Kernel.tick_count == 0
      args.state.terrain = read_terrain_data args

      args.state.player = {
        x: 320,
        y: 320,
        w: 32,
        h: 32,
        dx: 0,
        dy: 0,
        path: 'sprites/square/red.png'
      }
    end

    # tick the game (where input and aabb collision is processed)
    tick_game args

    # tick the map editor
    tick_map_editor args
  end

  def tick_game args
    # render terrain and player
    args.outputs.sprites << args.state.terrain
    args.outputs.sprites << args.state.player

    # set dx and dy based on inputs
    args.state.player.dx = args.inputs.left_right * 2
    args.state.player.dy = args.inputs.up_down * 2

    # check for collisions on the x and y axis independently

    # increment the player's position by dx
    args.state.player.x += args.state.player.dx

    # check for collision on the x axis first
    collision = args.state.terrain.find { |t| t.intersect_rect? args.state.player }

    # if there is a collision, move the player to the edge of the collision
    # based on the direction of the player's movement and set the player's
    # dx to 0
    if collision
      if args.state.player.dx > 0
        args.state.player.x = collision.x - args.state.player.w
      elsif args.state.player.dx < 0
        args.state.player.x = collision.x + collision.w
      end
      args.state.player.dx = 0
    end

    # increment the player's position by dy
    args.state.player.y += args.state.player.dy

    # check for collision on the y axis next
    collision = args.state.terrain.find { |t| t.intersect_rect? args.state.player }

    # if there is a collision, move the player to the edge of the collision
    # based on the direction of the player's movement and set the player's
    # dy to 0
    if collision
      if args.state.player.dy > 0
        args.state.player.y = collision.y - args.state.player.h
      elsif args.state.player.dy < 0
        args.state.player.y = collision.y + collision.h
      end
      args.state.player.dy = 0
    end
  end

  def tick_map_editor args
    # determine the location of the mouse, but
    # aligned to the grid
    grid_aligned_mouse_rect = {
      x: args.inputs.mouse.x.idiv(32) * 32,
      y: args.inputs.mouse.y.idiv(32) * 32,
      w: 32,
      h: 32
    }

    # determine if there's a tile at the grid aligned mouse location
    existing_terrain = args.state.terrain.find { |t| t.intersect_rect? grid_aligned_mouse_rect }

    # if there is, then render a red square to denote that
    # the tile will be deleted
    if existing_terrain
      args.outputs.sprites << {
        x: args.inputs.mouse.x.idiv(32) * 32,
        y: args.inputs.mouse.y.idiv(32) * 32,
        w: 32,
        h: 32,
        path: "sprites/square/red.png",
        a: 128
      }
    else
      # otherwise, render a blue square to denote that
      # a tile will be added
      args.outputs.sprites << {
        x: args.inputs.mouse.x.idiv(32) * 32,
        y: args.inputs.mouse.y.idiv(32) * 32,
        w: 32,
        h: 32,
        path: "sprites/square/blue.png",
        a: 128
      }
    end

    # if the mouse is clicked, then add or remove a tile
    if args.inputs.mouse.click
      if existing_terrain
        args.state.terrain.delete existing_terrain
      else
        args.state.terrain << { **grid_aligned_mouse_rect, path: "sprites/square/blue.png" }
      end

      # once the terrain state has been updated
      # save the terrain data to disk
      write_terrain_data args
    end
  end

  def read_terrain_data args
    # create the terrain data file if it doesn't exist
    contents = DR.read_file "data/terrain.txt"
    if !contents
      DR.write_file "data/terrain.txt", ""
    end

    # read the terrain data from disk which is a csv
    DR.read_file('data/terrain.txt').split("\n").map do |line|
      x, y, w, h = line.split(',').map(&:to_i)
      { x: x, y: y, w: w, h: h, path: 'sprites/square/blue.png' }
    end
  end

  def write_terrain_data args
    terrain_csv = args.state.terrain.map { |t| "#{t.x},#{t.y},#{t.w},#{t.h}" }.join "\n"
    DR.write_file 'data/terrain.txt', terrain_csv
  end

```

### Simple Aabb Grid Aligned Movement - main.rb
```ruby
  # ./samples/04_physics_and_collisions/01_simple_aabb_grid_aligned_movement/app/main.rb
  class Game
    attr_dr

    def initialize
      # generate available spaces that the player can move through
      @cells = 32.flat_map do |x_ordinal|
        18.map do |y_ordinal|
          {
            **Geometry.rect(x: x_ordinal * 40, y: y_ordinal * 40, w: 40, h: 40),
            x_ordinal: x_ordinal,
            y_ordinal: y_ordinal,
          }
        end
      end

      # track which spaces have walls in them
      @walls = []

      # player's position, size, and movement direction
      @player = {
        x: 20,
        y: 20,
        w: 40,
        h: 40,
        dx: 1,
        dy: 0,
        anchor_x: 0.5,
        anchor_y: 0.5,
        path: :solid,
        r: 128, g: 255, b: 128,
      }
    end

    def tick
      # toggle walls on mouse click
      if inputs.mouse.key_up.left
        cell = Geometry.find_intersect_rect(inputs.mouse, @cells)
        if cell
          if @walls.include?(cell)
            @walls.delete(cell)
          else
            @walls << cell
          end
        end
      end

      # move player based on arrow key input, but only if the player won't collide with a wall
      if inputs.up_down != 0
        # first check cells to see if the player is grid aligned
        collisions = Geometry.find_all_intersect_rect(
          { **@player, y: @player.y + inputs.up_down },
          @cells,
          tolerance: 0
        )

        # if the player is intersecting with exactly 2 cells, then they are grid aligned and we can check for wall collisions
        if collisions.length == 2
          # if neither of the cells the player is intersecting with have walls, then we can move the player
          if collisions.none? { |collision| @walls.include?(collision) }
            # update the player's movement direction based on the input
            @player.dy = inputs.up_down
            @player.dx = 0
          end
        end
      elsif inputs.left_right != 0
        collisions = Geometry.find_all_intersect_rect(
          { **@player, x: @player.x + inputs.left_right },
          @cells,
          tolerance: 0
        )

        if collisions.length == 2
          if collisions.none? { |collision| @walls.include?(collision) }
            @player.dy = 0
            @player.dx = inputs.left_right
          end
        end
      end

      # move the player based on their movement direction, but only if they won't collide with a wall
      @player.x += @player.dx * 2
      if Geometry.find_intersect_rect(@player, @walls)
        @player.x -= @player.dx * 2
      end
      @player.y += @player.dy * 2
      if Geometry.find_intersect_rect(@player, @walls)
        @player.y -= @player.dy * 2
      end

      # render the game
      outputs.background_color = [30, 30, 30]
      outputs.primitives << @cells.map do |cell|
        {
          **Geometry.zoom_rect(rect: cell, px: -1),
          path: :solid, r: 0, g: 0, b: 0, a: 128
        }
      end
      outputs.primitives << @walls.map do |cell|
        {
          **Geometry.zoom_rect(rect: cell, px: -1),
          path: :solid, r: 255, g: 255, b: 255, a: 128
        }
      end
      outputs.primitives << @player
      outputs.primitives << {
        x: 640, y: 360, text: "Click to add/remove walls. Use arrow keys to move.",
        anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255
      }
    end
  end

  module Main
    def tick args
      @game ||= Game.new
      @game.args = args
      @game.tick
    end

    def reset args
      @game = nil
    end
  end

  GTK.reset

```

### Simple Aabb Grid Aligned Movement Advanced - main.rb
```ruby
  # ./samples/04_physics_and_collisions/01_simple_aabb_grid_aligned_movement_advanced/app/main.rb
  class Game
    attr_dr

    def initialize
      @box_speed = 1
      @current_track_type = :right
      @cells = 30.flat_map do |x_ordinal|
        18.map do |y_ordinal|
          {
            **Geometry.rect(x: x_ordinal * 40, y: y_ordinal * 40, w: 40, h: 40),
            x_ordinal: x_ordinal,
            y_ordinal: y_ordinal,
          }
        end
      end

      @buttons = [
        {
          rect: Layout.rect(row: 0, col: 23, w: 1, h: 1),
          title: "type",
          text: -> { "#{track_char @current_track_type}" },
          callback: -> {
            case @current_track_type
            when :right
              @current_track_type = :down
            when :down
              @current_track_type = :left
            when :left
              @current_track_type = :up
            when :up
              @current_track_type = :right
            end
          }
        },
        {
          rect: Layout.rect(row: 1, col: 23, w: 1, h: 1),
          title: "speed",
          text: -> { "#{@box_speed}" },
          callback: -> {
            candidate_speed = @box_speed + 1
            while candidate_speed <= 20
              break if 40.zmod?(candidate_speed)
              candidate_speed += 1
            end
            if candidate_speed > 20
              candidate_speed = 1
            end
            @box_speed = candidate_speed
            @boxes = []
          },
        },
        {
          rect: Layout.rect(row: 2, col: 23, w: 1, h: 1),
          title: "clear boxes",
          text: -> { "#{@boxes.length}" },
          callback: -> { @boxes = [] }
        }
      ]

      @tracks = []
      @boxes = []
    end

    def new_box
      {
        x: 20,
        y: 340,
        w: 40,
        h: 40,
        dx: 0,
        dy: 0,
        speed: @box_speed,
        anchor_x: 0.5,
        anchor_y: 0.5,
        path: :solid,
        r: 128, g: 255, b: 128, a: 200
      }
    end

    def calc_edit_track
      cell = Geometry.find_intersect_rect(inputs.mouse, @cells)

      return if !cell

      track = Geometry.find_intersect_rect(inputs.mouse, @tracks)

      if inputs.mouse.key_up.left
        @tracks.delete track if track
        @tracks << { **cell, type: @current_track_type }
      elsif inputs.mouse.key_up.right
        @tracks.delete track if track
      end
    end

    def track_direction track
      type = if track.is_a? Symbol
               track
             else
               track.type
             end
      case type
      when :right
        { dx: 1, dy: 0 }
      when :down
        { dx: 0, dy: -1 }
      when :left
        { dx: -1, dy: 0 }
      when :up
        { dx: 0, dy: 1 }
      else
        raise "Unknown track type: #{track.type}"
      end
    end

    def tick_box box
      box.previous_track = box.current_track

      track_collisions = Geometry.find_all_intersect_rect(
        box,
        @tracks,
        tolerance: 0
      )

      cell_collisions = Geometry.find_all_intersect_rect(
        box,
        @cells,
        tolerance: 0
      )

      box.current_track = track_collisions.first

      if track_collisions.length == 0
        box.dx = 0
        box.dy = 0
      elsif track_collisions.length == 1 && cell_collisions.length == 1
        direction = track_direction(track_collisions.first)
        box.dx = direction.dx
        box.dy = direction.dy
      end

      box.x += box.dx * box.speed
      other_box = Geometry.find_intersect_rect(box, @boxes.reject { |b| b == box })
      if other_box
        if box.dx > 0
          box.x = other_box.x - box.w
        elsif box.dx < 0
          box.x = other_box.x + other_box.w
        end
      end
      box.y += box.dy * box.speed
      other_box = Geometry.find_intersect_rect(box, @boxes.reject { |b| b == box })
      if other_box
        if box.dy > 0
          box.y = other_box.y - box.h
        elsif box.dy < 0
          box.y = other_box.y + other_box.h
        end
      end
    end

    def track_char track
      type = if track.is_a? Symbol
               track
             else
               track.type
             end

      case type
      when :right
        "→"
      when :down
        "↓"
      when :left
        "←"
      when :up
        "↑"
      end
    end

    def calc_buttons
      return if !inputs.mouse.key_up.left
      button = Geometry.find_intersect_rect(inputs.mouse, @buttons, using: :rect)
      button.callback.call if button
    end

    def track_primitives track
      [
        {
          **Geometry.zoom_rect(rect: track, px: -1),
          path: :solid, r: 255, g: 255, b: 255, a: 128
        },
        {
          **track.center,
          text: track_char(track),
          anchor_x: 0.5,
          anchor_y: 0.5,
          r: 255,
          g: 255,
          b: 255
        }
      ]
    end

    def calc_boxes
      @boxes.each { |box| tick_box box }

      if Kernel.tick_count.zmod?(120)
        box_to_add = new_box
        if !Geometry.find_intersect_rect(box_to_add, @boxes)
          @boxes << box_to_add
        end
      end
    end

    def tick
      calc_edit_track
      calc_buttons
      calc_boxes
      render
    end

    def render
      outputs.background_color = [30, 30, 30]

      outputs.primitives << @cells.map do |cell|
        {
          **Geometry.zoom_rect(rect: cell, px: -1),
          path: :solid, r: 0, g: 0, b: 0, a: 128
        }
      end

      outputs.primitives << @tracks.map do |track|
        track_primitives track
      end

      outputs.primitives << @boxes
      outputs.primitives << {
        x: 640, y: 720, text: "Click to add/override track. Right click to remove track.",
        anchor_x: 0.5, anchor_y: 1, r: 255, g: 255, b: 255
      }

      outputs.primitives << {
        x: 640, y: 720, text: "Buttons at far right to change track type, change box speed, and clear boxes.",
        anchor_x: 0.5, anchor_y: 2, r: 255, g: 255, b: 255
      }

      mouse_cell = Geometry.find_intersect_rect(inputs.mouse, @cells)

      if mouse_cell
        outputs.primitives << track_primitives({ **mouse_cell, type: @current_track_type })
      end

      outputs.primitives << @buttons.map do |button|
        text = button.text.is_a?(Proc) ? button.text.call : button.text
        [
          { **button.rect, path: :solid, r: 0, g: 0, b: 0, a: 255 },
          { **button.rect.center,
            text: button.title,
            anchor_x: 0.5,
            anchor_y: 0.0,
            r: 255,
            g: 255,
            b: 255,
            size_px: 14 },
          { **button.rect.center,
            text: text,
            anchor_x: 0.5,
            anchor_y: 1.5,
            r: 255,
            g: 255,
            b: 255,
            size_px: 14 }
        ]
      end
    end
  end

  module Main
    def tick args
      @game ||= Game.new
      @game.args = args
      @game.tick
    end

    def reset args
      @game = nil
    end
  end

  GTK.reset

```

### Moving Objects - main.rb
```ruby
  # ./samples/04_physics_and_collisions/02_moving_objects/app/main.rb
  =begin

   APIs listing that haven't been encountered in previous sample apps:

   - Hashes: Collection of unique keys and their corresponding values. The value can be found
     using their keys.

     For example, if we have a "numbers" hash that stores numbers in English as the
     key and numbers in Spanish as the value, we'd have a hash that looks like this...
     numbers = { "one" => "uno", "two" => "dos", "three" => "tres" }
     and on it goes.

     Now if we wanted to find the corresponding value of the "one" key, we could say
     puts numbers["one"]
     which would print "uno" to the console.

   - num1.greater(num2): Returns the greater value.
     For example, if we have the command
     puts 4.greater(3)
     the number 4 would be printed to the console since it has a greater value than 3.
     Similar to lesser, which returns the lesser value.

   - num1.lesser(num2): Finds the lower value of the given options.
     For example, in the statement
     a = 4.lesser(3)
     3 has a lower value than 4, which means that the value of a would be set to 3,
     but if the statement had been
     a = 4.lesser(5)
     4 has a lower value than 5, which means that the value of a would be set to 4.

   - reject: Removes elements from a collection if they meet certain requirements.
     For example, you can derive an array of odd numbers from an original array of
     numbers 1 through 10 by rejecting all elements that are even (or divisible by 2).

   - find_all: Finds all values that satisfy specific requirements.
     For example, you can find all elements of a collection that are divisible by 2
     or find all objects that have intersected with another object.

   - abs: Returns the absolute value.
     For example, the command
     (-30).abs
     would return 30 as a result.

   - map: Ruby method used to transform data; used in arrays, hashes, and collections.
     Can be used to perform an action on every element of a collection, such as multiplying
     each element by 2 or declaring every element as a new entity.

   Reminders:

   - args.inputs.keyboard.KEY: Determines if a key has been pressed.
     For more information about the keyboard, take a look at mygame/documentation/06-keyboard.md.

   - ARRAY#intersect_rect?: Returns true or false depending on if the two rectangles intersect.

   - args.outputs.solids: An array. The values generate a solid.
     The parameters are [X, Y, WIDTH, HEIGHT, RED, GREEN, BLUE]
     For more information about solids, go to mygame/documentation/03-solids-and-borders.md.

  =end

  # Calls methods needed for game to run properly
  def tick args
    tick_instructions args, "Use LEFT and RIGHT arrow keys to move and SPACE to jump."
    defaults args
    render args
    calc args
    input args
  end

  # sets default values and creates empty collections
  # initialization only happens in the first frame
  def defaults args
    fiddle args
    args.state.enemy.hammers ||= []
    args.state.enemy.hammer_queue ||= []
    Kernel.tick_count = Kernel.tick_count
    args.state.bridge_top = 128
    args.state.player.x  ||= 0                        # initializes player's properties
    args.state.player.y  ||= args.state.bridge_top
    args.state.player.w  ||= 64
    args.state.player.h  ||= 64
    args.state.player.dy ||= 0
    args.state.player.dx ||= 0
    args.state.enemy.x   ||= 800                      # initializes enemy's properties
    args.state.enemy.y   ||= 0
    args.state.enemy.w   ||= 128
    args.state.enemy.h   ||= 128
    args.state.enemy.dy  ||= 0
    args.state.enemy.dx  ||= 0
    args.state.game_over_at ||= 0
  end

  # sets enemy, player, hammer values
  def fiddle args
    args.state.gravity                     = -0.3
    args.state.enemy_jump_power            = 10       # sets enemy values
    args.state.enemy_jump_interval         = 60
    args.state.hammer_throw_interval       = 40       # sets hammer values
    args.state.hammer_launch_power_default = 5
    args.state.hammer_launch_power_near    = 2
    args.state.hammer_launch_power_far     = 7
    args.state.hammer_upward_launch_power  = 15
    args.state.max_hammers_per_volley      = 10
    args.state.gap_between_hammers         = 10
    args.state.player_jump_power           = 10       # sets player values
    args.state.player_jump_power_duration  = 10
    args.state.player_max_run_speed        = 10
    args.state.player_speed_slowdown_rate  = 0.9
    args.state.player_acceleration         = 1
    args.state.hammer_size                 = 32
  end

  # outputs objects onto the screen
  def render args
    args.outputs.solids << 20.map_with_index do |i| # uses 20 squares to form bridge
      # sets x by multiplying 64 to index to find pixel value (places all squares side by side)
      # subtracts 64 from bridge_top because position is denoted by bottom left corner
      [i * 64, args.state.bridge_top - 64, 64, 64]
    end

    args.outputs.solids << [args.state.x, args.state.y, args.state.w, args.state.h, 255, 0, 0]
    args.outputs.solids << [args.state.player.x, args.state.player.y, args.state.player.w, args.state.player.h, 255, 0, 0] # outputs player onto screen (red box)
    args.outputs.solids << [args.state.enemy.x, args.state.enemy.y, args.state.enemy.w, args.state.enemy.h, 0, 255, 0] # outputs enemy onto screen (green box)
    args.outputs.solids << args.state.enemy.hammers # outputs enemy's hammers onto screen
  end

  # Performs calculations to move objects on the screen
  def calc args

    # Since velocity is the change in position, the change in x increases by dx. Same with y and dy.
    args.state.player.x  += args.state.player.dx
    args.state.player.y  += args.state.player.dy

    # Since acceleration is the change in velocity, the change in y (dy) increases every frame
    args.state.player.dy += args.state.gravity

    # player's y position is either current y position or y position of top of
    # bridge, whichever has a greater value
    # ensures that the player never goes below the bridge
    args.state.player.y  = args.state.player.y.greater(args.state.bridge_top)

    # player's x position is either the current x position or 0, whichever has a greater value
    # ensures that the player doesn't go too far left (out of the screen's scope)
    args.state.player.x  = args.state.player.x.greater(0)

    # player is not falling if it is located on the top of the bridge
    args.state.player.falling = false if args.state.player.y == args.state.bridge_top
    args.state.player.rect = [args.state.player.x, args.state.player.y, args.state.player.h, args.state.player.w] # sets definition for player

    args.state.enemy.x += args.state.enemy.dx # velocity; change in x increases by dx
    args.state.enemy.y += args.state.enemy.dy # same with y and dy

    # ensures that the enemy never goes below the bridge
    args.state.enemy.y  = args.state.enemy.y.greater(args.state.bridge_top)

    # ensures that the enemy never goes too far left (outside the screen's scope)
    args.state.enemy.x  = args.state.enemy.x.greater(0)

    # objects that go up must come down because of gravity
    args.state.enemy.dy += args.state.gravity

    args.state.enemy.y  = args.state.enemy.y.greater(args.state.bridge_top)

    #sets definition of enemy
    args.state.enemy.rect = [args.state.enemy.x, args.state.enemy.y, args.state.enemy.h, args.state.enemy.w]

    if args.state.enemy.y == args.state.bridge_top # if enemy is located on the top of the bridge
      args.state.enemy.dy = 0 # there is no change in y
    end

    # if 60 frames have passed and the enemy is not moving vertically
    if Kernel.tick_count.mod_zero?(args.state.enemy_jump_interval) && args.state.enemy.dy == 0
      args.state.enemy.dy = args.state.enemy_jump_power # the enemy jumps up
    end

    # if 40 frames have passed or 5 frames have passed since the game ended
    if Kernel.tick_count.mod_zero?(args.state.hammer_throw_interval) || args.state.game_over_at.elapsed_time == 5
      # rand will return a number greater than or equal to 0 and less than given variable's value (since max is excluded)
      # that is why we're adding 1, to include the max possibility
      volley_dx   = (rand(args.state.hammer_launch_power_default) + 1) * -1 # horizontal movement (follow order of operations)

      # if the horizontal distance between the player and enemy is less than 128 pixels
      if (args.state.player.x - args.state.enemy.x).abs < 128
        # the change in x won't be that great since the enemy and player are closer to each other
        volley_dx = (rand(args.state.hammer_launch_power_near) + 1) * -1
      end

      # if the horizontal distance between the player and enemy is greater than 300 pixels
      if (args.state.player.x - args.state.enemy.x).abs > 300
        # change in x will be more drastic since player and enemy are so far apart
        volley_dx = (rand(args.state.hammer_launch_power_far) + 1) * -1 # more drastic change
      end

      (rand(args.state.max_hammers_per_volley) + 1).map_with_index do |i|
        args.state.enemy.hammer_queue << { # stores hammer values in a hash
          x: args.state.enemy.x,
          w: args.state.hammer_size,
          h: args.state.hammer_size,
          dx: volley_dx, # change in horizontal position
          # multiplication operator takes precedence over addition operator
          throw_at: Kernel.tick_count + i * args.state.gap_between_hammers
        }
      end
    end

    # add elements from hammer_queue collection to the hammers collection by
    # finding all hammers that were thrown before the current frame (have already been thrown)
    args.state.enemy.hammers += args.state.enemy.hammer_queue.find_all do |h|
      h[:throw_at] < Kernel.tick_count
    end

    args.state.enemy.hammers.each do |h| # sets values for all hammers in collection
      h[:y]  ||= args.state.enemy.y + 130
      h[:dy] ||= args.state.hammer_upward_launch_power
      h[:dy]  += args.state.gravity # acceleration is change in gravity
      h[:x]   += h[:dx] # incremented by change in position
      h[:y]   += h[:dy]
      h[:rect] = [h[:x], h[:y], h[:w], h[:h]] # sets definition of hammer's rect
    end

    # reject hammers that have been thrown before current frame (have already been thrown)
    args.state.enemy.hammer_queue = args.state.enemy.hammer_queue.reject do |h|
      h[:throw_at] < Kernel.tick_count
    end

    # any hammers with a y position less than 0 are rejected from the hammers collection
    # since they have gone too far down (outside the scope's screen)
    args.state.enemy.hammers = args.state.enemy.hammers.reject { |h| h[:y] < 0 }

    # if there are any hammers that intersect with (or hit) the player,
    # the reset_player method is called (so the game can start over)
    if args.state.enemy.hammers.any? { |h| h[:rect].intersect_rect?(args.state.player.rect) }
      reset_player args
    end

    # if the enemy's rect intersects with (or hits) the player,
    # the reset_player method is called (so the game can start over)
    if args.state.enemy.rect.intersect_rect? args.state.player.rect
      reset_player args
    end
  end

  # Resets the player by changing its properties back to the values they had at initialization
  def reset_player args
    args.state.player.x = 0
    args.state.player.y = args.state.bridge_top
    args.state.player.dy = 0
    args.state.player.dx = 0
    args.state.enemy.hammers.clear # empties hammer collection
    args.state.enemy.hammer_queue.clear # empties hammer_queue
    args.state.game_over_at = Kernel.tick_count # game_over_at set to current frame (or passage of time)
  end

  # Processes input from the user to move the player
  def input args
    if args.inputs.keyboard.space # if the user presses the space bar
      args.state.player.jumped_at ||= Kernel.tick_count # jumped_at is set to current frame

      # if the time that has passed since the jump is less than the player's jump duration and
      # the player is not falling
      if args.state.player.jumped_at.elapsed_time < args.state.player_jump_power_duration && !args.state.player.falling
        args.state.player.dy = args.state.player_jump_power # change in y is set to power of player's jump
      end
    end

    # if the space bar is in the "up" state (or not being pressed down)
    if args.inputs.keyboard.key_up.space
      args.state.player.jumped_at = nil # jumped_at is empty
      args.state.player.falling = true # the player is falling
    end

    if args.inputs.keyboard.left # if left key is pressed
      args.state.player.dx -= args.state.player_acceleration # dx decreases by acceleration (player goes left)
      # dx is either set to current dx or the negative max run speed (which would be -10),
      # whichever has a greater value
      args.state.player.dx = args.state.player.dx.greater(-args.state.player_max_run_speed)
    elsif args.inputs.keyboard.right # if right key is pressed
      args.state.player.dx += args.state.player_acceleration # dx increases by acceleration (player goes right)
      # dx is either set to current dx or max run speed (which would be 10),
      # whichever has a lesser value
      args.state.player.dx = args.state.player.dx.lesser(args.state.player_max_run_speed)
    else
      args.state.player.dx *= args.state.player_speed_slowdown_rate # dx is scaled down
    end
  end

  def tick_instructions args, text, y = 715
    return if args.state.key_event_occurred
    if args.inputs.mouse.click ||
       args.inputs.keyboard.directional_vector ||
       args.inputs.keyboard.key_down.enter ||
       args.inputs.keyboard.key_down.space ||
       args.inputs.keyboard.key_down.escape
      args.state.key_event_occurred = true
    end

    args.outputs.debug << [0, y - 50, 1280, 60].solid
    args.outputs.debug << [640, y, text, 1, 1, 255, 255, 255].label
    args.outputs.debug << [640, y - 25, "(click to dismiss instructions)" , -2, 1, 255, 255, 255].label
  end

```

### Entities - main.rb
```ruby
  # ./samples/04_physics_and_collisions/03_entities/app/main.rb
  =begin

   Reminders:

   - map: Ruby method used to transform data; used in arrays, hashes, and collections.
     Can be used to perform an action on every element of a collection, such as multiplying
     each element by 2 or declaring every element as a new entity.

   - reject: Removes elements from a collection if they meet certain requirements.
     For example, you can derive an array of odd numbers from an original array of
     numbers 1 through 10 by rejecting all elements that are even (or divisible by 2).

   - args.state.new_entity: Used when we want to create a new object, like a sprite or button.
     In this sample app, new_entity is used to define the properties of enemies and bullets.
     (Remember, you can use state to define ANY property and it will be retained across frames.)

   - args.outputs.labels: An array. The values generate a label on the screen.
     The parameters are [X, Y, TEXT, SIZE, ALIGN, RED, GREEN, BLUE, ALPHA, FONT STYLE]

   - ARRAY#intersect_rect?: Returns true or false depending on if the two rectangles intersect.

   - args.inputs.mouse.click.point.(x|y): The x and y location of the mouse.

  =end

  # This sample app shows enemies that contain an id value and the time they were created.
  # These enemies can be removed by shooting at them with bullets.

  # Calls all methods necessary for the game to function properly.
  def tick args
    tick_instructions args, "Sample app shows how to use args.state.new_entity along with collisions. CLICK to shoot a bullet."
    defaults args
    render args
    calc args
    process_inputs args
  end

  # Sets default values
  # Enemies and bullets start off as empty collections
  def defaults args
    args.state.enemies ||= []
    args.state.bullets ||= []
  end

  # Provides each enemy in enemies collection with rectangular border,
  # as well as a label showing id and when they were created
  def render args
    # When you're calling a method that takes no arguments, you can use this & syntax on map.
    # Numbers are being added to x and y in order to keep the text within the enemy's borders.
    args.outputs.borders << args.state.enemies.map(&:rect)
    args.outputs.labels  << args.state.enemies.flat_map do |enemy|
      [
        [enemy.x + 4, enemy.y + 29, "id: #{enemy.entity_id}", -3, 0],
        [enemy.x + 4, enemy.y + 17, "created_at: #{enemy.created_at}", -3, 0] # frame enemy was created
      ]
    end

    # Outputs bullets in bullets collection as rectangular solids
    args.outputs.solids << args.state.bullets.map(&:rect)
  end

  # Calls all methods necessary for performing calculations
  def calc args
    add_new_enemies_if_needed args
    move_bullets args
    calculate_collisions args
    remove_bullets_of_screen args
  end

  # Adds enemies to the enemies collection and sets their values
  def add_new_enemies_if_needed args
    return if args.state.enemies.length >= 10 # if 10 or more enemies, enemies are not added
    return unless args.state.bullets.length == 0 # if user has not yet shot bullet, no enemies are added

    args.state.enemies += (10 - args.state.enemies.length).map do # adds enemies so there are 10 total
      args.state.new_entity(:enemy) do |e| # each enemy is declared as a new entity
        e.x = 640 + 500 * rand # each enemy is given random position on screen
        e.y = 600 * rand + 50
        e.rect = [e.x, e.y, 130, 30] # sets definition for enemy's rect
      end
    end
  end

  # Moves bullets across screen
  # Sets definition of the bullets
  def move_bullets args
    args.state.bullets.each do |bullet| # perform action on each bullet in collection
      bullet.x += bullet.speed # increment x by speed (bullets fly horizontally across screen)

      # By randomizing the value that increments bullet.y, the bullet does not fly straight up and out
      # of the scope of the screen. Try removing what follows bullet.speed, or changing 0.25 to 1.25 to
      # see what happens to the bullet's movement.
      bullet.y += bullet.speed.*(0.25).randomize(:ratio, :sign)
      bullet.rect = [bullet.x, bullet.y, bullet.size, bullet.size] # sets definition of bullet's rect
    end
  end

  # Determines if a bullet hits an enemy
  def calculate_collisions args
    args.state.bullets.each do |bullet| # perform action on every bullet and enemy in collections
      args.state.enemies.each do |enemy|
        # if bullet has not exploded yet and the bullet hits an enemy
        if !bullet.exploded && bullet.rect.intersect_rect?(enemy.rect)
          bullet.exploded = true # bullet explodes
          enemy.dead = true # enemy is killed
        end
      end
    end

    # All exploded bullets are rejected or removed from the bullets collection
    # and any dead enemy is rejected from the enemies collection.
    args.state.bullets = args.state.bullets.reject(&:exploded)
    args.state.enemies = args.state.enemies.reject(&:dead)
  end

  # Bullets are rejected from bullets collection once their position exceeds the width of screen
  def remove_bullets_of_screen args
    args.state.bullets = args.state.bullets.reject { |bullet| bullet.x > 1280 } # screen width is 1280
  end

  # Calls fire_bullet method
  def process_inputs args
    fire_bullet args
  end

  # Once mouse is clicked by the user to fire a bullet, a new bullet is added to bullets collection
  def fire_bullet args
    return unless args.inputs.mouse.click # return unless mouse is clicked
    args.state.bullets << args.state.new_entity(:bullet) do |bullet| # new bullet is declared a new entity
      bullet.y = args.inputs.mouse.click.point.y # set to the y value of where the mouse was clicked
      bullet.x = 0 # starts on the left side of the screen
      bullet.size = 10
      bullet.speed = 10 * rand + 2 # speed of a bullet is randomized
      bullet.rect = [bullet.x, bullet.y, bullet.size, bullet.size] # definition is set
    end
  end

  def tick_instructions args, text, y = 715
    return if args.state.key_event_occurred
    if args.inputs.mouse.click ||
       args.inputs.keyboard.directional_vector ||
       args.inputs.keyboard.key_down.enter ||
       args.inputs.keyboard.key_down.space ||
       args.inputs.keyboard.key_down.escape
      args.state.key_event_occurred = true
    end

    args.outputs.debug << [0, y - 50, 1280, 60].solid
    args.outputs.debug << [640, y, text, 1, 1, 255, 255, 255].label
    args.outputs.debug << [640, y - 25, "(click to dismiss instructions)" , -2, 1, 255, 255, 255].label
  end

```

### Box Collision - main.rb
```ruby
  # ./samples/04_physics_and_collisions/04_box_collision/app/main.rb
  =begin

   APIs listing that haven't been encountered in previous sample apps:

   - first: Returns the first element of the array.
     For example, if we have an array
     numbers = [1, 2, 3, 4, 5]
     and we call first by saying
     numbers.first
     the number 1 will be returned because it is the first element of the numbers array.

   - num1.idiv(num2): Divides two numbers and returns an integer.
     For example,
     16.idiv(3) = 5, because 16 / 3 is 5.33333 returned as an integer.
     16.idiv(4) = 4, because 16 / 4 is 4 and already has no decimal.

   Reminders:

   - find_all: Finds all values that satisfy specific requirements.

   - ARRAY#intersect_rect?: An array with at least four values is
     considered a rect. The intersect_rect? function returns true
     or false depending on if the two rectangles intersect.

   - reject: Removes elements from a collection if they meet certain requirements.

  =end

  # This sample app allows users to create tiles and place them anywhere on the screen as obstacles.
  # The player can then move and maneuver around them.

  class PoorManPlatformerPhysics
    attr_accessor :grid, :inputs, :state, :outputs

    # Calls all methods necessary for the app to run successfully.
    def tick
      defaults
      render
      calc
      process_inputs
    end

    # Sets default values for variables.
    # The ||= sign means that the variable will only be set to the value following the = sign if the value has
    # not already been set before. Intialization happens only in the first frame.
    def defaults
      state.tile_size               = 64
      state.gravity                 = -0.2
      state.previous_tile_size    ||= state.tile_size
      state.x                     ||= 0
      state.y                     ||= 800
      state.dy                    ||= 0
      state.dx                    ||= 0
      state.world                 ||= []
      state.world_lookup          ||= {}
      state.world_collision_rects ||= []
    end

    # Outputs solids and borders of different colors for the world and collision_rects collections.
    def render

      # Sets a black background on the screen (Comment this line out and the background will become white.)
      # Also note that black is the default color for when no color is assigned.
      outputs.solids << grid.rect

      # The position, size, and color (white) are set for borders given to the world collection.
      # Try changing the color by assigning different numbers (between 0 and 255) to the last three parameters.
      outputs.borders << state.world.map do |x, y|
        [x * state.tile_size,
         y * state.tile_size,
         state.tile_size,
         state.tile_size, 255, 255, 255]
      end

      # The top, bottom, and sides of the borders for collision_rects are different colors.
      outputs.borders << state.world_collision_rects.map do |e|
        [
          [e[:top],                             0, 170,   0], # top is a shade of green
          [e[:bottom],                          0, 100, 170], # bottom is a shade of greenish-blue
          [e[:left_right],                    170,   0,   0], # left and right are a shade of red
        ]
      end

      # Sets the position, size, and color (a shade of green) of the borders of only the player's
      # box and outputs it. If you change the 180 to 0, the player's box will be black and you
      # won't be able to see it (because it will match the black background).
      outputs.borders << [state.x,
                          state.y,
                          state.tile_size,
                          state.tile_size,  0, 180, 0]
    end

    # Calls methods needed to perform calculations.
    def calc
      calc_world_lookup
      calc_player
    end

    # Performs calculations on world_lookup and sets values.
    def calc_world_lookup

      # If the tile size isn't equal to the previous tile size,
      # the previous tile size is set to the tile size,
      # and world_lookup hash is set to empty.
      if state.tile_size != state.previous_tile_size
        state.previous_tile_size = state.tile_size
        state.world_lookup = {} # empty hash
      end

      # return if the world_lookup hash has keys (or, in other words, is not empty)
      # return unless the world collection has values inside of it (or is not empty)
      return if state.world_lookup.keys.length > 0
      return unless state.world.length > 0

      # Starts with an empty hash for world_lookup.
      # Searches through the world and finds the coordinates that exist.
      state.world_lookup = {}
      state.world.each { |x, y| state.world_lookup[[x, y]] = true }

      # Assigns world_collision_rects for every sprite drawn.
      state.world_collision_rects =
        state.world_lookup
            .keys
            .map do |coord_x, coord_y|
              s = state.tile_size
              # multiply by tile size so the grid coordinates; sets pixel value
              # don't forget that position is denoted by bottom left corner
              # set x = coord_x or y = coord_y and see what happens!
              x = s * coord_x
              y = s * coord_y
              {
                # The values added to x, y, and s position the world_collision_rects so they all appear
                # stacked (on top of world rects) but don't directly overlap.
                # Remove these added values and mess around with the rect placement!
                args:       [coord_x, coord_y],
                left_right: [x,     y + 4, s,     s - 6], # hash keys and values
                top:        [x + 4, y + 6, s - 8, s - 6],
                bottom:     [x + 1, y - 1, s - 2, s - 8],
              }
            end
    end

    # Performs calculations to change the x and y values of the player's box.
    def calc_player

      # Since acceleration is the change in velocity, the change in y (dy) increases every frame.
      # What goes up must come down because of gravity.
      state.dy += state.gravity

      # Calls the calc_box_collision and calc_edge_collision methods.
      calc_box_collision
      calc_edge_collision

      # Since velocity is the change in position, the change in y increases by dy. Same with x and dx.
      state.y += state.dy
      state.x += state.dx

      # Scales dx down.
      state.dx *= 0.8
    end

    # Calls methods needed to determine collisions between player and world_collision rects.
    def calc_box_collision
      return unless state.world_lookup.keys.length > 0 # return unless hash has atleast 1 key
      collision_floor!
      collision_left!
      collision_right!
      collision_ceiling!
    end

    # Finds collisions between the bottom of the player's rect and the top of a world_collision_rect.
    def collision_floor!
      return unless state.dy <= 0 # return unless player is going down or is as far down as possible
      player_rect = [state.x, state.y - 0.1, state.tile_size, state.tile_size] # definition of player

      # Goes through world_collision_rects to find all intersections between the bottom of player's rect and
      # the top of a world_collision_rect (hence the "-0.1" above)
      floor_collisions = state.world_collision_rects
                             .find_all { |r| r[:top].intersect_rect?(player_rect, collision_tollerance) }
                             .first

      return unless floor_collisions # return unless collision occurred
      state.y = floor_collisions[:top].top # player's y is set to the y of the top of the collided rect
      state.dy = 0 # if a collision occurred, the player's rect isn't moving because its path is blocked
    end

    # Finds collisions between the player's left side and the right side of a world_collision_rect.
    def collision_left!
      return unless state.dx < 0 # return unless player is moving left
      player_rect = [state.x - 0.1, state.y, state.tile_size, state.tile_size]

      # Goes through world_collision_rects to find all intersections beween the player's left side and the
      # right side of a world_collision_rect.
      left_side_collisions = state.world_collision_rects
                                 .find_all { |r| r[:left_right].intersect_rect?(player_rect, collision_tollerance) }
                                 .first

      return unless left_side_collisions # return unless collision occurred

      # player's x is set to the value of the x of the collided rect's right side
      state.x = left_side_collisions[:left_right].right
      state.dx = 0 # player isn't moving left because its path is blocked
    end

    # Finds collisions between the right side of the player and the left side of a world_collision_rect.
    def collision_right!
      return unless state.dx > 0 # return unless player is moving right
      player_rect = [state.x + 0.1, state.y, state.tile_size, state.tile_size]

      # Goes through world_collision_rects to find all intersections between the player's right side
      # and the left side of a world_collision_rect (hence the "+0.1" above)
      right_side_collisions = state.world_collision_rects
                                  .find_all { |r| r[:left_right].intersect_rect?(player_rect, collision_tollerance) }
                                  .first

      return unless right_side_collisions # return unless collision occurred

      # player's x is set to the value of the collided rect's left, minus the size of a rect
      # tile size is subtracted because player's position is denoted by bottom left corner
      state.x = right_side_collisions[:left_right].left - state.tile_size
      state.dx = 0 # player isn't moving right because its path is blocked
    end

    # Finds collisions between the top of the player's rect and the bottom of a world_collision_rect.
    def collision_ceiling!
      return unless state.dy > 0 # return unless player is moving up
      player_rect = [state.x, state.y + 0.1, state.tile_size, state.tile_size]

      # Goes through world_collision_rects to find intersections between the bottom of a
      # world_collision_rect and the top of the player's rect (hence the "+0.1" above)
      ceil_collisions = state.world_collision_rects
                            .find_all { |r| r[:bottom].intersect_rect?(player_rect, collision_tollerance) }
                            .first

      return unless ceil_collisions # return unless collision occurred

      # player's y is set to the bottom y of the rect it collided with, minus the size of a rect
      state.y = ceil_collisions[:bottom].y - state.tile_size
      state.dy = 0 # if a collision occurred, the player isn't moving up because its path is blocked
    end

    # Makes sure the player remains within the screen's dimensions.
    def calc_edge_collision

      #Ensures that the player doesn't fall below the map.
      if state.y < 0
        state.y = 0
        state.dy = 0

      #Ensures that the player doesn't go too high.
      # Position of player is denoted by bottom left hand corner, which is why we have to subtract the
      # size of the player's box (so it remains visible on the screen)
      elsif state.y > 720 - state.tile_size # if the player's y position exceeds the height of screen
        state.y = 720 - state.tile_size # the player will remain as high as possible while staying on screen
        state.dy = 0
      end

      # Ensures that the player remains in the horizontal range that it is supposed to.
      if state.x >= 1280 - state.tile_size && state.dx > 0 # if player moves too far right
        state.x = 1280 - state.tile_size # player will remain as right as possible while staying on screen
        state.dx = 0
      elsif state.x <= 0 && state.dx < 0 # if player moves too far left
        state.x = 0 # player will remain as left as possible while remaining on screen
        state.dx = 0
      end
    end

    # Processes input from the user on the keyboard.
    def process_inputs
      if inputs.mouse.down
        state.world_lookup = {}
        x, y = to_coord inputs.mouse.down.point  # gets x, y coordinates for the grid

        if state.world.any? { |loc| loc == [x, y] }  # checks if coordinates duplicate
          state.world = state.world.reject { |loc| loc == [x, y] }  # erases tile space
        else
          state.world << [x, y] # If no duplicates, adds to world collection
        end
      end

      # Sets dx to 0 if the player lets go of arrow keys.
      if inputs.keyboard.key_up.right
        state.dx = 0
      elsif inputs.keyboard.key_up.left
        state.dx = 0
      end

      # Sets dx to 3 in whatever direction the player chooses.
      if inputs.keyboard.key_held.right # if right key is pressed
        state.dx =  3
      elsif inputs.keyboard.key_held.left # if left key is pressed
        state.dx = -3
      end

      #Sets dy to 5 to make the player ~fly~ when they press the space bar
      if inputs.keyboard.key_held.space
        state.dy = 5
      end
    end

    def to_coord point

      # Integer divides (idiv) point.x to turn into grid
      # Then, you can just multiply each integer by state.tile_size later so the grid coordinates.
      [point.x.idiv(state.tile_size), point.y.idiv(state.tile_size)]
    end

    # Represents the tolerance for a collision between the player's rect and another rect.
    def collision_tollerance
      0.0
    end
  end

  $platformer_physics = PoorManPlatformerPhysics.new

  def tick args
    $platformer_physics.grid    = args.grid
    $platformer_physics.inputs  = args.inputs
    $platformer_physics.state    = args.state
    $platformer_physics.outputs = args.outputs
    $platformer_physics.tick
    tick_instructions args, "Sample app shows platformer collisions. CLICK to place box. ARROW keys to move around. SPACE to jump."
  end

  def tick_instructions args, text, y = 715
    return if args.state.key_event_occurred
    if args.inputs.mouse.click ||
       args.inputs.keyboard.directional_vector ||
       args.inputs.keyboard.key_down.enter ||
       args.inputs.keyboard.key_down.escape
      args.state.key_event_occurred = true
    end

    args.outputs.debug << [0, y - 50, 1280, 60].solid
    args.outputs.debug << [640, y, text, 1, 1, 255, 255, 255].label
    args.outputs.debug << [640, y - 25, "(click to dismiss instructions)" , -2, 1, 255, 255, 255].label
  end

```

### Box Collision 2 - main.rb
```ruby
  # ./samples/04_physics_and_collisions/05_box_collision_2/app/main.rb
  =begin
   APIs listing that haven't been encountered in previous sample apps:

   - times: Performs an action a specific number of times.
     For example, if we said
     5.times puts "Hello DragonRuby",
     then we'd see the words "Hello DragonRuby" printed on the console 5 times.

   - split: Divides a string into substrings based on a delimiter.
     For example, if we had a command
     "DragonRuby is awesome".split(" ")
     then the result would be
     ["DragonRuby", "is", "awesome"] because the words are separated by a space delimiter.

   - join: Opposite of split; converts each element of array to a string separated by delimiter.
     For example, if we had a command
     ["DragonRuby","is","awesome"].join(" ")
     then the result would be
     "DragonRuby is awesome".

   Reminders:

   - to_s: Returns a string representation of an object.
     For example, if we had
     500.to_s
     the string "500" would be returned.
     Similar to to_i, which returns an integer representation of an object.

   - elapsed_time: How many frames have passed since the click event.

   - args.outputs.labels: An array. Values in the array generate labels on the screen.
     The parameters are: [X, Y, TEXT, SIZE, ALIGN, RED, GREEN, BLUE, ALPHA, FONT STYLE]
     For more information about labels, go to mygame/documentation/02-labels.md.

   - inputs.mouse.down: Determines whether or not the mouse is being pressed down.
     The position of the mouse when it is pressed down can be found using inputs.mouse.down.point.(x|y).

   - first: Returns the first element of the array.

   - num1.idiv(num2): Divides two numbers and returns an integer.

   - find_all: Finds all values that satisfy specific requirements.

   - ARRAY#intersect_rect?: Returns true or false depending on if two rectangles intersect.

   - reject: Removes elements from a collection if they meet certain requirements.

   - String interpolation: Uses #{} syntax; everything between the #{ and the } is evaluated
     as Ruby code, and the placeholder is replaced with its corresponding value or result.

  =end

  MAP_FILE_PATH = 'app/map.txt' # the map.txt file in the app folder contains exported map

  class MetroidvaniaStarter
    attr_accessor :grid, :inputs, :state, :outputs, :gtk

    # Calls methods needed to run the game properly.
    def tick
      defaults
      render
      calc
      process_inputs
    end

    # Sets all the default variables.
    # '||' states that initialization occurs only in the first frame.
    def defaults
      state.tile_size                = 64
      state.gravity                  = -0.2
      state.player_width             = 60
      state.player_height            = 64
      state.collision_tolerance      = 0.0
      state.previous_tile_size     ||= state.tile_size
      state.x                      ||= 0
      state.y                      ||= 800
      state.dy                     ||= 0
      state.dx                     ||= 0
      attempt_load_world_from_file
      state.world_lookup           ||= { }
      state.world_collision_rects  ||= []
      state.mode                   ||= :creating # alternates between :creating and :selecting for sprite selection
      state.select_menu            ||= [0, 720, 1280, 720]
      #=======================================IMPORTANT=======================================#
      # When adding sprites, please label them "image1.png", "image2.png", image3".png", etc.
      # Once you have done that, adjust "state.sprite_quantity" to how many sprites you have.
      #=======================================================================================#
      state.sprite_quantity        ||= 20 # IMPORTANT TO ALTER IF SPRITES ADDED IF YOU ADD MORE SPRITES
      state.sprite_coords          ||= []
      state.banner_coords          ||= [640, 680 + 720]
      state.sprite_selected        ||= 1
      state.map_saved_at           ||= 0

      # Sets all the cordinate values for the sprite selection screen into a grid
      # Displayed when 's' is pressed by player to access sprites
      if state.sprite_coords == [] # if sprite_coords is an empty array
        count = 1
        temp_x = 165 # sets a starting x and y position for display
        temp_y = 500 + 720
        state.sprite_quantity.times do # for the number of sprites you have
          state.sprite_coords += [[temp_x, temp_y, count]] # add element to sprite_coords array
          temp_x += 100 # increment temp_x
          count += 1 # increment count
          if temp_x > 1280 - (165 + 50) # if exceeding specific horizontal width on screen
            temp_x = 165 # a new row of sprites starts
            temp_y -= 75 # new row of sprites starts 75 units lower than the previous row
          end
        end
      end
    end

    # Places sprites
    def render

      # Sets the x, y, width, height, and image path for each sprite in the world collection.
      outputs.sprites << state.world.map do |x, y, sprite|
        [x * state.tile_size, # multiply by size so grid coordinates; pixel value of location
         y * state.tile_size,
         state.tile_size,
         state.tile_size,
         'sprites/image' + sprite.to_s + '.png'] # uses concatenation to create unique image path
      end

      # Outputs sprite for the player by setting x, y, width, height, and image path
      outputs.sprites << [state.x,
                          state.y,
                          state.player_width,
                          state.player_height,'sprites/player.png']

      # Outputs labels as primitives in top right of the screen
      outputs.primitives << [920, 700, 'Press \'s\' to access sprites.', 1, 0].label
      outputs.primitives << [920, 675, 'Click existing sprite to delete.', 1, 0].label

      outputs.primitives << [920, 640, '<- and -> to move.', 1, 0].label
      outputs.primitives << [920, 615, 'Press and hold space to jump.', 1, 0].label

      outputs.primitives << [920, 580, 'Press \'e\' to export current map.', 1, 0].label

      # if the map is saved and less than 120 frames have passed, the label is displayed
      if state.map_saved_at > 0 && state.map_saved_at.elapsed_time < 120
        outputs.primitives << [920, 555, 'Map has been exported!', 1, 0, 50, 100, 50].label
      end

      # If player hits 's', following appears
      if state.mode == :selecting
        # White background for sprite selection
        outputs.primitives << [state.select_menu, 255, 255, 255].solid

        # Select tile label at the top of the screen
        outputs.primitives << [state.banner_coords.x, state.banner_coords.y, "Select Sprite (sprites located in \"sprites\" folder)", 10, 1, 0, 0, 0, 255].label

        # Places sprites in locations calculated in the defaults function
        outputs.primitives << state.sprite_coords.map do |x, y, order|
          [x, y, 50, 50, 'sprites/image' + order.to_s + ".png"].sprite
        end
      end

      # Creates sprite following mouse to help indicate which sprite you have selected
      # 10 is subtracted from the mouse's x position so that the sprite is not covered by the mouse icon
      outputs.primitives << [inputs.mouse.position.x - 10, inputs.mouse.position.y,
                             10, 10, 'sprites/image' + state.sprite_selected.to_s + ".png"].sprite
    end

    # Calls methods that perform calculations
    def calc
      calc_in_game
      calc_sprite_selection
    end

    # Calls methods that perform calculations (if in creating mode)
    def calc_in_game
      return unless state.mode == :creating
      calc_world_lookup
      calc_player
    end

    def calc_world_lookup
      # If the tile size isn't equal to the previous tile size,
      # the previous tile size is set to the tile size,
      # and world_lookup hash is set to empty.
      if state.tile_size != state.previous_tile_size
        state.previous_tile_size = state.tile_size
        state.world_lookup = {}
      end

      # return if world_lookup is not empty or if world is empty
      return if state.world_lookup.keys.length > 0
      return unless state.world.length > 0

      # Searches through the world and finds the coordinates that exist
      state.world_lookup = {}
      state.world.each { |x, y| state.world_lookup[[x, y]] = true }

      # Assigns collision rects for every sprite drawn
      state.world_collision_rects =
        state.world_lookup
             .keys
             .map do |coord_x, coord_y|
               s = state.tile_size
               # Multiplying by s (the size of a tile) ensures that the rect is
               # placed exactly where you want it to be placed (causes grid to coordinate)
               # How many pixels horizontally across and vertically up and down
               x = s * coord_x
               y = s * coord_y
               {
                 args:       [coord_x, coord_y],
                 left_right: [x,     y + 4, s,     s - 6], # hash keys and values
                 top:        [x + 4, y + 6, s - 8, s - 6],
                 bottom:     [x + 1, y - 1, s - 2, s - 8],
               }
             end
    end

    # Calculates movement of player and calls methods that perform collision calculations
    def calc_player
      state.dy += state.gravity  # what goes up must come down because of gravity
      calc_box_collision
      calc_edge_collision
      state.y  += state.dy       # Since velocity is the change in position, the change in y increases by dy
      state.x  += state.dx       # Ditto line above but dx and x
      state.dx *= 0.8            # Scales dx down
    end

    # Calls methods that determine whether the player collides with any world_collision_rects.
    def calc_box_collision
      return unless state.world_lookup.keys.length > 0 # return unless hash has atleast 1 key
      collision_floor
      collision_left
      collision_right
      collision_ceiling
    end

    # Finds collisions between the bottom of the player's rect and the top of a world_collision_rect.
    def collision_floor
      return unless state.dy <= 0 # return unless player is going down or is as far down as possible
      player_rect = [state.x, next_y, state.tile_size, state.tile_size] # definition of player

      # Runs through all the sprites on the field and finds all intersections between player's
      # bottom and the top of a rect.
      floor_collisions = state.world_collision_rects
                           .find_all { |r| r[:top].intersect_rect?(player_rect, state.collision_tolerance) }
                           .first

      return unless floor_collisions # performs following changes if a collision has occurred
      state.y = floor_collisions[:top].top # y of player is set to the y of the colliding rect's top
      state.dy = 0 # no change in y because the player's path is blocked
    end

    # Finds collisions between the player's left side and the right side of a world_collision_rect.
    def collision_left
      return unless state.dx < 0 # return unless player is moving left
      player_rect = [next_x, state.y, state.tile_size, state.tile_size]

      # Runs through all the sprites on the field and finds all intersections between the player's left side
      # and the right side of a rect.
      left_side_collisions = state.world_collision_rects
                               .find_all { |r| r[:left_right].intersect_rect?(player_rect, state.collision_tolerance) }
                               .first

      return unless left_side_collisions # return unless collision occurred
      state.x = left_side_collisions[:left_right].right # sets player's x to the x of the colliding rect's right side
      state.dx = 0 # no change in x because the player's path is blocked
    end

    # Finds collisions between the right side of the player and the left side of a world_collision_rect.
    def collision_right
      return unless state.dx > 0 # return unless player is moving right
      player_rect = [next_x, state.y, state.tile_size, state.tile_size]

      # Runs through all the sprites on the field and finds all intersections between the  player's
      # right side and the left side of a rect.
      right_side_collisions = state.world_collision_rects
                                .find_all { |r| r[:left_right].intersect_rect?(player_rect, state.collision_tolerance) }
                                .first

      return unless right_side_collisions # return unless collision occurred
      state.x = right_side_collisions[:left_right].left - state.tile_size # player's x is set to the x of colliding rect's left side (minus tile size since x is the player's bottom left corner)
      state.dx = 0 # no change in x because the player's path is blocked
    end

    # Finds collisions between the top of the player's rect and the bottom of a world_collision_rect.
    def collision_ceiling
      return unless state.dy > 0 # return unless player is moving up
      player_rect = [state.x, next_y, state.player_width, state.player_height]

      # Runs through all the sprites on the field and finds all intersections between the player's top
      # and the bottom of a rect.
      ceil_collisions = state.world_collision_rects
                          .find_all { |r| r[:bottom].intersect_rect?(player_rect, state.collision_tolerance) }
                          .first

      return unless ceil_collisions # return unless collision occurred
      state.y = ceil_collisions[:bottom].y - state.tile_size # player's y is set to the y of the colliding rect's bottom (minus tile size)
      state.dy = 0 # no change in y because the player's path is blocked
    end

    # Makes sure the player remains within the screen's dimensions.
    def calc_edge_collision
      # Ensures that player doesn't fall below the map
      if next_y < 0 && state.dy < 0 # if player is moving down and is about to fall (next_y) below the map's scope
        state.y = 0 # 0 is the lowest the player can be while staying on the screen
        state.dy = 0
      # Ensures player doesn't go insanely high
      elsif next_y > 720 - state.tile_size && state.dy > 0 # if player is moving up, about to exceed map's scope
        state.y = 720 - state.tile_size # if we don't subtract tile_size, we won't be able to see the player on the screen
        state.dy = 0
      end

      # Ensures that player remains in the horizontal range its supposed to
      if state.x >= 1280 - state.tile_size && state.dx > 0 # if the player is moving too far right
        state.x = 1280 - state.tile_size # farthest right the player can be while remaining in the screen's scope
        state.dx = 0
      elsif state.x <= 0 && state.dx < 0 # if the player is moving too far left
        state.x = 0 # farthest left the player can be while remaining in the screen's scope
        state.dx = 0
      end
    end

    def calc_sprite_selection
      # Does the transition to bring down the select sprite screen
      if state.mode == :selecting && state.select_menu.y != 0
        state.select_menu.y = 0  # sets y position of select menu (shown when 's' is pressed)
        state.banner_coords.y = 680 # sets y position of Select Sprite banner
        state.sprite_coords = state.sprite_coords.map do |x, y, w, h|
          [x, y - 720, w, h] # sets definition of sprites (change '-' to '+' and the sprites can't be seen)
        end
      end

      # Does the transition to leave the select sprite screen
      if state.mode == :creating  && state.select_menu.y != 720
        state.select_menu.y = 720 # sets y position of select menu (menu is retreated back up)
        state.banner_coords.y = 1000 # sets y position of Select Sprite banner
        state.sprite_coords = state.sprite_coords.map do |x, y, w, h|
          [x, y + 720, w, h] # sets definition of all elements in collection
        end
      end
    end

    def process_inputs
      # If the state.mode is back and if the menu has retreated back up
      # call methods that process user inputs
      if state.mode == :creating
        process_inputs_player_movement
        process_inputs_place_tile
      end

      # For each sprite_coordinate added, check what sprite was selected
      if state.mode == :selecting
        state.sprite_coords.map do |x, y, order| # goes through all sprites in collection
          # checks that a specific sprite was pressed based on x, y position
          if inputs.mouse.down && # the && (and) sign means ALL statements must be true for the evaluation to be true
             inputs.mouse.down.point.x >= x      && # x is greater than or equal to sprite's x and
             inputs.mouse.down.point.x <= x + 50 && # x is less than or equal to 50 pixels to the right
             inputs.mouse.down.point.y >= y      && # y is greater than or equal to sprite's y
             inputs.mouse.down.point.y <= y + 50 # y is less than or equal to 50 pixels up
            state.sprite_selected = order # sprite is chosen
          end
        end
      end

      inputs_export_stage
      process_inputs_show_available_sprites
    end

    # Moves the player based on the keys they press on their keyboard
    def process_inputs_player_movement
      # Sets dx to 0 if the player lets go of arrow keys (player won't move left or right)
      if inputs.keyboard.key_up.right
        state.dx = 0
      elsif inputs.keyboard.key_up.left
        state.dx = 0
      end

      # Sets dx to 3 in whatever direction the player chooses when they hold down (or press) the left or right keys
      if inputs.keyboard.key_held.right
        state.dx =  3
      elsif inputs.keyboard.key_held.left
        state.dx = -3
      end

      # Sets dy to 5 to make the player ~fly~ when they press the space bar on their keyboard
      if inputs.keyboard.key_held.space
        state.dy = 5
      end
    end

    # Adds tile in the place the user holds down the mouse
    def process_inputs_place_tile
      if inputs.mouse.down # if mouse is pressed
        state.world_lookup = {}
        x, y = to_coord inputs.mouse.down.point # gets x, y coordinates for the grid

        # Checks if any coordinates duplicate (already exist in world)
        if state.world.any? { |existing_x, existing_y, n| existing_x == x && existing_y == y }
          #erases existing tile space by rejecting them from world
          state.world = state.world.reject do |existing_x, existing_y, n|
            existing_x == x && existing_y == y
          end
        else
          state.world << [x, y, state.sprite_selected] # If no duplicates, add the sprite
        end
      end
    end

    # Stores/exports world collection's info (coordinates, sprite number) into a file
    def inputs_export_stage
      if inputs.keyboard.key_down.e # if "e" is pressed
        export_string = state.world.map do |x, y, sprite_number| # stores world info in a string
          "#{x},#{y},#{sprite_number}"                           # using string interpolation
        end
        gtk.write_file(MAP_FILE_PATH, export_string.join("\n")) # writes string into a file
        state.map_saved_at = Kernel.tick_count # frame number (passage of time) when the map was saved
      end
    end

    def process_inputs_show_available_sprites
      # Based on keyboard input, the entity (:creating and :selecting) switch
      if inputs.keyboard.key_held.s && state.mode == :creating # if "s" is pressed and currently creating
        state.mode = :selecting # will change to selecting
        inputs.keyboard.clear # VERY IMPORTANT! If not present, it'll flicker between on and off
      elsif inputs.keyboard.key_held.s && state.mode == :selecting # if "s" is pressed and currently selecting
        state.mode = :creating # will change to creating
        inputs.keyboard.clear # VERY IMPORTANT! If not present, it'll flicker between on and off
      end
    end

    # Loads the world collection by reading from the map.txt file in the app folder
    def attempt_load_world_from_file
      return if state.world # return if the world collection is already populated
      state.world ||= [] # initialized as an empty collection
      exported_world = gtk.read_file(MAP_FILE_PATH) # reads the file using the path mentioned at top of code
      return unless exported_world # return unless the file read was successful
      state.world = exported_world.each_line.map do |l| # perform action on each line of exported_world
          l.split(',').map(&:to_i) # calls split using ',' as a delimiter, and invokes .map on the collection,
                                   # calling to_i (converts to integers) on each element
      end
    end

    # Adds the change in y to y to determine the next y position of the player.
    def next_y
      state.y + state.dy
    end

    # Determines next x position of player
    def next_x
      if state.dx < 0 # if the player moves left
        return state.x - (state.tile_size - state.player_width) # subtracts since the change in x is negative (player is moving left)
      else
        return state.x + (state.tile_size - state.player_width) # adds since the change in x is positive (player is moving right)
      end
    end

    def to_coord point
      # Integer divides (idiv) point.x to turn into grid
      # Then, you can just multiply each integer by state.tile_size
      # later and huzzah. Grid coordinates
      [point.x.idiv(state.tile_size), point.y.idiv(state.tile_size)]
    end
  end

  $metroidvania_starter = MetroidvaniaStarter.new

  def tick args
      $metroidvania_starter.grid    = args.grid
      $metroidvania_starter.inputs  = args.inputs
      $metroidvania_starter.state   = args.state
      $metroidvania_starter.outputs = args.outputs
      $metroidvania_starter.gtk     = DR
      $metroidvania_starter.tick
  end

```

### Box Collision 3 - main.rb
```ruby
  # ./samples/04_physics_and_collisions/06_box_collision_3/app/main.rb
  class Game
    attr_dr

    def tick
      defaults
      render
      input_edit_map
      input_player
      calc_player
    end

    def defaults
      state.gravity           = -0.4
      state.drag              = 0.15
      state.tile_size         = 32
      state.player.size       = 16
      state.player.jump_power = 12

      state.tiles                 ||= []
      state.player.y              ||= 800
      state.player.x              ||= 100
      state.player.dy             ||= 0
      state.player.dx             ||= 0
      state.player.jumped_down_at ||= 0
      state.player.jumped_at      ||= 0

      calc_player_rect if !state.player.rect
    end

    def render
      outputs.labels << [10, 10.from_top, "tile: click to add a tile, hold X key and click to delete a tile."]
      outputs.labels << [10, 35.from_top, "move: use left and right to move, space to jump, down and space to jump down."]
      outputs.labels << [10, 55.from_top, "      You can jump through or jump down through tiles with a height of 1."]
      outputs.background_color = [80, 80, 80]
      outputs.sprites << tiles.map(&:sprite)
      outputs.sprites << (player.rect.merge path: 'sprites/square/green.png')

      mouse_overlay = {
        x: (inputs.mouse.x.ifloor state.tile_size),
        y: (inputs.mouse.y.ifloor state.tile_size),
        w: state.tile_size,
        h: state.tile_size,
        a: 100
      }

      mouse_overlay = mouse_overlay.merge r: 255 if state.delete_mode

      if state.mouse_held
        outputs.primitives << mouse_overlay.border!
      else
        outputs.primitives << mouse_overlay.solid!
      end
    end

    def input_edit_map
      state.mouse_held = true  if inputs.mouse.down
      state.mouse_held = false if inputs.mouse.up

      if inputs.keyboard.x
        state.delete_mode = true
      elsif inputs.keyboard.key_up.x
        state.delete_mode = false
      end

      return unless state.mouse_held

      ordinal = { x: (inputs.mouse.x.idiv state.tile_size),
                  y: (inputs.mouse.y.idiv state.tile_size) }

      found = find_tile ordinal
      if !found && !state.delete_mode
        tiles << (state.new_entity :tile, ordinal)
        recompute_tiles
      elsif found && state.delete_mode
        tiles.delete found
        recompute_tiles
      end
    end

    def input_player
      player.dx += inputs.left_right

      if inputs.keyboard.key_down.space && inputs.keyboard.down
        player.dy             = player.jump_power * -1
        player.jumped_at      = 0
        player.jumped_down_at = Kernel.tick_count
      elsif inputs.keyboard.key_down.space
        player.dy             = player.jump_power
        player.jumped_at      = Kernel.tick_count
        player.jumped_down_at = 0
      end
    end

    def calc_player
      calc_player_rect
      calc_below
      calc_left
      calc_right
      calc_above
      calc_player_dy
      calc_player_dx
      reset_player if player_off_stage?
    end

    def calc_player_rect
      player.rect      = current_player_rect
      player.next_rect = player.rect.merge x: player.x + player.dx,
                                           y: player.y + player.dy
      player.prev_rect = player.rect.merge x: player.x - player.dx,
                                           y: player.y - player.dy
    end

    def calc_below
      return unless player.dy <= 0
      tiles_below = find_tiles { |t| t.rect.top <= player.prev_rect.y }
      collision = find_colliding_tile tiles_below, (player.rect.merge y: player.next_rect.y)
      return unless collision
      if collision.neighbors.b == :none && player.jumped_down_at.elapsed_time < 10
        player.dy = -1
      else
        player.y  = collision.rect.y + state.tile_size
        player.dy = 0
      end
    end

    def calc_left
      return unless player.dx < 0
      tiles_left = find_tiles { |t| t.rect.right <= player.prev_rect.left }
      collision = find_colliding_tile tiles_left, (player.rect.merge x: player.next_rect.x)
      return unless collision
      player.x  = collision.rect.right
      player.dx = 0
    end

    def calc_right
      return unless player.dx > 0
      tiles_right = find_tiles { |t| t.rect.left >= player.prev_rect.right }
      collision = find_colliding_tile tiles_right, (player.rect.merge x: player.next_rect.x)
      return unless collision
      player.x  = collision.rect.left - player.rect.w
      player.dx = 0
    end

    def calc_above
      return unless player.dy > 0
      tiles_above = find_tiles { |t| t.rect.y >= player.prev_rect.y }
      collision = find_colliding_tile tiles_above, (player.rect.merge y: player.next_rect.y)
      return unless collision
      return if collision.neighbors.t == :none
      player.dy = 0
      player.y  = collision.rect.bottom - player.rect.h
    end

    def calc_player_dx
      player.dx  = player.dx.clamp(-5,  5)
      player.dx *= 0.9
      player.x  += player.dx
    end

    def calc_player_dy
      player.y  += player.dy
      player.dy += state.gravity
      player.dy += player.dy * state.drag ** 2 * -1
    end

    def reset_player
      player.x  = 100
      player.y  = 720
      player.dy = 0
    end

    def recompute_tiles
      tiles.each do |t|
        t.w = state.tile_size
        t.h = state.tile_size
        t.neighbors = tile_neighbors t, tiles

        t.rect = [t.x * state.tile_size,
                  t.y * state.tile_size,
                  state.tile_size,
                  state.tile_size].rect.to_hash

        sprite_sub_path = t.neighbors.mask.map { |m| flip_bit m }.join("")

        t.sprite = {
          x: t.x * state.tile_size,
          y: t.y * state.tile_size,
          w: state.tile_size,
          h: state.tile_size,
          path: "sprites/tile/wall-#{sprite_sub_path}.png"
        }
      end
    end

    def flip_bit bit
      return 0 if bit == 1
      return 1
    end

    def player
      state.player
    end

    def player_off_stage?
      player.rect.top < grid.bottom ||
      player.rect.right < grid.left ||
      player.rect.left > grid.right
    end

    def current_player_rect
      { x: player.x, y: player.y, w: player.size, h: player.size }
    end

    def tiles
      state.tiles
    end

    def find_tile ordinal
      tiles.find { |t| t.x == ordinal.x && t.y == ordinal.y }
    end

    def find_tiles &block
      tiles.find_all(&block)
    end

    def find_colliding_tile tiles, target
      tiles.find { |t| t.rect.intersect_rect? target }
    end

    def tile_neighbors tile, other_points
      t = find_tile x: tile.x + 0, y: tile.y + 1
      r = find_tile x: tile.x + 1, y: tile.y + 0
      b = find_tile x: tile.x + 0, y: tile.y - 1
      l = find_tile x: tile.x - 1, y: tile.y + 0

      tile_t, tile_r, tile_b, tile_l = 0

      tile_t = 1 if t
      tile_r = 1 if r
      tile_b = 1 if b
      tile_l = 1 if l

      state.new_entity :neighbors, mask: [tile_t, tile_r, tile_b, tile_l],
                                   t:    t ? :some : :none,
                                   b:    b ? :some : :none,
                                   l:    l ? :some : :none,
                                   r:    r ? :some : :none
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

```

### Jump Physics - main.rb
```ruby
  # ./samples/04_physics_and_collisions/07_jump_physics/app/main.rb
  =begin

   Reminders:

   - args.state.new_entity: Used when we want to create a new object, like a sprite or button.
     For example, if we want to create a new button, we would declare it as a new entity and
     then define its properties. (Remember, you can use state to define ANY property and it will
     be retained across frames.)

   - args.outputs.solids: An array. The values generate a solid.
     The parameters for a solid are [X, Y, WIDTH, HEIGHT, RED, GREEN, BLUE]
     For more information about solids, go to mygame/documentation/03-solids-and-borders.md.

   - num1.greater(num2): Returns the greater value.

   - Hashes: Collection of unique keys and their corresponding values. The value can be found
     using their keys.

   - ARRAY#inside_rect?: Returns true or false depending on if the point is inside the rect.

  =end

  # This sample app is a game that requires the user to jump from one platform to the next.
  # As the player successfully clears platforms, they become smaller and move faster.

  class VerticalPlatformer
    attr_dr

    # declares vertical platformer as new entity
    def s
      state.vertical_platformer ||= state.new_entity(:vertical_platformer)
      state.vertical_platformer
    end

    # creates a new platform using a hash
    def new_platform hash
      s.new_entity_strict(:platform, hash) # platform key
    end

    # calls methods needed for game to run properly
    def tick
      defaults
      render
      calc
      input
    end

    def init_game
      s.platforms ||= [ # initializes platforms collection with two platforms using hashes
        new_platform(x: 0, y: 0, w: 700, h: 32, dx: 1, speed: 0, rect: nil),
        new_platform(x: 0, y: 300, w: 700, h: 32, dx: 1, speed: 0, rect: nil), # 300 pixels higher
      ]

      s.tick_count  = Kernel.tick_count
      s.gravity     = -0.3 # what goes up must come down because of gravity
      s.player.platforms_cleared ||= 0 # counts how many platforms the player has successfully cleared
      s.player.x  ||= 0           # sets player values
      s.player.y  ||= 100
      s.player.w  ||= 64
      s.player.h  ||= 64
      s.player.dy ||= 0           # change in position
      s.player.dx ||= 0
      s.player_jump_power           = 15
      s.player_jump_power_duration  = 10
      s.player_max_run_speed        = 5
      s.player_speed_slowdown_rate  = 0.9
      s.player_acceleration         = 1
      s.camera ||= { y: -100 } # shows view on screen (as the player moves upward, the camera does too)
    end

    # Sets default values
    def defaults
      init_game
    end

    # Outputs objects onto the screen
    def render
      outputs.solids << s.platforms.map do |p| # outputs platforms onto screen
        [p.x + 300, p.y - s.camera[:y], p.w, p.h] # add 300 to place platform in horizontal center
        # don't forget, position of platform is denoted by bottom left hand corner
      end

      # outputs player using hash
      outputs.solids << {
        x: s.player.x + 300, # player positioned on top of platform
        y: s.player.y - s.camera[:y],
        w: s.player.w,
        h: s.player.h,
        r: 100,              # color saturation
        g: 100,
        b: 200
      }
    end

    # Performs calculations
    def calc
      s.platforms.each do |p| # for each platform in the collection
        p.rect = [p.x, p.y, p.w, p.h] # set the definition
      end

      # sets player point by adding half the player's width to the player's x
      s.player.point = [s.player.x + s.player.w.half, s.player.y] # change + to - and see what happens!

      # search the platforms collection to find if the player's point is inside the rect of a platform
      collision = s.platforms.find { |p| s.player.point.inside_rect? p.rect }

      # if collision occurred and player is moving down (or not moving vertically at all)
      if collision && s.player.dy <= 0
        s.player.y = collision.rect.y + collision.rect.h - 2 # player positioned on top of platform
        s.player.dy = 0 if s.player.dy < 0 # player stops moving vertically
        if !s.player.platform
          s.player.dx = 0 # no horizontal movement
        end
        # changes horizontal position of player by multiplying collision change in x (dx) by speed and adding it to current x
        s.player.x += collision.dx * collision.speed
        s.player.platform = collision # player is on the platform that it collided with (or landed on)
        if s.player.falling # if player is falling
          s.player.dx = 0  # no horizontal movement
        end
        s.player.falling = false
        s.player.jumped_at = nil
      else
        s.player.platform = nil # player is not on a platform
        s.player.y  += s.player.dy # velocity is the change in position
        s.player.dy += s.gravity # acceleration is the change in velocity; what goes up must come down
      end

      s.platforms.each do |p| # for each platform in the collection
        p.x += p.dx * p.speed # x is incremented by product of dx and speed (causes platform to move horizontally)
        # changes platform's x so it moves left and right across the screen (between -300 and 300 pixels)
        if p.x < -300 # if platform goes too far left
          p.dx *= -1 # dx is scaled down
          p.x = -300 # as far left as possible within scope
        elsif p.x > (1000 - p.w) # if platform's x is greater than 300
          p.dx *= -1
          p.x = (1000 - p.w) # set to 300 (as far right as possible within scope)
        end
      end

      delta = (s.player.y - s.camera[:y] - 100) # used to position camera view

      if delta > -200
        s.camera[:y] += delta * 0.01 # allows player to see view as they move upwards
        s.player.x  += s.player.dx # velocity is change in position; change in x increases by dx

        # searches platform collection to find platforms located more than 300 pixels above the player
        has_platforms = s.platforms.find { |p| p.y > (s.player.y + 300) }
        if !has_platforms # if there are no platforms 300 pixels above the player
          width = 700 - (700 * (0.1 * s.player.platforms_cleared)) # the next platform is smaller than previous
          s.player.platforms_cleared += 1 # player successfully cleared another platform
          last_platform = s.platforms[-1] # platform just cleared becomes last platform
          # another platform is created 300 pixels above the last platform, and this
          # new platform has a smaller width and moves faster than all previous platforms
          s.platforms << new_platform(x: (700 - width) * rand, # random x position
                                      y: last_platform.y + 300,
                                      w: width,
                                      h: 32,
                                      dx: 1.randomize(:sign), # random change in x
                                      speed: 2 * s.player.platforms_cleared,
                                      rect: nil)
        end
      else
        # game over
        s.as_hash.clear # otherwise clear the hash (no new platform is necessary)
        init_game
      end
    end

    # Takes input from the user to move the player
    def input
      if inputs.keyboard.space # if the space bar is pressed
        s.player.jumped_at ||= s.tick_count # set to current frame

        # if the time that has passed since the jump is less than the duration of a jump (10 frames)
        # and the player is not falling
        if s.player.jumped_at.elapsed_time < s.player_jump_power_duration && !s.player.falling
          s.player.dy = s.player_jump_power # player jumps up
        end
      end

      if inputs.keyboard.key_up.space # if space bar is in "up" state
        s.player.falling = true # player is falling
      end

      if inputs.keyboard.left # if left key is pressed
        s.player.dx -= s.player_acceleration # player's position changes, decremented by acceleration
        s.player.dx = s.player.dx.greater(-s.player_max_run_speed) # dx is either current dx or -5, whichever is greater
      elsif inputs.keyboard.right # if right key is pressed
        s.player.dx += s.player_acceleration # player's position changes, incremented by acceleration
        s.player.dx  = s.player.dx.lesser(s.player_max_run_speed) # dx is either current dx or 5, whichever is lesser
      else
        s.player.dx *= s.player_speed_slowdown_rate # scales dx down
      end
    end
  end

  $game = VerticalPlatformer.new

  def tick args
    $game.args = args
    $game.tick
  end

```

### Ball And Peg Bouncing - main.rb
```ruby
  # ./samples/04_physics_and_collisions/08_ball_and_peg_bouncing/app/main.rb
  class Game
    attr_dr

    def tick
      defaults
      render
      calc
    end

    def defaults
      state.player ||= { x: 640,
                         y: 720 - 64,
                         dy: 0,
                         dx: 0,
                         radius: 20 }

      state.pegs ||= [
        { x: 620, y: 360, radius: 20 },
        { x: 920, y: 416, radius: 20 },
      ]

      state.gravity ||= 0.5
    end

    def render
      outputs.background_color = [0, 0, 0]
      outputs.sprites << circle_prefab(player, "sprites/circle/blue.png")
      outputs.sprites << state.pegs.map { |peg| circle_prefab(peg, "sprites/circle/red.png") }
    end

    def calc
      player.dy -= state.gravity
      player.dy = player.dy.clamp(-15, 15)
      player.x += player.dx
      player.y += player.dy

      if player.y < 0 || player.x < 0 || player.x > 1280
        player.dx = 0
        player.dy = 0
        player.x = 640
        player.y = 720 - 64
      end

      collision = state.pegs.find do |peg|
        Geometry.intersect_circle? player, peg
      end

      if collision
        distance =   Geometry.distance player, collision
        force = Geometry.vec2_subtract collision, player
        normalized = Geometry.vec2_normalize force

        # "axis aligned bounding circle"
        aabc = Geometry.vec2_scale(force, -1)
        aabc = Geometry.vec2_scale(aabc, player.radius + collision.radius)
        aabc = Geometry.vec2_scale(aabc, 1 / distance)
        player.merge! Geometry.vec2_add(collision, aabc)

        reflect = Geometry.vec2_scale normalized, player.dy
        reflect = Geometry.vec2_scale reflect, 0.8
        player.dx = reflect.x
        player.dy = reflect.y
      end
    end

    def player
      state.player
    end

    def circle_prefab peg, path
      { x: peg.x,
        y: peg.y,
        w: peg.radius * 2,
        h: peg.radius * 2,
        path: path,
        anchor_x: 0.5,
        anchor_y: 0.5 }
    end
  end

  def boot args
    args.state = {}
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
  end

  DR.reset

```

### Arbitrary Collision - ball.rb
```ruby
  # ./samples/04_physics_and_collisions/09_arbitrary_collision/app/ball.rb

  class Ball
      attr_accessor :velocity, :child, :parent, :number, :leastChain
      attr_reader :x, :y, :hypotenuse, :width, :height

      def initialize args, number, leastChain, parent, child
          #Start the ball in the top center
          @number = number
          @leastChain = leastChain
          @x = args.grid.w / 2
          @y = args.grid.h - 20

          @velocity = Vector2d.new(2, -2)
          @width =  10
          @height = 10

          @left_wall = (args.state.board_width + args.grid.w / 8)
          @right_wall = @left_wall + args.state.board_width

          @max_velocity = MAX_VELOCITY

          @child = child
          @parent = parent

          @past = [{x: @x, y: @y}]
          @next = nil
      end

      def reassignLeastChain (lc=nil)
        if (lc == nil)
          lc = @number
        end
        @leastChain = lc
        if (parent != nil)
          @parent.reassignLeastChain(lc)
        end

      end

      def makeLeader args
        if isLeader
          return
        end
        @parent.reassignLeastChain
        args.state.ballParents.push(self)
        @parent = nil

      end

      def isLeader
        return (parent == nil)
      end

      def receiveNext (p)
        #trace!
        if parent != nil
          @x = p[:x]
          @y = p[:y]
          @velocity = p[:velocity]
          #puts @x.to_s + "|" + @y.to_s + "|"+@velocity.to_s
          @past.append(p)
          if (@past.length >= BALL_DISTANCE)
            if (@child != nil)
              @child.receiveNext(@past[0])
              @past.shift
            end
          end
        end
      end

      #Move the ball according to its velocity
      def update args

          if isLeader
            wallBounds args
            @x += @velocity.x
            @y += @velocity.y
            @past.append({x: @x, y: @y, velocity: @velocity})
            #puts @past

            if (@past.length >= BALL_DISTANCE)
              if (@child != nil)
                @child.receiveNext(@past[0])
                @past.shift
              end
            end

          else
            puts "unexpected"
            raise "unexpected"
          end
      end

      def wallBounds args
          b= false
          if @x < @left_wall
            @velocity.x = @velocity.x.abs() * 1
            b=true
          elsif @x + @width > @right_wall
            @velocity.x = @velocity.x.abs() * -1
            b=true
          end
          if @y < 0
            @velocity.y = @velocity.y.abs() * 1
            b=true
          elsif @y + @height > args.grid.h
            @velocity.y = @velocity.y.abs() * -1
            b=true
          end
          mag = (@velocity.x**2.0 + @velocity.y**2.0)**0.5
          if (b == true && mag < MAX_VELOCITY)
            @velocity.x*=1.1;
            @velocity.y*=1.1;
          end

      end

      #render the ball to the screen
      def draw args

          #update args
          #args.outputs.solids << [@x, @y, @width, @height, 255, 255, 0];
          #args.outputs.sprits << {
            #x: @x,
            #y: @y,
            #w: @width,
            #h: @height,
            #path: "sprites/ball10.png"
          #}
          #args.outputs.sprites <<[@x, @y, @width, @height, "sprites/ball10.png"]
          args.outputs.sprites << {x: @x, y: @y, w: @width, h: @height, path:"sprites/ball10.png" }
      end

      def getDraw args
        #wallBounds args
        #update args
        #args.outputs.labels << [@x, @y, @number.to_s + "|" + @leastChain.to_s]
        return [@x, @y, @width, @height, "sprites/ball10.png"]
      end

      def getPoints args
        points = [
          {x:@x+@width/2, y: @y},
          {x:@x+@width, y:@y+@height/2},
          {x:@x+@width/2,y:@y+@height},
          {x:@x,y:@y+@height/2}
        ]
        #psize = 5.0
        #for p in points
          #args.outputs.solids << [p.x-psize/2.0, p.y-psize/2.0, psize, psize, 0, 0, 0];
        #end
        return points
      end

      def serialize
        {x: @x, y:@y}
      end

      def inspect
        serialize.to_s
      end

      def to_s
        serialize.to_s
      end
    end

```

### Arbitrary Collision - blocks.rb
```ruby
  # ./samples/04_physics_and_collisions/09_arbitrary_collision/app/blocks.rb
  MAX_COUNT=100

  def universalUpdateOne args, shape
    didHit = false
    hitters = []
    #puts shape.to_s
    toCollide = nil
    for b in args.state.balls
      if [b.x, b.y, b.width, b.height].intersect_rect?(shape.bold)
        didSquare = false
        for s in shape.squareColliders
          if (s.collision?(args, b))
            didSquare = true
            didHit = true
            #s.collide(args, b)
            toCollide = s
            #hitter = b
            hitters.append(b)
          end #end if
        end #end for
        if (didSquare == false)
          for c in shape.colliders
            #puts args.state.ball.velocity
            if c.collision?(args, b.getPoints(args),b)
              #c.collide args, b
              toCollide = c
              didHit = true
              hitters.append(b)
            end #end if
          end #end for
        end #end if
      end#end if
    end#end for
    if (didHit)
      shape.count=0
      hitters = hitters.uniq
      for hitter in hitters
        hitter.makeLeader args
        #toCollide.collide(args, hitter)
        if shape.home == "squares"
          args.state.squares.delete(shape)
        elsif shape.home == "tshapes"
          args.state.tshapes.delete(shape)
        else shape.home == "lines"
          args.state.lines.delete(shape)
        end
      end

      #puts "HIT!" + hitter.number
    end
  end

  def universalUpdate args, shape
    #puts shape.home
    if (shape.count <= 1)
      universalUpdateOne args, shape
      return
    end

    didHit = false
    hitter = nil
    for b in args.state.ballParents
      if [b.x, b.y, b.width, b.height].intersect_rect?(shape.bold)
        didSquare = false
        for s in shape.squareColliders
          if (s.collision?(args, b))
            didSquare = true
            didHit = true
            s.collide(args, b)
            hitter = b
          end
        end
        if (didSquare == false)
          for c in shape.colliders
            #puts args.state.ball.velocity
            if c.collision?(args, b.getPoints(args),b)
              c.collide args, b
              didHit = true
              hitter = b
            end
          end
        end
      end
    end
    if (didHit)
      shape.count=shape.count-1
      shape.damageCount.append([(hitter.leastChain+1 - hitter.number)-1, Kernel.tick_count])

    end
    i=0
    while i < shape.damageCount.length
      if shape.damageCount[i][0] <= 0
        shape.damageCount.delete_at(i)
        i-=1
      elsif shape.damageCount[i][1].elapsed_time > BALL_DISTANCE and shape.damageCount[i][0] > 1
        shape.count-=1
        shape.damageCount[i][0]-=1
        shape.damageCount[i][1] = Kernel.tick_count
      end
      i+=1
    end
  end


  class Square
     attr_accessor :count, :x, :y, :home, :bold, :squareColliders, :colliders, :damageCount
     def initialize(args, x, y, block_size, orientation, block_offset)
          @x = x * block_size
          @y = y * block_size
          @block_size = block_size
          @block_offset = block_offset
          @orientation = orientation
          @damageCount = []
          @home = 'squares'


          Kernel.srand()
          @r = rand(255)
          @g = rand(255)
          @b = rand(255)

          @count = rand(MAX_COUNT)+1

          x_offset = (args.state.board_width + args.grid.w / 8) + @block_offset / 2
          @x_adjusted = @x + x_offset
          @y_adjusted = @y
          @size_adjusted = @block_size * 2 - @block_offset

          hypotenuse=args.state.ball_hypotenuse
          @bold = [(@x_adjusted-hypotenuse/2)-1, (@y_adjusted-hypotenuse/2)-1, @size_adjusted + hypotenuse + 2, @size_adjusted + hypotenuse + 2]

          @points = [
            {x:@x_adjusted, y:@y_adjusted},
            {x:@x_adjusted+@size_adjusted, y:@y_adjusted},
            {x:@x_adjusted+@size_adjusted, y:@y_adjusted+@size_adjusted},
            {x:@x_adjusted, y:@y_adjusted+@size_adjusted}
          ]
          @squareColliders = [
            SquareCollider.new(@points[0].x,@points[0].y,{x:-1,y:-1}),
            SquareCollider.new(@points[1].x-COLLISIONWIDTH,@points[1].y,{x:1,y:-1}),
            SquareCollider.new(@points[2].x-COLLISIONWIDTH,@points[2].y-COLLISIONWIDTH,{x:1,y:1}),
            SquareCollider.new(@points[3].x,@points[3].y-COLLISIONWIDTH,{x:-1,y:1}),
          ]
          @colliders = [
            LinearCollider.new(@points[0],@points[1], :neg),
            LinearCollider.new(@points[1],@points[2], :neg),
            LinearCollider.new(@points[2],@points[3], :pos),
            LinearCollider.new(@points[0],@points[3], :pos)
          ]
     end

     def draw(args)
      #Offset the coordinates to the edge of the game area
      x_offset = (args.state.board_width + args.grid.w / 8) + @block_offset / 2
      #args.outputs.solids << [@x + x_offset, @y, @block_size * 2 - @block_offset, @block_size * 2 - @block_offset, @r, @g, @b]
      args.outputs.solids <<{x: (@x + x_offset), y: (@y), w: (@block_size * 2 - @block_offset), h: (@block_size * 2 - @block_offset), r: @r , g: @g , b: @b }
      #args.outputs.solids << @bold.append([255,0,0])
      args.outputs.labels << [@x + x_offset + (@block_size * 2 - @block_offset)/2, (@y) + (@block_size * 2 - @block_offset)/2, @count.to_s]

     end

     def update args
       universalUpdate args, self
     end
  end

  class TShape
      attr_accessor :count, :x, :y, :home, :bold, :squareColliders, :colliders, :damageCount
      def initialize(args, x, y, block_size, orientation, block_offset)
          @x = x * block_size
          @y = y * block_size
          @block_size = block_size
          @block_offset = block_offset
          @orientation = orientation
          @damageCount = []
          @home = "tshapes"

          Kernel.srand()
          @r = rand(255)
          @g = rand(255)
          @b = rand(255)

          @count = rand(MAX_COUNT)+1


          @shapePoints = getShapePoints(args)
          minX={x:INFINITY, y:0}
          minY={x:0, y:INFINITY}
          maxX={x:-INFINITY, y:0}
          maxY={x:0, y:-INFINITY}
          for p in @shapePoints
            if p.x < minX.x
              minX = p
            end
            if p.x > maxX.x
              maxX = p
            end
            if p.y < minY.y
              minY = p
            end
            if p.y > maxY.y
              maxY = p
            end
          end


          hypotenuse=args.state.ball_hypotenuse

          @bold = [(minX.x-hypotenuse/2)-1, (minY.y-hypotenuse/2)-1, -((minX.x-hypotenuse/2)-1)+(maxX.x + hypotenuse + 2), -((minY.y-hypotenuse/2)-1)+(maxY.y + hypotenuse + 2)]
      end
      def getShapePoints(args)
        points=[]
        x_offset = (args.state.board_width + args.grid.w / 8) + (@block_offset / 2)

        if @orientation == :right
            #args.outputs.solids << [@x + x_offset, @y, @block_size - @block_offset, @block_size * 3 - @block_offset, @r, @g, @b]
            #args.outputs.solids << [@x + x_offset, @y + @block_size, @block_size * 2, @block_size, @r, @g, @b]
            points = [
              {x:@x + x_offset, y:@y},
              {x:(@x + x_offset)+(@block_size - @block_offset), y:@y},
              {x:(@x + x_offset)+(@block_size - @block_offset),y:@y + @block_size},
              {x:(@x + x_offset)+ @block_size * 2,y:@y + @block_size},
              {x:(@x + x_offset)+ @block_size * 2,y:@y + @block_size+@block_size},
              {x:(@x + x_offset)+(@block_size - @block_offset),y:@y + @block_size+@block_size},
              {x:(@x + x_offset)+(@block_size - @block_offset), y:@y+ @block_size * 3 - @block_offset},
              {x:@x + x_offset , y:@y+ @block_size * 3 - @block_offset}
            ]
            @squareColliders = [
              SquareCollider.new(points[0].x,points[0].y,{x:-1,y:-1}),
              SquareCollider.new(points[1].x-COLLISIONWIDTH,points[1].y,{x:1,y:-1}),
              SquareCollider.new(points[2].x,points[2].y-COLLISIONWIDTH,{x:1,y:-1}),
              SquareCollider.new(points[3].x-COLLISIONWIDTH,points[3].y,{x:1,y:-1}),
              SquareCollider.new(points[4].x-COLLISIONWIDTH,points[4].y-COLLISIONWIDTH,{x:1,y:1}),
              SquareCollider.new(points[5].x,points[5].y,{x:1,y:1}),
              SquareCollider.new(points[6].x-COLLISIONWIDTH,points[6].y-COLLISIONWIDTH,{x:1,y:1}),
              SquareCollider.new(points[7].x,points[7].y-COLLISIONWIDTH,{x:-1,y:1}),
            ]
            @colliders = [
              LinearCollider.new(points[0],points[1], :neg),
              LinearCollider.new(points[1],points[2], :neg),
              LinearCollider.new(points[2],points[3], :neg),
              LinearCollider.new(points[3],points[4], :neg),
              LinearCollider.new(points[4],points[5], :pos),
              LinearCollider.new(points[5],points[6], :neg),
              LinearCollider.new(points[6],points[7], :pos),
              LinearCollider.new(points[0],points[7], :pos)
            ]
        elsif @orientation == :up
            #args.outputs.solids << [@x + x_offset, @y, @block_size * 3 - @block_offset, @block_size - @block_offset, @r, @g, @b]
            #args.outputs.solids << [@x + x_offset + @block_size, @y, @block_size, @block_size * 2, @r, @g, @b]
            points = [
              {x:@x + x_offset, y:@y},
              {x:(@x + x_offset)+(@block_size * 3 - @block_offset), y:@y},
              {x:(@x + x_offset)+(@block_size * 3 - @block_offset), y:@y+(@block_size - @block_offset)},
              {x:@x + x_offset + @block_size + @block_size, y:@y+(@block_size - @block_offset)},
              {x:@x + x_offset + @block_size + @block_size, y:@y+@block_size*2},
              {x:@x + x_offset + @block_size, y:@y+@block_size*2},
              {x:@x + x_offset + @block_size, y:@y+(@block_size - @block_offset)},
              {x:@x + x_offset, y:@y+(@block_size - @block_offset)}
            ]
            @squareColliders = [
              SquareCollider.new(points[0].x,points[0].y,{x:-1,y:-1}),
              SquareCollider.new(points[1].x-COLLISIONWIDTH,points[1].y,{x:1,y:-1}),
              SquareCollider.new(points[2].x-COLLISIONWIDTH,points[2].y-COLLISIONWIDTH,{x:1,y:1}),
              SquareCollider.new(points[3].x,points[3].y,{x:1,y:1}),
              SquareCollider.new(points[4].x-COLLISIONWIDTH,points[4].y-COLLISIONWIDTH,{x:1,y:1}),
              SquareCollider.new(points[5].x,points[5].y-COLLISIONWIDTH,{x:-1,y:1}),
              SquareCollider.new(points[6].x-COLLISIONWIDTH,points[6].y,{x:-1,y:1}),
              SquareCollider.new(points[7].x,points[7].y-COLLISIONWIDTH,{x:-1,y:1}),
            ]
            @colliders = [
              LinearCollider.new(points[0],points[1], :neg),
              LinearCollider.new(points[1],points[2], :neg),
              LinearCollider.new(points[2],points[3], :pos),
              LinearCollider.new(points[3],points[4], :neg),
              LinearCollider.new(points[4],points[5], :pos),
              LinearCollider.new(points[5],points[6], :neg),
              LinearCollider.new(points[6],points[7], :pos),
              LinearCollider.new(points[0],points[7], :pos)
            ]
        elsif @orientation == :left
            #args.outputs.solids << [@x + x_offset + @block_size, @y, @block_size - @block_offset, @block_size * 3 - @block_offset, @r, @g, @b]
            #args.outputs.solids << [@x + x_offset, @y + @block_size, @block_size * 2 - @block_offset, @block_size - @block_offset, @r, @g, @b]
            xh = @x + x_offset
            #points = [
              #{x:@x + x_offset, y:@y},
              #{x:(@x + x_offset)+(@block_size - @block_offset), y:@y},
              #{x:(@x + x_offset)+(@block_size - @block_offset),y:@y + @block_size},
              #{x:(@x + x_offset)+ @block_size * 2,y:@y + @block_size},
              #{x:(@x + x_offset)+ @block_size * 2,y:@y + @block_size+@block_size},
              #{x:(@x + x_offset)+(@block_size - @block_offset),y:@y + @block_size+@block_size},
              #{x:(@x + x_offset)+(@block_size - @block_offset), y:@y+ @block_size * 3 - @block_offset},
              #{x:@x + x_offset , y:@y+ @block_size * 3 - @block_offset}
            #]
            points = [
              {x:@x + x_offset + @block_size, y:@y},
              {x:@x + x_offset + @block_size + (@block_size - @block_offset), y:@y},
              {x:@x + x_offset + @block_size + (@block_size - @block_offset),y:@y+@block_size*3- @block_offset},
              {x:@x + x_offset + @block_size, y:@y+@block_size*3- @block_offset},
              {x:@x + x_offset+@block_size, y:@y+@block_size*2- @block_offset},
              {x:@x + x_offset, y:@y+@block_size*2- @block_offset},
              {x:@x + x_offset, y:@y+@block_size},
              {x:@x + x_offset+@block_size, y:@y+@block_size}
            ]
            @squareColliders = [
              SquareCollider.new(points[0].x,points[0].y,{x:-1,y:-1}),
              SquareCollider.new(points[1].x-COLLISIONWIDTH,points[1].y,{x:1,y:-1}),
              SquareCollider.new(points[2].x-COLLISIONWIDTH,points[2].y-COLLISIONWIDTH,{x:1,y:1}),
              SquareCollider.new(points[3].x,points[3].y-COLLISIONWIDTH,{x:-1,y:1}),
              SquareCollider.new(points[4].x-COLLISIONWIDTH,points[4].y,{x:-1,y:1}),
              SquareCollider.new(points[5].x,points[5].y-COLLISIONWIDTH,{x:-1,y:1}),
              SquareCollider.new(points[6].x,points[6].y,{x:-1,y:-1}),
              SquareCollider.new(points[7].x-COLLISIONWIDTH,points[7].y-COLLISIONWIDTH,{x:-1,y:-1}),
            ]
            @colliders = [
              LinearCollider.new(points[0],points[1], :neg),
              LinearCollider.new(points[1],points[2], :neg),
              LinearCollider.new(points[2],points[3], :pos),
              LinearCollider.new(points[3],points[4], :neg),
              LinearCollider.new(points[4],points[5], :pos),
              LinearCollider.new(points[5],points[6], :neg),
              LinearCollider.new(points[6],points[7], :neg),
              LinearCollider.new(points[0],points[7], :pos)
            ]
        elsif @orientation == :down
            #args.outputs.solids << [@x + x_offset, @y + @block_size, @block_size * 3 - @block_offset, @block_size - @block_offset, @r, @g, @b]
            #args.outputs.solids << [@x + x_offset + @block_size, @y, @block_size - @block_offset, @block_size * 2 - @block_offset, @r, @g, @b]

            points = [
              {x:@x + x_offset, y:@y+(@block_size*2)-@block_offset},
              {x:@x + x_offset+ @block_size*3-@block_offset, y:@y+(@block_size*2)-@block_offset},
              {x:@x + x_offset+ @block_size*3-@block_offset, y:@y+(@block_size)},
              {x:@x + x_offset+ @block_size*2-@block_offset, y:@y+(@block_size)},
              {x:@x + x_offset+ @block_size*2-@block_offset, y:@y},#
              {x:@x + x_offset+ @block_size, y:@y},#
              {x:@x + x_offset + @block_size, y:@y+(@block_size)},
              {x:@x + x_offset, y:@y+(@block_size)}
            ]
            @squareColliders = [
              SquareCollider.new(points[0].x,points[0].y-COLLISIONWIDTH,{x:-1,y:1}),
              SquareCollider.new(points[1].x-COLLISIONWIDTH,points[1].y-COLLISIONWIDTH,{x:1,y:1}),
              SquareCollider.new(points[2].x-COLLISIONWIDTH,points[2].y,{x:1,y:-1}),
              SquareCollider.new(points[3].x,points[3].y-COLLISIONWIDTH,{x:1,y:-1}),
              SquareCollider.new(points[4].x-COLLISIONWIDTH,points[4].y,{x:1,y:-1}),
              SquareCollider.new(points[5].x,points[5].y,{x:-1,y:-1}),
              SquareCollider.new(points[6].x-COLLISIONWIDTH,points[6].y-COLLISIONWIDTH,{x:-1,y:-1}),
              SquareCollider.new(points[7].x,points[7].y,{x:-1,y:-1}),
            ]
            @colliders = [
              LinearCollider.new(points[0],points[1], :pos),
              LinearCollider.new(points[1],points[2], :pos),
              LinearCollider.new(points[2],points[3], :neg),
              LinearCollider.new(points[3],points[4], :pos),
              LinearCollider.new(points[4],points[5], :neg),
              LinearCollider.new(points[5],points[6], :pos),
              LinearCollider.new(points[6],points[7], :neg),
              LinearCollider.new(points[0],points[7], :neg)
            ]
        end
        return points
      end

      def draw(args)
          #Offset the coordinates to the edge of the game area
          x_offset = (args.state.board_width + args.grid.w / 8) + (@block_offset / 2)

          if @orientation == :right
              #args.outputs.solids << [@x + x_offset, @y, @block_size - @block_offset, @block_size * 3 - @block_offset, @r, @g, @b]
              args.outputs.solids << {x: (@x + x_offset), y: @y, w: @block_size - @block_offset, h: (@block_size * 3 - @block_offset), r: @r , g: @g, b: @b}
              #args.outputs.solids << [@x + x_offset, @y + @block_size, @block_size * 2, @block_size, @r, @g, @b]
              args.outputs.solids << {x: (@x + x_offset), y: (@y + @block_size), w: (@block_size * 2), h: (@block_size), r: @r , g: @g, b: @b }
          elsif @orientation == :up
              #args.outputs.solids << [@x + x_offset, @y, @block_size * 3 - @block_offset, @block_size - @block_offset, @r, @g, @b]
              args.outputs.solids << {x: (@x + x_offset), y: (@y), w: (@block_size * 3 - @block_offset), h: (@block_size - @block_offset), r: @r , g: @g, b: @b}
              #args.outputs.solids << [@x + x_offset + @block_size, @y, @block_size, @block_size * 2, @r, @g, @b]
              args.outputs.solids << {x: (@x + x_offset + @block_size), y: (@y), w: (@block_size), h: (@block_size * 2), r: @r , g: @g, b: @b}
          elsif @orientation == :left
              #args.outputs.solids << [@x + x_offset + @block_size, @y, @block_size - @block_offset, @block_size * 3 - @block_offset, @r, @g, @b]
              args.outputs.solids << {x: (@x + x_offset + @block_size), y: (@y), w: (@block_size - @block_offset), h: (@block_size * 3 - @block_offset), r: @r , g: @g, b: @b}
              #args.outputs.solids << [@x + x_offset, @y + @block_size, @block_size * 2 - @block_offset, @block_size - @block_offset, @r, @g, @b]
              args.outputs.solids << {x: (@x + x_offset), y: (@y + @block_size), w: (@block_size * 2 - @block_offset), h: (@block_size - @block_offset), r: @r , g: @g, b: @b}
          elsif @orientation == :down
              #args.outputs.solids << [@x + x_offset, @y + @block_size, @block_size * 3 - @block_offset, @block_size - @block_offset, @r, @g, @b]
              args.outputs.solids << {x: (@x + x_offset), y: (@y + @block_size), w: (@block_size * 3 - @block_offset), h: (@block_size - @block_offset), r: @r , g: @g, b: @b}
              #args.outputs.solids << [@x + x_offset + @block_size, @y, @block_size - @block_offset, @block_size * 2 - @block_offset, @r, @g, @b]
              args.outputs.solids << {x: (@x + x_offset + @block_size), y: (@y), w: (@block_size - @block_offset), h: ( @block_size * 2 - @block_offset), r: @r , g: @g, b: @b}
          end

          #psize = 5.0
          #for p in @shapePoints
            #args.outputs.solids << [p.x-psize/2, p.y-psize/2, psize, psize, 0, 0, 0]
          #end
          args.outputs.labels << [@x + x_offset + (@block_size * 2 - @block_offset)/2, (@y) + (@block_size * 2 - @block_offset)/2, @count.to_s]

      end

      def updateOne_old args
        didHit = false
        hitter = nil
        toCollide = nil
        for b in args.state.balls
          if [b.x, b.y, b.width, b.height].intersect_rect?(@bold)
            didSquare = false
            for s in @squareColliders
              if (s.collision?(args, b))
                didSquare = true
                didHit = true
                #s.collide(args, b)
                toCollide = s
                hitter = b
                break
              end
            end
            if (didSquare == false)
              for c in @colliders
                #puts args.state.ball.velocity
                if c.collision?(args, b.getPoints(args),b)
                  #c.collide args, b
                  toCollide = c
                  didHit = true
                  hitter = b
                  break
                end
              end
            end
          end
          if didHit
            break
          end
        end
        if (didHit)
          @count=0
          hitter.makeLeader args
          #toCollide.collide(args, hitter)
          args.state.tshapes.delete(self)
          #puts "HIT!" + hitter.number
        end
      end

      def update_old args
        if (@count == 1)
          updateOne args
          return
        end
        didHit = false
        hitter = nil
        for b in args.state.ballParents
          if [b.x, b.y, b.width, b.height].intersect_rect?(@bold)
            didSquare = false
            for s in @squareColliders
              if (s.collision?(args, b))
                didSquare = true
                didHit=true
                s.collide(args, b)
                hitter = b
              end
            end
            if (didSquare == false)
              for c in @colliders
                #puts args.state.ball.velocity
                if c.collision?(args, b.getPoints(args), b)
                  c.collide args, b
                  didHit=true
                  hitter = b
                end
              end
            end
          end
        end
        if (didHit)
          @count=@count-1
          @damageCount.append([(hitter.leastChain+1 - hitter.number)-1, Kernel.tick_count])

          if (@count == 0)
            args.state.tshapes.delete(self)
            return
          end
        end
        i=0

        while i < @damageCount.length
          if @damageCount[i][0] <= 0
            @damageCount.delete_at(i)
            i-=1
          elsif @damageCount[i][1].elapsed_time > BALL_DISTANCE
            @count-=1
            @damageCount[i][0]-=1
          end
          if (@count == 0)
            args.state.tshapes.delete(self)
            return
          end
          i+=1
        end
      end #end update

      def update args
        universalUpdate args, self
      end

  end

  class Line
      attr_accessor :count, :x, :y, :home, :bold, :squareColliders, :colliders, :damageCount
      def initialize(args, x, y, block_size, orientation, block_offset)
          @x = x * block_size
          @y = y * block_size
          @block_size = block_size
          @block_offset = block_offset
          @orientation = orientation
          @damageCount = []
          @home = "lines"

          Kernel.srand()
          @r = rand(255)
          @g = rand(255)
          @b = rand(255)

          @count = rand(MAX_COUNT)+1

          @shapePoints = getShapePoints(args)
          minX={x:INFINITY, y:0}
          minY={x:0, y:INFINITY}
          maxX={x:-INFINITY, y:0}
          maxY={x:0, y:-INFINITY}
          for p in @shapePoints
            if p.x < minX.x
              minX = p
            end
            if p.x > maxX.x
              maxX = p
            end
            if p.y < minY.y
              minY = p
            end
            if p.y > maxY.y
              maxY = p
            end
          end


          hypotenuse=args.state.ball_hypotenuse

          @bold = [(minX.x-hypotenuse/2)-1, (minY.y-hypotenuse/2)-1, -((minX.x-hypotenuse/2)-1)+(maxX.x + hypotenuse + 2), -((minY.y-hypotenuse/2)-1)+(maxY.y + hypotenuse + 2)]
      end

      def getShapePoints(args)
        points=[]
        x_offset = (args.state.board_width + args.grid.w / 8) + (@block_offset / 2)

        if @orientation == :right
          #args.outputs.solids << [@x + x_offset, @y, @block_size * 3 - @block_offset, @block_size - @block_offset, @r, @g, @b]
          xa =@x + x_offset
          ya =@y
          wa =@block_size * 3 - @block_offset
          ha =(@block_size - @block_offset)
        elsif @orientation == :up
          #args.outputs.solids << [@x + x_offset, @y, @block_size - @block_offset, @block_size * 3 - @block_offset, @r, @g, @b]
          xa =@x + x_offset
          ya =@y
          wa =@block_size - @block_offset
          ha =@block_size * 3 - @block_offset

        elsif @orientation == :left
          #args.outputs.solids << [@x + x_offset, @y, @block_size * 3 - @block_offset, @block_size - @block_offset, @r, @g, @b]
          xa =@x + x_offset
          ya =@y
          wa =@block_size * 3 - @block_offset
          ha =@block_size - @block_offset
        elsif @orientation == :down
          #args.outputs.solids << [@x + x_offset, @y, @block_size - @block_offset, @block_size * 3 - @block_offset, @r, @g, @b]
          xa =@x + x_offset
          ya =@y
          wa =@block_size - @block_offset
          ha =@block_size * 3 - @block_offset
        end
        points = [
          {x: xa, y:ya},
          {x: xa + wa,y:ya},
          {x: xa + wa,y:ya+ha},
          {x: xa, y:ya+ha},
        ]
        @squareColliders = [
          SquareCollider.new(points[0].x,points[0].y,{x:-1,y:-1}),
          SquareCollider.new(points[1].x-COLLISIONWIDTH,points[1].y,{x:1,y:-1}),
          SquareCollider.new(points[2].x-COLLISIONWIDTH,points[2].y-COLLISIONWIDTH,{x:1,y:1}),
          SquareCollider.new(points[3].x,points[3].y-COLLISIONWIDTH,{x:-1,y:1}),
        ]
        @colliders = [
          LinearCollider.new(points[0],points[1], :neg),
          LinearCollider.new(points[1],points[2], :neg),
          LinearCollider.new(points[2],points[3], :pos),
          LinearCollider.new(points[0],points[3], :pos),
        ]
        return points
      end

      def update args
        universalUpdate args, self
      end

      def draw(args)
          x_offset = (args.state.board_width + args.grid.w / 8) + @block_offset / 2

          if @orientation == :right
              args.outputs.solids << [@x + x_offset, @y, @block_size * 3 - @block_offset, @block_size - @block_offset, @r, @g, @b]
          elsif @orientation == :up
              args.outputs.solids << [@x + x_offset, @y, @block_size - @block_offset, @block_size * 3 - @block_offset, @r, @g, @b]
          elsif @orientation == :left
              args.outputs.solids << [@x + x_offset, @y, @block_size * 3 - @block_offset, @block_size - @block_offset, @r, @g, @b]
          elsif @orientation == :down
              args.outputs.solids << [@x + x_offset, @y, @block_size - @block_offset, @block_size * 3 - @block_offset, @r, @g, @b]
          end

          args.outputs.labels << [@x + x_offset + (@block_size * 2 - @block_offset)/2, (@y) + (@block_size * 2 - @block_offset)/2, @count.to_s]

      end
  end

```

### Arbitrary Collision - linear_collider.rb
```ruby
  # ./samples/04_physics_and_collisions/09_arbitrary_collision/app/linear_collider.rb

  COLLISIONWIDTH=8

  class LinearCollider
    attr_reader :pointA, :pointB
    def initialize (pointA, pointB, mode,collisionWidth=COLLISIONWIDTH)
      @pointA = pointA
      @pointB = pointB
      @mode = mode
      @collisionWidth = collisionWidth

      if (@pointA.x > @pointB.x)
        @pointA, @pointB = @pointB, @pointA
      end

      @linearCollider_collision_once = false
    end

    def collisionSlope args
      if (@pointB.x-@pointA.x == 0)
        return INFINITY
      end
      return (@pointB.y - @pointA.y) / (@pointB.x - @pointA.x)
    end


    def collision? (args, points, ball=nil)

      slope = collisionSlope args
      result = false

      # calculate a vector with a magnitude of (1/2)collisionWidth and a direction perpendicular to the collision line
      vect=nil;mag=nil;vect=nil;
      if @mode == :both
        vect = {x: @pointB.x - @pointA.x, y:@pointB.y - @pointA.y}
        mag  = (vect.x**2 + vect.y**2)**0.5
        vect = {y: -1*(vect.x/(mag))*@collisionWidth*0.5, x: (vect.y/(mag))*@collisionWidth*0.5}
      else
        vect = {x: @pointB.x - @pointA.x, y:@pointB.y - @pointA.y}
        mag  = (vect.x**2 + vect.y**2)**0.5
        vect = {y: -1*(vect.x/(mag))*@collisionWidth, x: (vect.y/(mag))*@collisionWidth}
      end

      rpointA=nil;rpointB=nil;rpointC=nil;rpointD=nil;
      if @mode == :pos
        rpointA = {x:@pointA.x + vect.x, y:@pointA.y + vect.y}
        rpointB = {x:@pointB.x + vect.x, y:@pointB.y + vect.y}
        rpointC = {x:@pointB.x, y:@pointB.y}
        rpointD = {x:@pointA.x, y:@pointA.y}
      elsif @mode == :neg
        rpointA = {x:@pointA.x, y:@pointA.y}
        rpointB = {x:@pointB.x, y:@pointB.y}
        rpointC = {x:@pointB.x - vect.x, y:@pointB.y - vect.y}
        rpointD = {x:@pointA.x - vect.x, y:@pointA.y - vect.y}
      elsif @mode == :both
        rpointA = {x:@pointA.x + vect.x, y:@pointA.y + vect.y}
        rpointB = {x:@pointB.x + vect.x, y:@pointB.y + vect.y}
        rpointC = {x:@pointB.x - vect.x, y:@pointB.y - vect.y}
        rpointD = {x:@pointA.x - vect.x, y:@pointA.y - vect.y}
      end
      #four point rectangle



      if ball != nil
        xs = [rpointA.x,rpointB.x,rpointC.x,rpointD.x]
        ys = [rpointA.y,rpointB.y,rpointC.y,rpointD.y]
        correct = 1
        rect1 = [ball.x, ball.y, ball.width, ball.height]
        #$r1 = rect1
        rect2 = [xs.min-correct,ys.min-correct,(xs.max-xs.min)+correct*2,(ys.max-ys.min)+correct*2]
        #$r2 = rect2
        if rect1.intersect_rect?(rect2) == false
          return false
        end
      end


      #area of a triangle
      triArea = -> (a,b,c) { ((a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))/2.0).abs }

      #if at least on point is in the rectangle then collision? is true - otherwise false
      for point in points
        #Check whether a given point lies inside a rectangle or not:
        #if the sum of the area of traingls, PAB, PBC, PCD, PAD equal the area of the rec, then an intersection has occurred
        areaRec =  triArea.call(rpointA, rpointB, rpointC)+triArea.call(rpointA, rpointC, rpointD)
        areaSum = [
          triArea.call(point, rpointA, rpointB),triArea.call(point, rpointB, rpointC),
          triArea.call(point, rpointC, rpointD),triArea.call(point, rpointA, rpointD)
        ].inject(0){|sum,x| sum + x }
        e = 0.0001 #allow for minor error
        if areaRec>= areaSum-e and areaRec<= areaSum+e
          result = true
          #return true
          break
        end
      end

      #args.outputs.lines << [@pointA.x, @pointA.y, @pointB.x, @pointB.y,     000, 000, 000]
      #args.outputs.lines << [rpointA.x, rpointA.y, rpointB.x, rpointB.y,     255, 000, 000]
      #args.outputs.lines << [rpointC.x, rpointC.y, rpointD.x, rpointD.y,     000, 000, 255]


      #puts (rpointA.x.to_s + " " +  rpointA.y.to_s + " " + rpointB.x.to_s + " "+ rpointB.y.to_s)
      return result
    end #end collision?

    def getRepelMagnitude (fbx, fby, vrx, vry, ballMag)
      a = fbx ; b = vrx ; c = fby
      d = vry ; e = ballMag
      if b**2 + d**2 == 0
        #unexpected
      end
      x1 = (-a*b+-c*d + (e**2 * b**2 - b**2 * c**2 + 2*a*b*c*d + e**2 + d**2 - a**2 * d**2)**0.5)/(b**2 + d**2)
      x2 = -((a*b + c*d + (e**2 * b**2 - b**2 * c**2 + 2*a*b*c*d + e**2 * d**2 - a**2 * d**2)**0.5)/(b**2 + d**2))
      err = 0.00001
      o = ((fbx + x1*vrx)**2 + (fby + x1*vry)**2 ) ** 0.5
      p = ((fbx + x2*vrx)**2 + (fby + x2*vry)**2 ) ** 0.5
      r = 0
      if (ballMag >= o-err and ballMag <= o+err)
        r = x1
      elsif (ballMag >= p-err and ballMag <= p+err)
        r = x2
      else
        #unexpected
      end
      return r
    end

    def collide args, ball
      slope = collisionSlope args

      # perpVect: normal vector perpendicular to collision
      perpVect = {x: @pointB.x - @pointA.x, y:@pointB.y - @pointA.y}
      mag  = (perpVect.x**2 + perpVect.y**2)**0.5
      perpVect = {x: perpVect.x/(mag), y: perpVect.y/(mag)}
      perpVect = {x: -perpVect.y, y: perpVect.x}
      if perpVect.y > 0 #ensure perpVect points upward
        perpVect = {x: perpVect.x*-1, y: perpVect.y*-1}
      end
      previousPosition = {
        x:ball.x-ball.velocity.x,
        y:ball.y-ball.velocity.y
      }
      yInterc = @pointA.y + -slope*@pointA.x
      if slope == INFINITY
        if previousPosition.x < @pointA.x
          perpVect = {x: perpVect.x*-1, y: perpVect.y*-1}
          yInterc = -INFINITY
        end
      elsif previousPosition.y < slope*previousPosition.x + yInterc #check if ball is bellow or above the collider to determine if perpVect is - or +
        perpVect = {x: perpVect.x*-1, y: perpVect.y*-1}
      end

      velocityMag = (ball.velocity.x**2 + ball.velocity.y**2)**0.5
      theta_ball=Math.atan2(ball.velocity.y,ball.velocity.x) #the angle of the ball's velocity
      theta_repel=Math.atan2(perpVect.y,perpVect.x) #the angle of the repelling force(perpVect)

      fbx = velocityMag * Math.cos(theta_ball) #the x component of the ball's velocity
      fby = velocityMag * Math.sin(theta_ball) #the y component of the ball's velocity

      #the magnitude of the repelling force
      repelMag = getRepelMagnitude(fbx, fby, perpVect.x, perpVect.y, (ball.velocity.x**2 + ball.velocity.y**2)**0.5)
      frx = repelMag* Math.cos(theta_repel) #the x component of the repel's velocity | magnitude is set to twice of fbx
      fry = repelMag* Math.sin(theta_repel) #the y component of the repel's velocity | magnitude is set to twice of fby

      fsumx = fbx+frx #sum of x forces
      fsumy = fby+fry #sum of y forces
      fr = velocityMag#fr is the resulting magnitude
      thetaNew = Math.atan2(fsumy, fsumx)  #thetaNew is the resulting angle
      xnew = fr*Math.cos(thetaNew)#resulting x velocity
      ynew = fr*Math.sin(thetaNew)#resulting y velocity
      if (velocityMag < MAX_VELOCITY)
        ball.velocity =  Vector2d.new(xnew*1.1, ynew*1.1)
      else
        ball.velocity =  Vector2d.new(xnew, ynew)
      end

    end
  end

```

### Arbitrary Collision - main.rb
```ruby
  # ./samples/04_physics_and_collisions/09_arbitrary_collision/app/main.rb
  INFINITY= 10**10
  MAX_VELOCITY = 8.0
  BALL_COUNT = 90
  BALL_DISTANCE = 20
  require 'app/vector2d.rb'
  require 'app/blocks.rb'
  require 'app/ball.rb'
  require 'app/rectangle.rb'
  require 'app/linear_collider.rb'
  require 'app/square_collider.rb'



  #Method to init default values
  def defaults args
    args.state.board_width ||= args.grid.w / 4
    args.state.board_height ||= args.grid.h
    args.state.game_area ||= [(args.state.board_width + args.grid.w / 8), 0, args.state.board_width, args.grid.h]
    args.state.balls ||= []
    args.state.num_balls ||= 0
    args.state.ball_created_at ||= Kernel.tick_count
    args.state.ball_hypotenuse = (10**2 + 10**2)**0.5
    args.state.ballParents ||= []

    init_blocks args
    init_balls args
  end

  begin :default_methods
    def init_blocks args
      block_size = args.state.board_width / 8
      #Space inbetween each block
      block_offset = 4

      args.state.squares ||=[
        Square.new(args, 2, 0, block_size, :right, block_offset),
        Square.new(args, 5, 0, block_size, :right, block_offset),
        Square.new(args, 6, 7, block_size, :right, block_offset)
      ]


      #Possible orientations are :right, :left, :up, :down


      args.state.tshapes ||= [
        TShape.new(args, 0, 6, block_size, :left, block_offset),
        TShape.new(args, 3, 3, block_size, :down, block_offset),
        TShape.new(args, 0, 3, block_size, :right, block_offset),
        TShape.new(args, 0, 11, block_size, :up, block_offset)
      ]

      args.state.lines ||= [
        Line.new(args,3, 8, block_size, :down, block_offset),
        Line.new(args, 7, 3, block_size, :up, block_offset),
        Line.new(args, 3, 7, block_size, :right, block_offset)
      ]

      #exit()
    end

    def init_balls args
      return unless args.state.num_balls < BALL_COUNT


      #only create a new ball every 10 ticks
      return unless args.state.ball_created_at.elapsed_time > 10

      if (args.state.num_balls == 0)
        args.state.balls.append(Ball.new(args,args.state.num_balls,BALL_COUNT-1, nil, nil))
        args.state.ballParents = [args.state.balls[0]]
      else
        args.state.balls.append(Ball.new(args,args.state.num_balls,BALL_COUNT-1, args.state.balls.last, nil) )
        args.state.balls[-2].child = args.state.balls[-1]
      end
      args.state.ball_created_at = Kernel.tick_count
      args.state.num_balls += 1
    end
  end

  #Render loop
  def render args
    bgClr = {r:10, g:10, b:200}
    bgClr = {r:255-30, g:255-30, b:255-30}

    args.outputs.solids << [0, 0, Grid.right, Grid.top, bgClr[:r], bgClr[:g], bgClr[:b]];
    args.outputs.borders << args.state.game_area

    render_instructions args
    render_shapes args

    render_balls args

    #args.state.rectangle.draw args

    args.outputs.sprites << [Grid.right-(args.state.board_width + Grid.w / 8), 0, Grid.right, Grid.top, "sprites/square-white-2.png", 0, 255, bgClr[:r], bgClr[:g], bgClr[:b]]
    args.outputs.sprites << [0, 0, (args.state.board_width + Grid.w / 8), Grid.top, "sprites/square-white-2.png", 0, 255, bgClr[:r], bgClr[:g], bgClr[:b]]

  end

  begin :render_methods
    def render_instructions args
      #gtk.current_framerate
      args.outputs.labels << [20, Grid.top-20, "FPS: " + DR.current_framerate.to_s]
      if (args.state.balls != nil && args.state.balls[0] != nil)
          bx =  args.state.balls[0].velocity.x
          by =  args.state.balls[0].velocity.y
          bmg = (bx**2.0 + by**2.0)**0.5
          args.outputs.labels << [20, Grid.top-20-20, "V: " + bmg.to_s ]
      end


    end

    def render_shapes args
      for s in args.state.squares
        s.draw args
      end

      for l in args.state.lines
        l.draw args
      end

      for t in args.state.tshapes
        t.draw args
      end


    end

    def render_balls args
      #args.state.balls.each do |ball|
        #ball.draw args
      #end

      args.outputs.sprites << args.state.balls.map do |ball|
        ball.getDraw args
      end
    end
  end

  #Calls all methods necessary for performing calculations
  def calc args
    for b in args.state.ballParents
      b.update args
    end

    for s in args.state.squares
      s.update args
    end

    for l in args.state.lines
      l.update args
    end

    for t in args.state.tshapes
      t.update args
    end



  end

  begin :calc_methods

  end

  def tick args
    defaults args
    render args
    calc args
  end

```

### Arbitrary Collision - paddle.rb
```ruby
  # ./samples/04_physics_and_collisions/09_arbitrary_collision/app/paddle.rb
  class Paddle
    attr_accessor :enabled

    def initialize ()
      @x=WIDTH/2
      @y=100
      @width=100
      @height=20
      @speed=10

      @xyCollision  = LinearCollider.new({x: @x,y: @y+@height+5}, {x: @x+@width, y: @y+@height+5})
      @xyCollision2 = LinearCollider.new({x: @x,y: @y}, {x: @x+@width, y: @y}, :pos)
      @xyCollision3 = LinearCollider.new({x: @x,y: @y}, {x: @x, y: @y+@height+5})
      @xyCollision4 = LinearCollider.new({x: @x+@width,y: @y}, {x: @x+@width, y: @y+@height+5}, :pos)

      @enabled = true
    end

    def update args
      @xyCollision.resetPoints({x: @x,y: @y+@height+5}, {x: @x+@width, y: @y+@height+5})
      @xyCollision2.resetPoints({x: @x,y: @y}, {x: @x+@width, y: @y})
      @xyCollision3.resetPoints({x: @x,y: @y}, {x: @x, y: @y+@height+5})
      @xyCollision4.resetPoints({x: @x+@width,y: @y}, {x: @x+@width, y: @y+@height+5})

      @xyCollision.update  args
      @xyCollision2.update args
      @xyCollision3.update args
      @xyCollision4.update args

      args.inputs.keyboard.key_held.left  ||= false
      args.inputs.keyboard.key_held.right  ||= false

      if not (args.inputs.keyboard.key_held.left == args.inputs.keyboard.key_held.right)
        if args.inputs.keyboard.key_held.left && @enabled
          @x-=@speed
        elsif args.inputs.keyboard.key_held.right && @enabled
          @x+=@speed
        end
      end

      xmin =WIDTH/4
      xmax = 3*(WIDTH/4)
      @x = (@x+@width > xmax) ? xmax-@width : (@x<xmin) ? xmin : @x;
    end

    def render args
      args.outputs.solids << [@x,@y,@width,@height,255,0,0];
    end

    def rect
      [@x, @y, @width, @height]
    end
  end

```

### Arbitrary Collision - rectangle.rb
```ruby
  # ./samples/04_physics_and_collisions/09_arbitrary_collision/app/rectangle.rb
  class Rectangle
    def initialize args

      @image = "sprites/roundSquare_white.png"
      @width  = 160.0
      @height = 80.0
      @x=Grid.right/2.0 - @width/2.0
      @y=Grid.top/2.0 - @height/2.0

      @xtmp = @width  * (1.0/10.0)
      @ytmp = @height * (1.0/10.0)

      #ball0 = args.state.balls[0]
      #hypotenuse = (args.state.balls[0].width**2 + args.state.balls[0].height**2)**0.5
      hypotenuse=args.state.ball_hypotenuse
      @boldXY = {x:(@x-hypotenuse/2)-1, y:(@y-hypotenuse/2)-1}
      @boldWidth = @width + hypotenuse + 2
      @boldHeight = @height + hypotenuse + 2
      @bold = [(@x-hypotenuse/2)-1,(@y-hypotenuse/2)-1,@width + hypotenuse + 2,@height + hypotenuse + 2]


      @points = [
        {x:@x,        y:@y+@ytmp},
        {x:@x+@xtmp,        y:@y},
        {x:@x+@width-@xtmp, y:@y},
        {x:@x+@width, y:@y+@ytmp},
        {x:@x+@width, y:@y+@height-@ytmp},#
        {x:@x+@width-@xtmp, y:@y+@height},
        {x:@x+@xtmp,        y:@y+@height},
        {x:@x,        y:@y+@height-@ytmp}
      ]

      @colliders = []
      #i = 0
      #while i < @points.length-1
        #@colliders.append(LinearCollider.new(@points[i],@points[i+1],:pos))
        #i+=1
      #end
      @colliders.append(LinearCollider.new(@points[0],@points[1], :neg))
      @colliders.append(LinearCollider.new(@points[1],@points[2], :neg))
      @colliders.append(LinearCollider.new(@points[2],@points[3], :neg))
      @colliders.append(LinearCollider.new(@points[3],@points[4], :neg))
      @colliders.append(LinearCollider.new(@points[4],@points[5], :pos))
      @colliders.append(LinearCollider.new(@points[5],@points[6], :pos))
      @colliders.append(LinearCollider.new(@points[6],@points[7], :pos))
      @colliders.append(LinearCollider.new(@points[0],@points[7], :pos))

    end

    def update args

      for b in args.state.balls
        if [b.x, b.y, b.width, b.height].intersect_rect?(@bold)
          for c in @colliders
            if c.collision?(args, b.getPoints(args),b)
              c.collide args, b
            end
          end
        end
      end
    end

    def draw args
      args.outputs.sprites << [
        @x,                                       # X
        @y,                                       # Y
        @width,                                   # W
        @height,                                  # H
        @image,                                   # PATH
        0,                                        # ANGLE
        255,                                      # ALPHA
        219,                                      # RED_SATURATION
        112,                                      # GREEN_SATURATION
        147                                       # BLUE_SATURATION
      ]
      #args.outputs.sprites << [@x, @y, @width, @height, "sprites/roundSquare_small_black.png"]
    end

    def serialize
    	{x: @x, y:@y}
    end

    def inspect
    	serialize.to_s
    end

    def to_s
    	serialize.to_s
    end
  end

```

### Arbitrary Collision - square_collider.rb
```ruby
  # ./samples/04_physics_and_collisions/09_arbitrary_collision/app/square_collider.rb

  class SquareCollider
    def initialize x,y,direction,size=COLLISIONWIDTH
      @x = x
      @y = y
      @size = size
      @direction = direction

    end
    def collision? args, ball
      #args.outputs.solids <<  [@x, @y, @size, @size,     000, 255, 255]


      return [@x,@y,@size,@size].intersect_rect?([ball.x,ball.y,ball.width,ball.height])
    end

    def collide args, ball
      vmag = (ball.velocity.x**2.0 +ball.velocity.y**2.0)**0.5
      a = ((2.0**0.5)*vmag)/2.0
      if vmag < MAX_VELOCITY
        ball.velocity.x = (a) * @direction.x * 1.1
        ball.velocity.y = (a) * @direction.y * 1.1
      else
        ball.velocity.x = (a) * @direction.x
        ball.velocity.y = (a) * @direction.y
      end

    end
  end

```

### Arbitrary Collision - vector2d.rb
```ruby
  # ./samples/04_physics_and_collisions/09_arbitrary_collision/app/vector2d.rb
  class Vector2d
      attr_accessor :x, :y

      def initialize x=0, y=0
        @x=x
        @y=y
      end

      #returns a vector multiplied by scalar x
      #x [float] scalar
      def mult x
        r = Vector2d.new(0,0)
        r.x=@x*x
        r.y=@y*x
        r
      end

      # vect [Vector2d] vector to copy
      def copy vect
        Vector2d.new(@x, @y)
      end

      #returns a new vector equivalent to this+vect
      #vect [Vector2d] vector to add to self
      def add vect
        Vector2d.new(@x+vect.x,@y+vect.y)
      end

      #returns a new vector equivalent to this-vect
      #vect [Vector2d] vector to subtract to self
      def sub vect
        Vector2d.new(@x-vect.c, @y-vect.y)
      end

      #return the magnitude of the vector
      def mag
        ((@x**2)+(@y**2))**0.5
      end

      #returns a new normalize version of the vector
      def normalize
        Vector2d.new(@x/mag, @y/mag)
      end

      #TODO delet?
      def distABS vect
        (((vect.x-@x)**2+(vect.y-@y)**2)**0.5).abs()
      end
    end
```

### Collision With Object Removal - ball.rb
```ruby
  # ./samples/04_physics_and_collisions/10_collision_with_object_removal/app/ball.rb
  class Ball
    #TODO limit accessors?
    attr_accessor :xy, :width, :height, :velocity


    #@xy [Vector2d] x,y position
    #@velocity [Vector2d] velocity of ball
    def initialize
      @xy = Vector2d.new(WIDTH/2,500)
      @velocity = Vector2d.new(4,-4)
      @width =  20
      @height = 20
    end

    #move the ball according to its velocity
    def update args
      @xy.x+=@velocity.x
      @xy.y+=@velocity.y
    end

    #render the ball to the screen
    def render args
      args.outputs.solids << [@xy.x,@xy.y,@width,@height,255,0,255];
      #args.outputs.labels << [20,HEIGHT-50,"velocity: " +@velocity.x.to_s+","+@velocity.y.to_s + "   magnitude:" + @velocity.mag.to_s]
    end

    def rect
      [@xy.x,@xy.y,@width,@height]
    end

  end

```

### Collision With Object Removal - linear_collider.rb
```ruby
  # ./samples/04_physics_and_collisions/10_collision_with_object_removal/app/linear_collider.rb
  #The LinearCollider (theoretically) produces collisions upon a line segment defined point.y two x,y cordinates

  class LinearCollider

    #start [Array of length 2] start of the line segment as a x,y cordinate
    #last [Array of length 2] end of the line segment as a x,y cordinate

    #inorder for the LinearCollider to be functional the line segment must be said to have a thickness
    #(as it is unlikly that a colliding object will land exactly on the linesegment)

    #extension defines if the line's thickness extends negatively or positively
    #extension :pos     extends positively
    #extension :neg     extends negatively

    #thickness [float] how thick the line should be (should always be atleast as large as the magnitude of the colliding object)
    def initialize (pointA, pointB, extension=:neg, thickness=10)
      @pointA = pointA
      @pointB = pointB
      @thickness = thickness
      @extension = extension

      @pointAExtended={
        x: @pointA.x + @thickness*(@extension == :neg ? -1 : 1),
        y: @pointA.y + @thickness*(@extension == :neg ? -1 : 1)
      }
      @pointBExtended={
        x: @pointB.x + @thickness*(@extension == :neg ? -1 : 1),
        y: @pointB.y + @thickness*(@extension == :neg ? -1 : 1)
      }

    end

    def resetPoints(pointA,pointB)
      @pointA = pointA
      @pointB = pointB

      @pointAExtended={
        x:@pointA.x + @thickness*(@extension == :neg ? -1 : 1),
        y:@pointA.y + @thickness*(@extension == :neg ? -1 : 1)
      }
      @pointBExtended={
        x:@pointB.x + @thickness*(@extension == :neg ? -1 : 1),
        y:@pointB.y + @thickness*(@extension == :neg ? -1 : 1)
      }
    end

    #TODO: Ugly function
    def slope (pointA, pointB)
      return (pointB.x==pointA.x) ? INFINITY : (pointB.y+-pointA.y)/(pointB.x+-pointA.x)
    end

    #TODO: Ugly function
    def intercept(pointA, pointB)
      if (slope(pointA, pointB) == INFINITY)
        -INFINITY
      elsif slope(pointA, pointB) == -1*INFINITY
        INFINITY
      else
        pointA.y+-1.0*(slope(pointA, pointB)*pointA.x)
      end
    end

    def calcY(pointA, pointB, x)
      return slope(pointA, pointB)*x + intercept(pointA, pointB)
    end

    #test if a collision has occurred
    def isCollision? (point)
      #INFINITY slop breaks down when trying to determin collision, ergo it requires a special test
      if slope(@pointA, @pointB) ==  INFINITY &&
        point.x >= [@pointA.x,@pointB.x].min+(@extension == :pos ? -@thickness : 0) &&
        point.x <= [@pointA.x,@pointB.x].max+(@extension == :neg ?  @thickness : 0) &&
        point.y >= [@pointA.y,@pointB.y].min && point.y <= [@pointA.y,@pointB.y].max
          return true
      end

      isNegInLine   = @extension == :neg &&
                      point.y <= slope(@pointA, @pointB)*point.x+intercept(@pointA,@pointB) &&
                      point.y >= point.x*slope(@pointAExtended, @pointBExtended)+intercept(@pointAExtended,@pointBExtended)
      isPosInLine   = @extension == :pos &&
                      point.y >= slope(@pointA, @pointB)*point.x+intercept(@pointA,@pointB) &&
                      point.y <= point.x*slope(@pointAExtended, @pointBExtended)+intercept(@pointAExtended,@pointBExtended)
      isInBoxBounds = point.x >= [@pointA.x,@pointB.x].min &&
                      point.x <= [@pointA.x,@pointB.x].max &&
                      point.y >= [@pointA.y,@pointB.y].min+(@extension == :neg ? -@thickness : 0) &&
                      point.y <= [@pointA.y,@pointB.y].max+(@extension == :pos ? @thickness : 0)

      return isInBoxBounds && (isNegInLine || isPosInLine)

    end

    def getRepelMagnitude (fbx, fby, vrx, vry, args)
      a = fbx ; b = vrx ; c = fby
      d = vry ; e = args.state.ball.velocity.mag

      if b**2 + d**2 == 0
        puts "magnitude error"
      end

      x1 = (-a*b+-c*d + (e**2 * b**2 - b**2 * c**2 + 2*a*b*c*d + e**2 + d**2 - a**2 * d**2)**0.5)/(b**2 + d**2)
      x2 = -((a*b + c*d + (e**2 * b**2 - b**2 * c**2 + 2*a*b*c*d + e**2 * d**2 - a**2 * d**2)**0.5)/(b**2 + d**2))
      return ((a+x1*b)**2 + (c+x1*d)**2 == e**2) ? x1 : x2
    end

    def update args
      #each of the four points on the square ball - NOTE simple to extend to a circle
      points= [ {x: args.state.ball.xy.x,                          y: args.state.ball.xy.y},
                {x: args.state.ball.xy.x+args.state.ball.width,    y: args.state.ball.xy.y},
                {x: args.state.ball.xy.x,                          y: args.state.ball.xy.y+args.state.ball.height},
                {x: args.state.ball.xy.x+args.state.ball.width,    y: args.state.ball.xy.y + args.state.ball.height}
              ]

      #for each point p in points
      for point in points
        #isCollision.md has more information on this section
        #TODO: section can certainly be simplifyed
        if isCollision?(point)
          u = Vector2d.new(1.0,((slope(@pointA, @pointB)==0) ? INFINITY : -1/slope(@pointA, @pointB))*1.0).normalize #normal perpendicular (to line segment) vector

          #the vector with the repeling force can be u or -u depending of where the ball was coming from in relation to the line segment
          previousBallPosition=Vector2d.new(point.x-args.state.ball.velocity.x,point.y-args.state.ball.velocity.y)
          choiceA = (u.mult(1))
          choiceB =  (u.mult(-1))
          vectorRepel = nil

          if (slope(@pointA, @pointB))!=INFINITY && u.y < 0
            choiceA, choiceB = choiceB, choiceA
          end
          vectorRepel = (previousBallPosition.y > calcY(@pointA, @pointB, previousBallPosition.x)) ? choiceA : choiceB

          #vectorRepel = (previousBallPosition.y > slope(@pointA, @pointB)*previousBallPosition.x+intercept(@pointA,@pointB)) ? choiceA : choiceB)
          if (slope(@pointA, @pointB) == INFINITY) #slope INFINITY breaks down in the above test, ergo it requires a custom test
            vectorRepel = (previousBallPosition.x > @pointA.x) ? (u.mult(1)) : (u.mult(-1))
          end
          #puts ("     " + $t[0].to_s + "," + $t[1].to_s + "    " + $t[2].to_s + "," + $t[3].to_s + "     " + "   " + u.x.to_s + "," + u.y.to_s)
          #vectorRepel now has the repeling force

          mag = args.state.ball.velocity.mag
          theta_ball=Math.atan2(args.state.ball.velocity.y,args.state.ball.velocity.x) #the angle of the ball's velocity
          theta_repel=Math.atan2(vectorRepel.y,vectorRepel.x) #the angle of the repeling force
          #puts ("theta:" + theta_ball.to_s + " " + theta_repel.to_s) #theta okay

          fbx = mag * Math.cos(theta_ball) #the x component of the ball's velocity
          fby = mag * Math.sin(theta_ball) #the y component of the ball's velocity

          repelMag = getRepelMagnitude(fbx, fby, vectorRepel.x, vectorRepel.y, args)

          frx = repelMag* Math.cos(theta_repel) #the x component of the repel's velocity | magnitude is set to twice of fbx
          fry = repelMag* Math.sin(theta_repel) #the y component of the repel's velocity | magnitude is set to twice of fby

          fsumx = fbx+frx #sum of x forces
          fsumy = fby+fry #sum of y forces
          fr = mag#fr is the resulting magnitude
          thetaNew = Math.atan2(fsumy, fsumx)  #thetaNew is the resulting angle
          xnew = fr*Math.cos(thetaNew) #resulting x velocity
          ynew = fr*Math.sin(thetaNew) #resulting y velocity

          args.state.ball.velocity = Vector2d.new(xnew,ynew)
          #args.state.ball.xy.add(args.state.ball.velocity)
          break #no need to check the other points ?
        else
        end
      end
    end #end update

  end

```

### Collision With Object Removal - main.rb
```ruby
  # ./samples/04_physics_and_collisions/10_collision_with_object_removal/app/main.rb
  # coding: utf-8
  INFINITY= 10**10
  WIDTH=1280
  HEIGHT=720

  require 'app/vector2d.rb'
  require 'app/paddle.rb'
  require 'app/ball.rb'
  require 'app/linear_collider.rb'

  #Method to init default values
  def defaults args
    args.state.game_board ||= [(args.grid.w / 2 - args.grid.w / 4), 0, (args.grid.w / 2), args.grid.h]
    args.state.bricks ||= []
    args.state.num_bricks ||= 0
    args.state.game_over_at ||= 0
    args.state.paddle ||= Paddle.new
    args.state.ball   ||= Ball.new
    args.state.westWall  ||= LinearCollider.new({x: args.grid.w/4,      y: 0},          {x: args.grid.w/4,      y: args.grid.h}, :pos)
    args.state.eastWall  ||= LinearCollider.new({x: 3*args.grid.w*0.25, y: 0},          {x: 3*args.grid.w*0.25, y: args.grid.h})
    args.state.southWall ||= LinearCollider.new({x: 0,                  y: 0},          {x: args.grid.w,        y: 0})
    args.state.northWall ||= LinearCollider.new({x: 0,                  y:args.grid.h}, {x: args.grid.w,        y: args.grid.h}, :pos)

    #args.state.testWall ||= LinearCollider.new({x:0 , y:0},{x:args.grid.w, y:args.grid.h})
  end

  #Render loop
  def render args
    render_instructions args
    render_board args
    render_bricks args
  end

  begin :render_methods
    #Method to display the instructions of the game
    def render_instructions args
      args.outputs.labels << [225, args.grid.h - 30, "← and → to move the paddle left and right",  0, 1]
    end

    def render_board args
      args.outputs.borders << args.state.game_board
    end

    def render_bricks args
      args.outputs.solids << args.state.bricks.map(&:rect)
    end
  end

  #Calls all methods necessary for performing calculations
  def calc args
    add_new_bricks args
    reset_game args
    calc_collision args
    win_game args

    args.state.westWall.update args
    args.state.eastWall.update args
    args.state.southWall.update args
    args.state.northWall.update args
    args.state.paddle.update args
    args.state.ball.update args

    #args.state.testWall.update args

    args.state.paddle.render args
    args.state.ball.render args
  end

  begin :calc_methods
    def add_new_bricks args
      return if args.state.num_bricks > 40

      #Width of the game board is 640px
      brick_width = (args.grid.w / 2) / 10
      brick_height = brick_width / 2

      (4).map_with_index do |y|
        #Make a box that is 10 bricks wide and 4 bricks tall
        args.state.bricks += (10).map_with_index do |x|
          args.state.new_entity(:brick) do |b|
            b.x = x * brick_width + (args.grid.w / 2 - args.grid.w / 4)
            b.y = args.grid.h - ((y + 1) * brick_height)
            b.rect = [b.x + 1, b.y - 1, brick_width - 2, brick_height - 2, 235, 50 * y, 52]

            #Add linear colliders to the brick
            b.collider_bottom = LinearCollider.new([(b.x-2), (b.y-5)], [(b.x+brick_width+1), (b.y-5)], :pos, brick_height)
            b.collider_right = LinearCollider.new([(b.x+brick_width+1), (b.y-5)], [(b.x+brick_width+1), (b.y+brick_height+1)], :pos)
            b.collider_left = LinearCollider.new([(b.x-2), (b.y-5)], [(b.x-2), (b.y+brick_height+1)], :neg)
            b.collider_top = LinearCollider.new([(b.x-2), (b.y+brick_height+1)], [(b.x+brick_width+1), (b.y+brick_height+1)], :neg)

            # @xyCollision  = LinearCollider.new({x: @x,y: @y+@height}, {x: @x+@width, y: @y+@height})
            # @xyCollision2 = LinearCollider.new({x: @x,y: @y}, {x: @x+@width, y: @y}, :pos)
            # @xyCollision3 = LinearCollider.new({x: @x,y: @y}, {x: @x, y: @y+@height})
            # @xyCollision4 = LinearCollider.new({x: @x+@width,y: @y}, {x: @x+@width, y: @y+@height}, :pos)

            b.broken = false

            args.state.num_bricks += 1
          end
        end
      end
    end

    def reset_game args
      if args.state.ball.xy.y < 20 && args.state.game_over_at.elapsed_time > 60
        #Freeze the ball
        args.state.ball.velocity.x = 0
        args.state.ball.velocity.y = 0
        #Freeze the paddle
        args.state.paddle.enabled = false

        args.state.game_over_at = Kernel.tick_count
      end

      if args.state.game_over_at.elapsed_time < 60 && Kernel.tick_count > 60 && args.state.bricks.count != 0
        #Display a "Game over" message
        args.outputs.labels << [100, 100, "GAME OVER", 10]
      end

      #If 60 frames have passed since the game ended, restart the game
      if args.state.game_over_at != 0 && args.state.game_over_at.elapsed_time == 60
        # FIXME: only put value types in state
        args.state.ball = Ball.new

        # FIXME: only put value types in state
        args.state.paddle = Paddle.new

        args.state.bricks = []
        args.state.num_bricks = 0
      end
    end

    def calc_collision args
      #Remove the brick if it is hit with the ball
      ball = args.state.ball
      ball_rect = [ball.xy.x, ball.xy.y, 20, 20]

      #Loop through each brick to see if the ball is colliding with it
      args.state.bricks.each do |b|
        if b.rect.intersect_rect?(ball_rect)
          #Run the linear collider for the brick if there is a collision
          b[:collider_bottom].update args
          b[:collider_right].update args
          b[:collider_left].update args
          b[:collider_top].update args

          b.broken = true
        end
      end

      args.state.bricks = args.state.bricks.reject(&:broken)
    end

    def win_game args
      if args.state.bricks.count == 0 && args.state.game_over_at.elapsed_time > 60
        #Freeze the ball
        args.state.ball.velocity.x = 0
        args.state.ball.velocity.y = 0
        #Freeze the paddle
        args.state.paddle.enabled = false

        args.state.game_over_at = Kernel.tick_count
      end

      if args.state.game_over_at.elapsed_time < 60 && Kernel.tick_count > 60 && args.state.bricks.count == 0
        #Display a "Game over" message
        args.outputs.labels << [100, 100, "CONGRATULATIONS!", 10]
      end
    end

  end

  def tick args
    defaults args
    render args
    calc args

    #args.outputs.lines << [0, 0, args.grid.w, args.grid.h]

    #$tc+=1
    #if $tc == 5
      #$train << [args.state.ball.xy.x, args.state.ball.xy.y]
      #$tc = 0
    #end
    #for t in $train

      #args.outputs.solids << [t[0],t[1],5,5,255,0,0];
    #end
  end

```

### Collision With Object Removal - paddle.rb
```ruby
  # ./samples/04_physics_and_collisions/10_collision_with_object_removal/app/paddle.rb
  class Paddle
    attr_accessor :enabled

    def initialize ()
      @x=WIDTH/2
      @y=100
      @width=100
      @height=20
      @speed=10

      @xyCollision  = LinearCollider.new({x: @x,y: @y+@height+5}, {x: @x+@width, y: @y+@height+5})
      @xyCollision2 = LinearCollider.new({x: @x,y: @y}, {x: @x+@width, y: @y}, :pos)
      @xyCollision3 = LinearCollider.new({x: @x,y: @y}, {x: @x, y: @y+@height+5})
      @xyCollision4 = LinearCollider.new({x: @x+@width,y: @y}, {x: @x+@width, y: @y+@height+5}, :pos)

      @enabled = true
    end

    def update args
      @xyCollision.resetPoints({x: @x,y: @y+@height+5}, {x: @x+@width, y: @y+@height+5})
      @xyCollision2.resetPoints({x: @x,y: @y}, {x: @x+@width, y: @y})
      @xyCollision3.resetPoints({x: @x,y: @y}, {x: @x, y: @y+@height+5})
      @xyCollision4.resetPoints({x: @x+@width,y: @y}, {x: @x+@width, y: @y+@height+5})

      @xyCollision.update  args
      @xyCollision2.update args
      @xyCollision3.update args
      @xyCollision4.update args

      args.inputs.keyboard.key_held.left  ||= false
      args.inputs.keyboard.key_held.right  ||= false

      if not (args.inputs.keyboard.key_held.left == args.inputs.keyboard.key_held.right)
        if args.inputs.keyboard.key_held.left && @enabled
          @x-=@speed
        elsif args.inputs.keyboard.key_held.right && @enabled
          @x+=@speed
        end
      end

      xmin =WIDTH/4
      xmax = 3*(WIDTH/4)
      @x = (@x+@width > xmax) ? xmax-@width : (@x<xmin) ? xmin : @x;
    end

    def render args
      args.outputs.solids << [@x,@y,@width,@height,255,0,0];
    end

    def rect
      [@x, @y, @width, @height]
    end
  end

```

### Collision With Object Removal - tests.rb
```ruby
  # ./samples/04_physics_and_collisions/10_collision_with_object_removal/app/tests.rb
  # For advanced users:
  # You can put some quick verification tests here, any method
  # that starts with the `test_` will be run when you save this file.

  # Here is an example test and game

  # To run the test: ./dragonruby mygame --eval app/tests.rb --no-tick

  class MySuperHappyFunGame
    attr_dr

    def tick
      outputs.solids << [100, 100, 300, 300]
    end
  end

  def test_universe args, assert
    game = MySuperHappyFunGame.new
    game.args = args
    game.tick
    assert.true!  args.outputs.solids.length == 1, "failure: a solid was not added after tick"
    assert.false! 1 == 2, "failure: some how, 1 equals 2, the world is ending"
    puts "test_universe completed successfully"
  end

  puts "running tests"
  DR.reset 100
  DR.log_level = :off
  DR.tests.start

```

### Collision With Object Removal - vector2d.rb
```ruby
  # ./samples/04_physics_and_collisions/10_collision_with_object_removal/app/vector2d.rb

  class Vector2d
    attr_accessor :x, :y

    def initialize x=0, y=0
      @x=x
      @y=y
    end

    #returns a vector multiplied by scalar x
    #x [float] scalar
    def mult x
      r = Vector2d.new(0,0)
      r.x=@x*x
      r.y=@y*x
      r
    end

    # vect [Vector2d] vector to copy
    def copy vect
      Vector2d.new(@x, @y)
    end

    #returns a new vector equivalent to this+vect
    #vect [Vector2d] vector to add to self
    def add vect
      Vector2d.new(@x+vect.x,@y+vect.y)
    end

    #returns a new vector equivalent to this-vect
    #vect [Vector2d] vector to subtract to self
    def sub vect
      Vector2d.new(@x-vect.c, @y-vect.y)
    end

    #return the magnitude of the vector
    def mag
      ((@x**2)+(@y**2))**0.5
    end

    #returns a new normalize version of the vector
    def normalize
      Vector2d.new(@x/mag, @y/mag)
    end

    #TODO delet?
    def distABS vect
      (((vect.x-@x)**2+(vect.y-@y)**2)**0.5).abs()
    end
  end

```

### Bouncing Ball With Gravity - main.rb
```ruby
  # ./samples/04_physics_and_collisions/11_bouncing_ball_with_gravity/app/main.rb
  class Game
    attr_dr

    def tick
      outputs.labels << { x: 30, y: 30.from_top,
                          text: "left/right arrow keys to spin, up arrow to jump, ctrl+r to reset, click two points to place terrain" }
      defaults
      calc
      render
    end

    def defaults
      state.terrain ||= []

      state.player ||= { x: 100,
                         y: 640,
                         dx: 0,
                         dy: 0,
                         radius: 12,
                         drag: 0.05477,
                         gravity: 0.03,
                         entropy: 0.9,
                         angle: 0,
                         facing: 1,
                         angle_velocity: 0,
                         elasticity: 0.5 }

      state.grid_points ||= (1280.idiv(40) + 1).flat_map do |x|
        (720.idiv(40) + 1).map do |y|
          { x: x * 40,
            y: y * 40,
            w: 40,
            h: 40,
            anchor_x: 0.5,
            anchor_y: 0.5 }
        end
      end
    end

    def calc
      player.y = 720  if player.y < 0
      player.x = 1280 if player.x < 0
      player.x = 0    if player.x > 1280
      player.angle_velocity = player.angle_velocity.clamp(-30, 30)
      calc_edit_mode
      calc_play_mode
    end

    def calc_edit_mode
      state.current_grid_point = Geometry.find_intersect_rect(inputs.mouse, state.grid_points)
      calc_edit_mode_click
    end

    def calc_edit_mode_click
      return if !state.current_grid_point
      return if !inputs.mouse.click

      if !state.start_point
        state.start_point = state.current_grid_point
      else
        state.terrain << { x: state.start_point.x,
                           y: state.start_point.y,
                           x2: state.current_grid_point.x,
                           y2: state.current_grid_point.y }
        state.start_point = nil
      end
    end

    def calc_play_mode
      player.x += player.dx
      player.dy -= player.gravity
      player.y += player.dy
      player.angle += player.angle_velocity
      player.dy += player.dy * player.drag ** 2 * -1
      player.dx += player.dx * player.drag ** 2 * -1
      player.colliding = false
      player.colliding_with = nil

      if inputs.keyboard.key_down.up
        player.dy += 5 * player.angle.vector_y
        player.dx += 5 * player.angle.vector_x
      end
      player.angle_velocity += inputs.left_right * -1
      player.facing = if inputs.left_right == -1
                        -1
                      elsif inputs.left_right == 1
                        1
                      else
                        player.facing
                      end

      collisions = player_terrain_collisions
      collisions.each do |collision|
        collide! player, collision
      end

      if player.colliding_with
        roll! player, player.colliding_with
      end
    end

    def reflect_velocity! circle, line
      slope = Geometry.line_slope line, replace_infinity: 1000
      slope_angle = Geometry.line_angle line
      if slope_angle == 90 || slope_angle == 270
        circle.dx *= -circle.elasticity
      else
        circle.angle_velocity += slope * (circle.dx.abs + circle.dy.abs)
        vec = line.x2 - line.x, line.y2 - line.y
        len = Math.sqrt(vec.x**2 + vec.y**2)

        vec.x /= len
        vec.y /= len

        n = Geometry.vec2_normal vec

        v_dot_n = Geometry.vec2_dot_product({ x: circle.dx, y: circle.dy }, n)

        circle.dx = circle.dx - n.x * (2 * v_dot_n)
        circle.dy = circle.dy - n.y * (2 * v_dot_n)
        circle.dx *= circle.elasticity
        circle.dy *= circle.elasticity
        half_terminal_velocity = 10
        impact_intensity = (circle.dy.abs) / half_terminal_velocity
        impact_intensity = 1 if impact_intensity > 1

        final = (0.9 - 0.8 * impact_intensity)
        next_angular_velocity = circle.angle_velocity * final
        circle.angle_velocity *= final

        if (circle.dx.abs + circle.dy.abs) <= 0.2
          circle.dx = 0
          circle.dy = 0
          circle.angle_velocity *= 0.99
        end

        if circle.angle_velocity.abs <= 0.1
          circle.angle_velocity = 0
        end
      end
    end

    def position_on_line! circle, line
      circle.colliding = true
      point = Geometry.line_normal line, circle
      if point.y > circle.y
        circle.colliding_from_above = true
      else
        circle.colliding_from_above = false
      end

      circle.colliding_with = line

      if !Geometry.point_on_line? point, line
        distance_from_start_of_line = Geometry.distance_squared({ x: line.x, y: line.y }, point)
        distance_from_end_of_line = Geometry.distance_squared({ x: line.x2, y: line.y2 }, point)
        if distance_from_start_of_line < distance_from_end_of_line
          point = { x: line.x, y: line.y }
        else
          point = { x: line.x2, y: line.y2 }
        end
      end
      angle = Geometry.angle_to point, circle
      circle.y = point.y + angle.vector_y * (circle.radius)
      circle.x = point.x + angle.vector_x * (circle.radius)
    end

    def collide! circle, line
      return if !line
      position_on_line! circle, line
      reflect_velocity! circle, line
      next_player = { x: player.x + player.dx,
                      y: player.y + player.dy,
                      radius: player.radius }
    end

    def roll! circle, line
      slope_angle = Geometry.line_angle line
      return if slope_angle == 90 || slope_angle == 270

      ax = -circle.gravity * slope_angle.vector_y
      ay = -circle.gravity * slope_angle.vector_x

      if ax.abs < 0.05 && ay.abs < 0.05
        ax = 0
        ay = 0
      end

      friction_coefficient = 0.0001
      friction_force = friction_coefficient * circle.gravity * slope_angle.vector_x

      circle.dy += ay
      circle.dx += ax

      if circle.colliding_from_above
        circle.dx += circle.angle_velocity * slope_angle.vector_x * 0.1
        circle.dy += circle.angle_velocity * slope_angle.vector_y * 0.1
      else
        circle.dx += circle.angle_velocity * slope_angle.vector_x * -0.1
        circle.dy += circle.angle_velocity * slope_angle.vector_y * -0.1
      end

      if circle.dx != 0
        circle.dx -= friction_force * (circle.dx / circle.dx.abs)
      end

      if circle.dy != 0
        circle.dy -= friction_force * (circle.dy / circle.dy.abs)
      end
    end

    def player_terrain_collisions
      terrain.find_all do |terrain|
               Geometry.circle_intersect_line? player, terrain
             end
             .sort_by do |terrain|
               if player.facing == -1
                 -terrain.x
               else
                 terrain.x
               end
             end
    end

    def render
      render_current_grid_point
      render_preview_line
      render_grid_points
      render_terrain
      render_player
      render_player_terrain_collisions
    end

    def render_player_terrain_collisions
      collisions = player_terrain_collisions
      outputs.lines << collisions.map do |collision|
                         { x: collision.x,
                           y: collision.y,
                           x2: collision.x2,
                           y2: collision.y2,
                           r: 255,
                           g: 0,
                           b: 0 }
                       end
    end

    def render_current_grid_point
      return if state.game_mode == :play
      return if !state.current_grid_point
      outputs.sprites << state.current_grid_point
                              .merge(w: 8,
                                     h: 8,
                                     anchor_x: 0.5,
                                     anchor_y: 0.5,
                                     path: :solid,
                                     g: 0,
                                     r: 0,
                                     b: 0,
                                     a: 128)
    end

    def render_preview_line
      return if state.game_mode == :play
      return if !state.start_point
      return if !state.current_grid_point

      outputs.lines << { x: state.start_point.x,
                         y: state.start_point.y,
                         x2: state.current_grid_point.x,
                         y2: state.current_grid_point.y }
    end

    def render_grid_points
      outputs
        .sprites << state
                      .grid_points
                      .map do |point|
        point.merge w: 8,
                    h: 8,
                    anchor_x: 0.5,
                    anchor_y: 0.5,
                    path: :solid,
                    g: 255,
                    r: 255,
                    b: 255,
                    a: 128
      end
    end

    def render_terrain
      outputs.lines << state.terrain
    end

    def render_player
      outputs.sprites << player_prefab
    end

    def player_prefab
      flip_horizontally = player.facing == -1
      { x: player.x,
        y: player.y,
        w: player.radius * 2,
        h: player.radius * 2,
        angle: player.angle,
        anchor_x: 0.5,
        anchor_y: 0.5,
        path: "sprites/circle/blue.png" }
    end

    def player
      state.player
    end

    def terrain
      state.terrain
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $terrain = args.state.terrain
    $game = nil
  end

```

### Ramp Collision - main.rb
```ruby
  # ./samples/04_physics_and_collisions/12_ramp_collision/app/main.rb
  # sample app shows how to do ramp collision
  # based off of the writeup here:
  # http://higherorderfun.com/blog/2012/05/20/the-guide-to-implementing-2d-platformers/

  # NOTE: at the bottom of the file you'll find DR.reset_and_replay "replay.txt"
  #       whenever you make changes to this file, a replay will automatically run so you can
  #       see how your changes affected the game. Comment out the line at the bottom if you
  #       don't want the replay to autmatically run.
  def tick args
    tick_toolbar args
    tick_game args
  end

  def tick_game args
    game_defaults args
    game_input args
    game_calc args
    game_render args
  end

  def game_input args
    # if space is pressed or held (signifying a jump)
    if args.inputs.keyboard.space
      # change the player's dy to the jump power if the
      # player is not currently touching a ceiling
      if !args.state.player.on_ceiling
        args.state.player.dy = args.state.player.jump_power
        args.state.player.on_floor = false
        args.state.player.jumping = true
      end
    else
      # if the space key is released, then jumping is false
      # and the player will no longer be on the ceiling
      args.state.player.jumping = false
      args.state.player.on_ceiling = false
    end

    # set the player's dx value to the left/right input
    # NOTE: that the speed of the player's dx movement has
    #       a sensitive relation ship with collision detection.
    #       If you increase the speed of the player, you may
    #       need to tweak the collision code to compensate for
    #       the extra horizontal speed.
    args.state.player.dx = args.inputs.left_right * 2
  end

  def game_render args
    # for each terrain entry, render the line that represents the connection
    # from the tile's left_height to the tile's right_height
    args.outputs.primitives << args.state.terrain.map { |t| t.line }

    # determine if the player sprite needs to be flipped hoizontally
    flip_horizontally = args.state.player.facing == -1

    # render the player
    args.outputs.sprites << args.state.player.merge(flip_horizontally: flip_horizontally)

    args.outputs.labels << {
      x: 640,
      y: 100,
      alignment_enum: 1,
      text: "Left and Right to move player. Space to jump. Use the toolbar at the top to add more terrain."
    }

    args.outputs.labels << {
      x: 640,
      y: 60,
      alignment_enum: 1,
      text: "Click any existing terrain on the map to delete it."
    }
  end

  def game_calc args
    # set the direction the player is facing based on the
    # the dx value of the player
    if args.state.player.dx > 0
      args.state.player.facing = 1
    elsif args.state.player.dx < 0
      args.state.player.facing = -1
    end

    # preform the calcuation of ramp collision
    calc_collision args

    # reset the player if the go off screen
    calc_off_screen args
  end

  def game_defaults args
    # how much gravity is in the game
    args.state.gravity ||= 0.1

    # initialized the player to the center of the screen
    args.state.player ||= {
      x: 640,
      y: 360,
      w: 16,
      h: 16,
      dx: 0,
      dy: 0,
      jump_power: 3,
      path: 'sprites/square/blue.png',
      on_floor: false,
      on_ceiling: false,
      facing: 1
    }
  end

  def calc_collision args
    # increment the players x position by the dx value
    args.state.player.x += args.state.player.dx

    # if the player is not on the floor
    if !args.state.player.on_floor
      # then apply gravity
      args.state.player.dy -= args.state.gravity
      # clamp the max dy value to -12 to 12
      args.state.player.dy = args.state.player.dy.clamp(-12, 12)

      # update the player's y position by the dy value
      args.state.player.y += args.state.player.dy
    end

    # get all colisions between the player and the terrain
    collisions = Geometry.find_all_intersect_rect args.state.player, args.state.terrain

    # if there are no collisions, then the player is not on the floor or ceiling
    # return from the method since there is nothing more to process
    if collisions.length == 0
      args.state.player.on_floor = false
      args.state.player.on_ceiling = false
      return
    end

    # set a local variable to the player since
    # we'll be accessing it a lot
    player = args.state.player

    # sort the collisions by the distance from the collision's center to the player's center
    sorted_collisions = collisions.sort_by do |collision|
      player_center = player.x + player.w / 2
      collision_center = collision.x + collision.w / 2
      (player_center - collision_center).abs
    end

    # define a one pixel wide rectangle that represents the center of the player
    # we'll use this value to determine the location of the player's feet on
    # a ramp
    player_center_rect = {
      x: player.x + player.w / 2 - 0.5,
      y: player.y,
      w: 1,
      h: player.h
    }

    # for each collision...
    sorted_collisions.each do |collision|
      # if the player doesn't intersect with the collision,
      # then set the player's on_floor and on_ceiling values to false
      # and continue to the next collision
      if !collision.intersect_rect? player_center_rect
        player.on_floor = false
        player.on_ceiling = false
        next
      end

      if player.dy < 0
        # if the player is falling
        # the percentage of the player's center relative to the collision
        # is a difference from the collision to the player (as opposed to the player to the collision)
        perc = (collision.x - player_center_rect.x) / player.w
        height_of_slope = collision.tile.left_height - collision.tile.right_height

        new_y = (collision.y + collision.tile.left_height + height_of_slope * perc)
        diff = new_y - player.y

        if diff < 0
          # if the current fall rate of the player is less than the difference
          # of the player's new y position and the player's current y position
          # then don't set the player's y position to the new y position
          # and wait for another application of gravity to bring the player a little
          # closer
          if player.dy.abs >= diff.abs
            # if the player's current fall speed can cover the distance to the
            # new y position, then set the player's y position to the new y position
            # and mark them as being on the floor so that gravity no longer get's processed
            player.y = new_y
            player.on_floor = true

            # given the player's speed, set the player's dy to a value that will
            # keep them from bouncing off the floor when the ramp is steep
            # NOTE: if you change the player's speed, then this value will need to be adjusted
            #       to keep the player from bouncing off the floor
            player.dy = -1
          end
        elsif diff > 0 && diff < 8
          # there's a small edge case where collision may be processed from
          # below the terrain (eg when the player is jumping up and hitting the
          # ramp from below). The moment when jump is released, the player's dy
          # value could result in the player tunneling through the terrain,
          # and get popped on to the top side.

          # testing to make sure the distance that will be displaced is less than
          # 8 pixels will keep this tunneling from happening
          player.y = new_y
          player.on_floor = true

          # given the player's speed, set the player's dy to a value that will
          # keep them from bouncing off the floor when the ramp is steep
          # NOTE: if you change the player's speed, then this value will need to be adjusted
          #       to keep the player from bouncing off the floor
          player.dy = -1
        end
      elsif player.dy > 0
        # if the player is jumping
        # the percentage of the player's center relative to the collision
        # is a difference is reversed from the player to the collision (as opposed to the player to the collision)
        perc = (player_center_rect.x - collision.x) / player.w

        # the height of the slope is also reversed when approaching the collision from the bottom
        height_of_slope = collision.tile.right_height - collision.tile.left_height

        new_y = collision.y + collision.tile.left_height + height_of_slope * perc

        # since this collision is being processed from below, the difference
        # between the current players position and the new y position is
        # based off of the player's top position (their head)
        player_top = player.y + player.h

        diff = new_y - player_top

        # we also need to calculate the difference between the player's bottom
        # and the new position. This will be used to determine if the player
        # can jump from the new_y position
        diff_bottom = new_y - player.y


        # if the player's current rising speed can cover the distance to the
        # new y position, then set the player's y position to the new y position
        # an mark them as being on the floor so that gravity no longer get's processed
        can_cover_distance_to_new_y = player.dy >= diff.abs && player.dy.sign == diff.sign

        # another scenario that needs to be covered is if the player's top is already passed
        # the new_y position (their rising speed made them partially clip through the collision)
        player_top_above_new_y = player_top > new_y

        # if either of the conditions above is true then we want to set the player's y position
        if can_cover_distance_to_new_y || player_top_above_new_y
          # only set the player's y position to the new y position if the player's
          # cannot escape the collision by jumping up from the new_y position
          if diff_bottom >= player.jump_power
            player.y = new_y.floor - player.h

            # after setting the new_y position, we need to determine if the player
            # if the player is touching the ceiling or not
            # touching the ceiling disables the ability for the player to jump/increase
            # their dy value any more than it already is
            if player.jumping
              # disable jumping if the player is currently moving upwards
              player.on_ceiling = true

              # NOTE: if you change the player's speed, then this value will need to be adjusted
              #       to keep the player from bouncing off the ceiling as they move right and left
              player.dy = 1
            else
              # if the player is not currently jumping, then set their dy to 0
              # so they can immediately start falling after the collision
              # this also means that they are no longer on the ceiling and can jump again
              player.dy = 0
              player.on_ceiling = false
            end
          end
        end
      end
    end
  end

  def calc_off_screen args
    below_screen = args.state.player.y + args.state.player.h < 0
    above_screen = args.state.player.y > 720 + args.state.player.h
    off_screen_left = args.state.player.x + args.state.player.w < 0
    off_screen_right = args.state.player.x > 1280

    # if the player is off the screen, then reset them to the top of the screen
    if below_screen || above_screen || off_screen_left || off_screen_right
      args.state.player.x = 640
      args.state.player.y = 720
      args.state.player.dy = 0
      args.state.player.on_floor = false
    end
  end

  def tick_toolbar args
    # ================================================
    # tollbar defaults
    # ================================================
    if !args.state.toolbar
      # these are the tiles you can select from
      tile_definitions = [
        { name: "16-12", left_height: 16, right_height: 12  },
        { name: "12-8",  left_height: 12, right_height: 8   },
        { name: "8-4",   left_height: 8,  right_height: 4   },
        { name: "4-0",   left_height: 4,  right_height: 0   },
        { name: "0-4",   left_height: 0,  right_height: 4   },
        { name: "4-8",   left_height: 4,  right_height: 8   },
        { name: "8-12",  left_height: 8,  right_height: 12  },
        { name: "12-16", left_height: 12, right_height: 16  },

        { name: "16-8",  left_height: 16, right_height: 8   },
        { name: "8-0",   left_height: 8,  right_height: 0   },
        { name: "0-8",   left_height: 0,  right_height: 8   },
        { name: "8-16",  left_height: 8,  right_height: 16  },

        { name: "0-0",   left_height: 0,  right_height: 0   },
        { name: "8-8",   left_height: 8,  right_height: 8   },
        { name: "16-16", left_height: 16, right_height: 16  },
      ]

      # toolbar data representation which will be used to render the toolbar.
      # the buttons array will be used to render the buttons
      # the toolbar_rect will be used to restrict the creation of tiles
      # within the toolbar area
      args.state.toolbar = {
        toolbar_rect: nil,
        buttons: []
      }

      # for each tile definition, create a button
      args.state.toolbar.buttons = tile_definitions.map_with_index do |spec, index|
        left_height  = spec.left_height
        right_height = spec.right_height
        button_size  = 48
        column_size  = 15
        column_padding = 2
        column = index % column_size
        column_padding = column * column_padding
        margin = 10
        row = index.idiv(column_size)
        row_padding = row * 2
        x = margin + column_padding + (column * button_size)
        y = (margin + button_size + row_padding + (row * button_size)).from_top

        # when a tile is added, the data of this button will be used
        # to construct the terrain

        # each tile has an x, y, w, h which represents the bounding box
        # of the button.
        # the button also contains the left_height and right_height which is
        # important when determining collision of the ramps
        {
          name: spec.name,
          left_height: left_height,
          right_height: right_height,
          button_rect: {
            x: x,
            y: y,
            w: 48,
            h: 48
          }
        }
      end

      # with the buttons populated, compute the bounding box of the entire
      # toolbar (again this will be used to restrict the creation of tiles)
      min_x = args.state.toolbar.buttons.map { |t| t.button_rect.x }.min
      min_y = args.state.toolbar.buttons.map { |t| t.button_rect.y }.min

      max_x = args.state.toolbar.buttons.map { |t| t.button_rect.x }.max
      max_y = args.state.toolbar.buttons.map { |t| t.button_rect.y }.max

      args.state.toolbar.rect = {
        x: min_x - 10,
        y: min_y - 10,
        w: max_x - min_x + 10 + 64,
        h: max_y - min_y + 10 + 64
      }
    end

    # set the selected tile to the last button in the toolbar
    args.state.selected_tile ||= args.state.toolbar.buttons.last

    # ================================================
    # starting terrain generation
    # ================================================
    if !args.state.terrain
      world = [
        { row: 14, col: 25, name: "0-8"   },
        { row: 14, col: 26, name: "8-16"  },
        { row: 15, col: 27, name: "0-8"   },
        { row: 15, col: 28, name: "8-16"  },
        { row: 16, col: 29, name: "0-8"   },
        { row: 16, col: 30, name: "8-16"  },
        { row: 17, col: 31, name: "0-8"   },
        { row: 17, col: 32, name: "8-16"  },
        { row: 18, col: 33, name: "0-8"   },
        { row: 18, col: 34, name: "8-16"  },
        { row: 18, col: 35, name: "16-12" },
        { row: 18, col: 36, name: "12-8"  },
        { row: 18, col: 37, name: "8-4"   },
        { row: 18, col: 38, name: "4-0"   },
        { row: 18, col: 39, name: "0-0"   },
        { row: 18, col: 40, name: "0-0"   },
        { row: 18, col: 41, name: "0-0"   },
        { row: 18, col: 42, name: "0-4"   },
        { row: 18, col: 43, name: "4-8"   },
        { row: 18, col: 44, name: "8-12"  },
        { row: 18, col: 45, name: "12-16" },
      ]

      args.state.terrain = world.map do |tile|
        template = tile_by_name(args, tile.name)
        next if !template
        grid_rect = grid_rect_for(tile.row, tile.col)
        new_terrain_definition(grid_rect, template)
      end
    end

    # ================================================
    # toolbar input and rendering
    # ================================================
    # store the mouse position alligned to the tile grid
    mouse_grid_aligned_rect = grid_aligned_rect args.inputs.mouse, 16

    # determine if the mouse intersects the toolbar
    mouse_intersects_toolbar = args.state.toolbar.rect.intersect_rect? args.inputs.mouse

    # determine if the mouse intersects a toolbar button
    toolbar_button = args.state.toolbar.buttons.find { |t| t.button_rect.intersect_rect? args.inputs.mouse }

    # determine if the mouse click occurred over a tile in the terrain
    terrain_tile = Geometry.find_intersect_rect mouse_grid_aligned_rect, args.state.terrain


    # if a mouse click occurs....
    if args.inputs.mouse.click
      if toolbar_button
        # if a toolbar button was clicked, set the currently selected tile to the toolbar tile
        args.state.selected_tile = toolbar_button
      elsif terrain_tile
        # if a tile was clicked, delete it from the terrain
        args.state.terrain.delete terrain_tile
      elsif !args.state.toolbar.rect.intersect_rect? args.inputs.mouse
        # if the mouse was not clicked in the toolbar area
        # add a new terrain based off of the information in the selected tile
        args.state.terrain << new_terrain_definition(mouse_grid_aligned_rect, args.state.selected_tile)
      end
    end

    # render a light blue background for the toolbar button that is currently
    # being hovered over (if any)
    if toolbar_button
      args.outputs.primitives << toolbar_button.button_rect.merge(primitive_marker: :solid, a: 64, b: 255)
    end

    # put a blue background around the currently selected tile
    args.outputs.primitives << args.state.selected_tile.button_rect.merge(primitive_marker: :solid, b: 255, r: 128, a: 64)

    if !mouse_intersects_toolbar
      if terrain_tile
        # if the mouse is hoving over an existing terrain tile, render a red border around the
        # tile to signify that it will be deleted if the mouse is clicked
        args.outputs.borders << terrain_tile.merge(a: 255, r: 255)
      else
        # if the mouse is not hovering over an existing terrain tile, render the currently
        # selected tile at the mouse position
        grid_aligned_rect = grid_aligned_rect args.inputs.mouse, 16

        args.outputs.solids << {
          **grid_aligned_rect,
          a: 30,
          g: 128
        }

        args.outputs.lines << {
          x:  grid_aligned_rect.x,
          y:  grid_aligned_rect.y + args.state.selected_tile.left_height,
          x2: grid_aligned_rect.x + grid_aligned_rect.w,
          y2: grid_aligned_rect.y + args.state.selected_tile.right_height,
        }
      end
    end

    # render each toolbar button using two primitives, a border to denote
    # the click area of the button, and a line to denote the terrain that
    # will be created when the button is clicked
    args.outputs.primitives << args.state.toolbar.buttons.map do |toolbar_tile|
      primitives = []
      scale = toolbar_tile.button_rect.w / 16

      primitive_type = :border

      [
        {
          **toolbar_tile.button_rect,
          primitive_marker: primitive_type,
          a: 64,
          g: 128
        },
        {
          x:  toolbar_tile.button_rect.x,
          y:  toolbar_tile.button_rect.y + toolbar_tile.left_height * scale,
          x2: toolbar_tile.button_rect.x + toolbar_tile.button_rect.w,
          y2: toolbar_tile.button_rect.y + toolbar_tile.right_height * scale
        }
      ]
    end
  end

  # ================================================
  # helper methods
  #=================================================

  # converts a row and column on the grid to
  # a rect
  def grid_rect_for row, col
    { x: col * 16, y: row * 16, w: 16, h: 16 }
  end

  # find a tile by name
  def tile_by_name args, name
    args.state.toolbar.buttons.find { |b| b.name == name }
  end

  # data structure containing terrain information
  # specifcially tile.left_height and tile.right_height
  def new_terrain_definition grid_rect, tile
    grid_rect.merge(
      tile: tile,
      line: {
        x:  grid_rect.x,
        y:  grid_rect.y + tile.left_height,
        x2: grid_rect.x + grid_rect.w,
        y2: grid_rect.y + tile.right_height
      }
    )
  end

  # helper method that returns a grid aligned rect given
  # an arbitrary rect and a grid size
  def grid_aligned_rect point, size
    grid_aligned_x = point.x - (point.x % size)
    grid_aligned_y = point.y - (point.y % size)
    { x: grid_aligned_x.to_i, y: grid_aligned_y.to_i, w: size.to_i, h: size.to_i }
  end

  DR.reset_and_replay "replay.txt", speed: 2

```

### Ramp Collision Simple - main.rb
```ruby
  # ./samples/04_physics_and_collisions/12_ramp_collision_simple/app/main.rb
  class Game
    attr :args

    def defaults
      state.terrain ||= [
        { x:   0,  y:  0, w: 128, h: 128, left_perc: 0,   right_perc: 0.5 },
        { x: 128,  y: 64, w: 128, h: 128, left_perc: 0,   right_perc: 1.0 },
        { x: 256,  y: 64, w: 128, h: 128, left_perc: 1.0, right_perc: 0 },
        { x: 384,  y: 64, w: 128, h: 128, left_perc: 0,   right_perc: 0 },
        { x: 512,  y: 64, w: 128, h: 128, left_perc: 0,   right_perc: 0 },
        { x: 640,  y:  0, w: 128, h: 128, left_perc: 0.5, right_perc: 0 },
        { x: 768,  y:  0, w: 128, h: 128, left_perc: 0,   right_perc: 1.0 },
      ]

      state.player ||= {
        x: 100,
        y: 720,
        w: 32,
        h: 32,
        dx: 0,
        dy: 0,
        on_ground: false
      }
    end

    def tick
      defaults
      calc
      render
    end

    def calc
      if inputs.keyboard.right
        player.dx = 2
      elsif inputs.keyboard.left
        player.dx = -2
      end

      if inputs.keyboard.key_down.space && player.on_ground
        player.dy = 8
        player.on_ground = false
      end

      if player.y + player.h < 0
        player.x = 100
        player.y = 720
      end

      player.prev_y = player.y
      player.x += player.dx
      player.dx *= 0.9
      player.dy -= 0.2
      player.dy = player.dy.clamp(-8, 8)
      player.y += player.dy
      collisions = Geometry.find_all_intersect_rect(player_feet_box, state.terrain)

      collision = collisions.map do |c|
        r = { rect: c, ramp_y: ramp_y_for_x(player.x, c) }
        r.delta_y = (player.y - (c.y + r.ramp_y))
        r
      end.sort_by { |c| c.delta_y.abs }.first # sort by the smallest ramp delta

      if collision
        if clipping_ramp?(player.y, collision)
          player.y = collision.rect.y + collision.ramp_y
          player.on_ground = true
        elsif player.on_ground
          player.dy = 0
          player.y = player.prev_y
          player.on_ground = false
        end
      elsif player.on_ground
        player.dy = 0
        player.y = player.prev_y
        player.on_ground = false
      end
    end

    def render
      outputs.background_color = [0, 0, 0]
      outputs.primitives << state.terrain.map { |t| ramp_prefab(t) }
      outputs.primitives << state.player.merge(path: :solid, r: 255, g: 255, b: 255, anchor_x: 0.5, anchor_y: 0)
      outputs.primitives << player_feet_box.merge(path: :solid, r: 255, g: 0, b: 0, anchor_x: 0.5, anchor_y: 0)
    end

    def clipping_ramp? y, ramp
      clip_height = 16
      y < ramp.rect.y + ramp.ramp_y && y + clip_height > ramp.rect.y + ramp.ramp_y
    end

    def ramp_y_for_x x, ramp
      rel_x = (x - ramp.x).fdiv ramp.w
      ((ramp.right_perc - ramp.left_perc) * rel_x + ramp.left_perc) * ramp.h
    end

    def outputs
      @args.outputs
    end

    def state
      @args.state
    end

    def inputs
      @args.inputs
    end

    def player
      state.player
    end

    def player_feet_box
      { x: player.x, y: player.y, w: 2, h: 16, anchor_x: 0.5, anchor_y: 0 }
    end

    def ramp_prefab ramp
      { x:  ramp.x,
        y:  ramp.y + ramp.h * ramp.left_perc,
        x2: ramp.x + ramp.w,
        y2: ramp.y + ramp.h * ramp.right_perc,
        r: 255,
        g: 0,
        b: 0 }
    end
  end

  def boot args
    args.state = {}
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
  end

```

### Verlet Integration - main.rb
```ruby
  # ./samples/04_physics_and_collisions/13_verlet_integration/app/main.rb
  # https://www.youtube.com/watch?v=-GWTDhOQU6M
  class Square
    attr :x, :y, :w, :h,
         :prev_x, :prev_y,
         :acceleration_x, :acceleration_y,
         :drag_x, :drag_y,
         :radius,
         :dx, :dy, :path, :start_acceleration_x, :start_acceleration_y

    def initialize(x:, y:, w:, h:, radius:, start_acceleration_x:, start_acceleration_y:, drag_x:, drag_y:)
      @x = x
      @y = y
      @w = w
      @h = h
      @radius = radius
      @start_acceleration_x = start_acceleration_x
      @start_acceleration_y = start_acceleration_y
      @acceleration_x = nil
      @acceleration_y = nil
      @drag_x = drag_x
      @drag_y = drag_y
      @path = "sprites/square/blue.png"
    end

    def tick dt
      @prev_x ||= @x
      @prev_y ||= @y
      if !@acceleration_x
        @acceleration_x = @start_acceleration_x
      else
        @acceleration_x = 0
      end

      if !@acceleration_y
        @acceleration_y = @start_acceleration_y
      else
        @acceleration_y = -0.25 * dt
      end

      if @y < 0
        @y = 0
      end

      if @x < 0
        @x = 0
      elsif (@x + @w) > 1280
        @x = 1280 - @w
      end

      dx = @x - @prev_x
      dy = @y - @prev_y
      dx += @acceleration_x * dt
      dy += @acceleration_y * dt
      dx *= @drag_x ** dt
      dy *= @drag_y ** dt

      @prev_x = @x
      @prev_y = @y
      @x += dx
      @y += dy
    end

    def prefab
      {x: @x, y: @y, w: @w, h: @h, path: @path,}
    end

    def center_x
      @x + @radius
    end

    def center_y
      @y + @radius
    end
  end

  class Game
    attr_dr

    def initialize
      @squares = []
    end

    def render
      outputs.watch "FPS: #{DR.current_framerate}"
      outputs.watch "Squares: #{@squares.length}"
      outputs.background_color = [30, 30, 30]
      outputs.primitives << @squares.map(&:prefab)
    end

    def calc_dt dt
      Array.each(@squares) do |object|
        object.tick dt
      end

      Geometry.each_intersect_rect(@squares, @squares) do |o_1, o_2|
        o_1_center_x = o_1.center_x
        o_1_center_y = o_1.center_y
        o_2_center_x = o_2.center_x
        o_2_center_y = o_2.center_y

        distance_x = o_1_center_x - o_2_center_x
        distance_y = o_1_center_y - o_2_center_y
        distance = Math.sqrt(distance_x * distance_x + distance_y * distance_y)

        if distance < o_1.radius + o_2.radius
          v_x = (o_2_center_x - o_1_center_x) / distance
          v_y = (o_2_center_y - o_1_center_y) / distance
          delta = o_1.radius + o_2.radius - distance

          o_1_dx = -0.75 * dt * delta * v_x * 0.5
          o_1_dy = -0.75 * dt * delta * v_y * 0.5
          o_1.x += o_1_dx
          o_1.y += o_1_dy

          o_2_dx = 0.75 * dt * delta * v_x * 0.5
          o_2_dy = 0.75 * dt * delta * v_y * 0.5
          o_2.x += o_2_dx
          o_2.y += o_2_dy
        end
      end
    end

    def calc
      if (inputs.mouse.click || inputs.mouse.held)
        mouse_x = inputs.mouse.x
        mouse_y = inputs.mouse.y

        angle = rand(360)
        acc_x = angle.vector_x * 20
        acc_y = angle.vector_y * 20

        @squares << Square.new(x: mouse_x - 8,
                               y: mouse_y - 8,
                               w: 16,
                               h: 16,
                               radius: 8,
                               start_acceleration_x: acc_x,
                               start_acceleration_y: acc_y,
                               drag_x: 0.95,
                               drag_y: 0.99)
      end

      calc_dt 0.5
      calc_dt 0.5
    end

    def tick
      calc
      render
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def sub_tick args
  end

  def reset args
    $game = nil
  end

  DR.reset

```

### Hookes Law Coulombs Law - main.rb
```ruby
  # ./samples/04_physics_and_collisions/14_hookes_law_coulombs_law/app/main.rb
  # Sample app demonstrates how to use Hooke's Law and Columb's Law
  # to render things to the screen without things overlapping
  def boot args
    args.state = {}
  end

  def tick args
    args.state.center_screen ||= { x: 640, y: 360 }
    args.state.particles ||= 10.map do
      { x: Numeric.rand(500..800),
        y: Numeric.rand(200..400),
        w: 16,
        h: 16,
        dx: Numeric.rand(-1.0..1.0),
        dy: Numeric.rand(-1.0..1.0),
        r: 128 * rand,
        g: 128 * rand,
        b: 128 * rand,
        path: :solid }
    end

    if args.inputs.mouse.click
      args.state.particles.push_back({ x: args.inputs.mouse.x - 8,
                                       y: args.inputs.mouse.y - 8,
                                       w: 16,
                                       h: 16,
                                       dx: Numeric.rand(-1.0..1.0),
                                       dy: Numeric.rand(-1.0..1.0),
                                       r: 128 * rand,
                                       g: 128 * rand,
                                       b: 128 * rand,
                                       path: :solid })
    end


    args.state.particles.each do |p1|
      hookes_law! p1, args.state.center_screen
      args.state.particles.each do |p2|
        next if p1 == p2
        coulombs_law! p1, p2
      end
    end

    args.state.particles.each do |p1|
      p1.dx = p1.dx.clamp(-2.5, 2.5)
      p1.dy = p1.dy.clamp(-2.5, 2.5)
      p1.x += p1.dx
      p1.y += p1.dy
      collide_edge! p1
    end

    collisions = false

    Geometry.each_intersect_rect(args.state.particles, args.state.particles) do |p1, p2|
      collisions = true
    end

    if !collisions
      args.state.particles.each do |p1|
        p1.dx *= 0.95
        p1.dy *= 0.95
      end
    end

    args.outputs.sprites << args.state.particles
    args.outputs.labels << { x: 640,
                             y: 360,
                             text: "Click to add particles",
                             anchor_x: 0.5,
                             anchor_y: 0.5 }
  end

  def hookes_law! p1, p2
    dx = p2.x - p1.x
    dy = p2.y - p1.y
    distance = Math.sqrt(dx * dx + dy * dy)
    force = (distance - 100) / 100.0 * 0.01

    if distance > 0
      p1.dx += (dx / distance) * force
      p1.dy += (dy / distance) * force
    end
  end

  def coulombs_law! p1, p2
    dx = p2.x - p1.x
    dy = p2.y - p1.y
    distance = Math.sqrt(dx * dx + dy * dy)
    return if distance < 1
    force = 20 / (distance * distance)

    dx_force = (dx / distance) * force
    dy_force = (dy / distance) * force

    p1.dx -= dx_force
    p1.dy -= dy_force
    p2.dx += dx_force
    p2.dy += dy_force
  end

  def collide_edge! p1
    if p1.x < 0
      p1.x = 0
      p1.dx *= -1
    elsif p1.x > 1280 - p1.w
      p1.x = 1280 - p1.w
      p1.dx *= -1
    end

    if p1.y < 0
      p1.y = 0
      p1.dy *= -1
    elsif p1.y > 720 - p1.h
      p1.y = 720 - p1.h
      p1.dy *= -1
    end
  end

```
