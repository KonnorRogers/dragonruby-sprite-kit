### Lowrez Labels - main.rb
```ruby
  # ./samples/99_genre_lowrez/lowrez_labels/app/main.rb
  # sample app demonstrates how fonts are rendered at the top level and within a low rez render target
  class Game
    attr_gtk

    def tick
      outputs.primitives << Layout.rect(row: 0, col: 0, w: 4, h: 4)
                                  .merge(path: :solid, r: 128, g: 128, b: 128, w: 16, h: 16)
      outputs.primitives << Layout.rect(row: 0, col: 0, w: 4, h: 4)
                                  .merge(text: "+", font: "fonts/lowrez.ttf", anchor_x: 0, anchor_y: 0, size_px: 16)

      outputs.primitives << Layout.rect(row: 0, col: 4, w: 4, h: 4)
                                  .merge(path: :solid, r: 128, g: 128, b: 128, w: 32, h: 32)
      outputs.primitives << Layout.rect(row: 0, col: 4, w: 4, h: 4)
                                  .merge(text: "+", font: "fonts/lowrez.ttf", anchor_x: 0, anchor_y: 0, size_px: 32)

      outputs.primitives << Layout.rect(row: 0, col: 8, w: 4, h: 4)
                                  .merge(path: :solid, r: 128, g: 128, b: 128, w: 64, h: 64)
      outputs.primitives << Layout.rect(row: 0, col: 8, w: 4, h: 4)
                                  .merge(text: "+", font: "fonts/lowrez.ttf", anchor_x: 0, anchor_y: 0, size_px: 64)

      outputs.primitives << Layout.rect(row: 0, col: 12, w: 4, h: 4)
                                  .merge(path: :solid, r: 128, g: 128, b: 128, w: 128, h: 128)
      outputs.primitives << Layout.rect(row: 0, col: 12, w: 4, h: 4)
                                  .merge(text: "+", font: "fonts/lowrez.ttf", anchor_x: 0, anchor_y: 0, size_px: 128)

      # to avoid visual artifacts, you want to scale render targets down to smaller powers of two
      # otherwise labels will have rendering artifacts
      # for lowrez games, be sure that your RT size is always a power of two and are scaled by a power of two
      outputs[:lowrez_text].w = 128
      outputs[:lowrez_text].h = 128
      outputs[:lowrez_text].primitives << { x: 0, y: 0, w: 128, h: 128, r: 128, g: 128, b: 128, path: :solid }
      outputs[:lowrez_text].primitives << { x: 0, y: 0, anchor_y: 0, anchor_y: 0, text: "+", size_px: 128, font: "fonts/lowrez.ttf" }

      outputs.primitives << Layout.rect(row: 0, col: 1, w: 4, h: 4)
                                  .merge(path: :lowrez_text, w: 16, h: 16) # 128 scaled down to 16x16

      outputs.primitives << Layout.rect(row: 0, col: 3, w: 4, h: 4)
                                  .merge(path: :lowrez_text, w: 32, h: 32) # 128 scaled down to 32x32

      outputs.primitives << Layout.rect(row: 0, col: 10, w: 4, h: 4)
                                  .merge(path: :lowrez_text, w: 64, h: 64) # 128 scaled down to 64x64

      outputs.primitives << Layout.rect(row: 0, col: 15, w: 4, h: 4)
                                  .merge(path: :lowrez_text, w: 128, h: 128)

      outputs.primitives << Layout.debug_primitives
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

  GTK.reset

```

### Nokia 3310 - main.rb
```ruby
  # ./samples/99_genre_lowrez/nokia_3310/app/main.rb
  # this file sets up the main game loop (no need to modify it)
  require "app/nokia_emulation.rb"

  # here is your main game class
  # your game code will go here
  class Game
    attr :args, :nokia_mouse_position

    def tick
      # uncomment the methods below on at a time to see the examples in action
      # (be sure to comment out the other methods to avoid conflicts)

      hello_world

      # how_to_render_a_label

      # how_to_render_solids

      # how_to_render_sprites

      # how_to_animate_a_sprite

      # how_to_animate_a_sprite_sheet

      # how_to_determine_collision

      # how_to_create_buttons

      # shooter_game
    end

    def hello_world
      # your canvas is 84x48

      # render a label at center x, near the top (centered horizontally is done by setting anchor_x: 0.5)
      nokia.labels << {
        x: 84 / 2,
        y: 48 - 6,
        text: "nokia 3310 jam 3",
        size_px: 5, # size_px of 5 is a small font size, 10 is medium, 15 is large, 20 is extra large
        font: "fonts/lowrez.ttf",
        anchor_x: 0.5,
        anchor_y: 0
      }

      # render a sprite at the center of the screen
      # and make it rotate
      nokia.sprites << {
        x: 84 / 2 - 10,
        y: 48 / 2 - 10,
        w: 20,
        h: 20,
        path: "sprites/monochrome-ship.png",
        angle: Kernel.tick_count % 360,
      }
    end

    def how_to_render_a_label
      # Render a small label (size_px: 5)
      nokia.labels << { x: 1,
                        y: 0,
                        text: "SMALL",
                        anchor_x: 0,
                        anchor_y: 0,
                        size_px: 5,
                        font: "fonts/lowrez.ttf" }

      # Render a medium label (size_px: 10)
      nokia.labels << { x: 1,
                        y: 5,
                        text: "MEDIUM",
                        anchor_x: 0,
                        anchor_y: 0,
                        size_px: 10,
                        font: "fonts/lowrez.ttf" }

      # Render a large label (size_px: 15)
      nokia.labels << { x: 1,
                        y: 14,
                        text: "LARGE",
                        anchor_x: 0,
                        anchor_y: 0,
                        size_px: 15,
                        font: "fonts/lowrez.ttf" }

      # Render an extra large label (size_px: 20)
      nokia.labels << { x: 1,
                        y: 27,
                        text: "EXTRA LARGE",
                        anchor_x: 0,
                        anchor_y: 0,
                        size_px: 20,
                        font: "fonts/lowrez.ttf" }

      # You can use the helper functions sm_label, md_label, lg_label, xl_label
      # which returns a Hash that you can ~merge~ properties with
      # Example:
      nokia.labels << sm_label.merge(x: 40, text: "Default")
    end

    def how_to_render_solids
      # Render a square at 0, 0 with a width and height of 1 (setting path to :solid will render a solid color)
      nokia.sprites << { x: 0, y: 0, w: 1, h: 1, path: :solid, r: 0, g: 0, b: 0 }

      # Render a square at 1, 1 with a width and height of 2
      nokia.sprites << { x: 1, y: 1, w: 2, h: 2, path: :solid, r: 0, g: 0, b: 0 }

      # Render a square at 3, 3 with a width and height of 3
      nokia.sprites << { x: 3, y: 3, w: 3, h: 3, path: :solid, r: 0, g: 0, b: 0 }

      # Render a square at 6, 6 with a width and height of 4
      nokia.sprites << { x: 6, y: 6, w: 4, h: 4, path: :solid, r: 0, g: 0, b: 0 }
    end

    def how_to_render_sprites
      # add a sprite to the screen 10 times
      10.times do |i|
        nokia.sprites << {
          x: i * 8.4,
          y: i * 4.8,
          w: 5,
          h: 5,
          path: 'sprites/monochrome-ship.png'
        }
      end

      # add a sprite based on a position
      positions = [
        { x: 20, y: 32 },
        { x: 45, y: 15 },
        { x: 72, y: 23 },
      ]

      positions.each do |position|
        # use Ruby's ~Hash#merge~ function to create a sprite
        nokia.sprites << position.merge(path: 'sprites/monochrome-ship.png',
                                        w: 5,
                                        h: 5)
      end
    end

    def how_to_animate_a_sprite
      start_animation_on_tick = 180


      # Get the frame_index given start_at, frame_count, hold_for, and repeat
      sprite_index = Numeric.frame_index start_at: start_animation_on_tick,  # when to start the animation?
                                         frame_count: 7,                     # how many sprites?
                                         hold_for: 8,                        # how long to hold each sprite?
                                         repeat: true                        # should it repeat?

      # render the current tick and the resolved sprite index
      nokia.labels  << sm_label.merge(x: 84 / 2,
                                      y: 48 - 6,
                                      text: "Tick: #{Kernel.tick_count}",
                                      anchor_x: 0.5)

      nokia.labels  << sm_label.merge(x: 84 / 2,
                                      y: 48 - 12,
                                      text: "sprite_index: #{sprite_index || 'nil'}",
                                      anchor_x: 0.5)

      # Numeric.frame_index will return nil if the frame hasn't arrived yet
      if sprite_index
        # if the sprite_index is populated, use it to determine the sprite path and render it
        sprite_path  = "sprites/explosion-#{sprite_index}.png"
        nokia.sprites << { x: 84 / 2 - 16,
                           y: 48 / 2 - 16,
                           w: 32,
                           h: 32,
                           path: sprite_path }
      else
        # if the sprite_index is nil, render a countdown instead
        countdown_in_seconds = ((start_animation_on_tick - Kernel.tick_count) / 60).round(1)

        nokia.labels  << sm_label.merge(x: 84 / 2,
                                        y: 48 / 2,
                                        text: "Count Down: #{countdown_in_seconds.to_sf}",
                                        anchor_x: 0.5,
                                        anchor_y: 0.5)
      end
    end

    def how_to_animate_a_sprite_sheet
      start_animation_on_tick = 180


      # Get the frame_index given start_at, frame_count, hold_for, and repeat
      sprite_index = Numeric.frame_index start_at: start_animation_on_tick,  # when to start the animation?
                                         frame_count: 7,                     # how many sprites?
                                         hold_for: 8,                        # how long to hold each sprite?
                                         repeat: true                        # should it repeat?

      # render the current tick and the resolved sprite index
      nokia.labels  << sm_label.merge(x: 84 / 2,
                                      y: 48 - 6,
                                      text: "Tick: #{Kernel.tick_count}",
                                      anchor_x: 0.5)

      nokia.labels  << sm_label.merge(x: 84 / 2,
                                      y: 48 - 12,
                                      text: "sprite_index: #{sprite_index || 'nil'}",
                                      anchor_x: 0.5)

      # Numeric.frame_index will return nil if the frame hasn't arrived yet
      if sprite_index
        # if the sprite_index is populated, use it to determine the sprite path and render it
        nokia.sprites << {
          x: 84 / 2 - 16,
          y: 48 / 2 - 16,
          w: 32,
          h: 32,
          path:  "sprites/explosion-sheet.png",
          source_x: 32 * sprite_index,
          source_y: 0,
          source_w: 32,
          source_h: 32
        }
      else
        # if the sprite_index is nil, render a countdown instead
        countdown_in_seconds = ((start_animation_on_tick - Kernel.tick_count) / 60).round(1)

        nokia.labels  << sm_label.merge(x: 84 / 2,
                                        y: 48 / 2,
                                        text: "Count Down: #{countdown_in_seconds.to_sf}",
                                        anchor_x: 0.5,
                                        anchor_y: 0.5)
      end
    end

    def how_to_determine_collision
      # game state is stored in the state variable

      # Render the instructions
      if !state.ship_one
        # if game state's ship one isn't initialized, render the instructions to place ship one
        nokia.labels << sm_label.merge(x: 42,
                                       y: 48 - 6,
                                       text: "CLICK: PLACE SHIP 1",
                                       anchor_x: 0.5)
      elsif !state.ship_two
        # if game state's ship one isn't initialized, render the instructions to place ship one
        nokia.labels << sm_label.merge(x: 42,
                                       y: 48 - 6,
                                       text: "CLICK: PLACE SHIP 2",
                                       anchor_x: 0.5)
      else
        # otherwise, render the instructions to reset the ships
        nokia.labels << sm_label.merge(x: 42,
                                       y: 48 - 6,
                                       text: "CLICK: RESET SHIPS",
                                       anchor_x: 0.5)
      end

      # if a mouse click occurs:
      # - set ship_one if it isn't set
      # - set ship_two if it isn't set
      # - otherwise reset ship one and ship two
      if inputs.mouse.click
        # is ship_one set?
        if !state.ship_one
          # set ship_one to the mouse position
          state.ship_one = { x: nokia_mouse_position.x - 5,
                             y: nokia_mouse_position.y - 5,
                             w: 10,
                             h: 10 }
        # is ship_one set?
        elsif !state.ship_two
          # set ship_two to the mouse position
          state.ship_two = { x: nokia_mouse_position.x - 5,
                             y: nokia_mouse_position.y - 5,
                             w: 10,
                             h: 10 }
        # should we reset?
        else
          state.ship_one = nil
          state.ship_two = nil
        end
      end

      # render ship one if it's set
      if state.ship_one
        # use Ruby's .merge method which is available on ~Hash~ to set the sprite
        # render ship one
        nokia.sprites << state.ship_one.merge(path: 'sprites/monochrome-ship.png')
      end

      if state.ship_two
        # use Ruby's .merge method which is available on ~Hash~ to set the sprite
        # render ship two
        nokia.sprites << state.ship_two.merge(path: 'sprites/monochrome-ship.png')
      end

      # if both ship one and ship two are set, then determine collision
      if state.ship_one && state.ship_two
        # collision is determined using the intersect_rect? method
        if Geometry.intersect_rect?(state.ship_one, state.ship_two)
          # if collision occurred, render the words collision!
          nokia.labels << sm_label.merge(x: 84 / 2,
                                         y: 5,
                                         text: "Collision!",
                                         anchor_x: 0.5)
        else
          # if collision occurred, render the words no collision.
          nokia.labels << sm_label.merge(x: 84 / 2,
                                         y: 5,
                                         text: "No Collision.",
                                         anchor_x: 0.5)
        end
      else
        # render overlay sprite
        nokia.sprites << { x: nokia_mouse_position.x - 5,
                           y: nokia_mouse_position.y - 5,
                           w: 10,
                           h: 10,
                           path: :solid,
                           r: 0,
                           g: 0,
                           b: 0,
                           a: 128 }

        # if both ship one and ship two aren't set, then render -- (waiting for input before collision can be determined)
        nokia.labels << sm_label.merge(x: 84 / 2,
                                       y: 6,
                                       text: "--",
                                       anchor_x: 0.5)
      end
    end

    def how_to_create_buttons
      # Render instructions
      nokia.labels << sm_label.merge(x: 84 / 2,
                                     y: 48 - 3,
                                     text: "Press a Button!",
                                     anchor_x: 0.5,
                                     anchor_y: 0.5)


      # Create button one using a border and a label
      state.button_one_border ||= { x: 1, y: 28, w: 82, h: 10 }
      nokia.borders << state.button_one_border
      nokia.labels << sm_label.merge(x: state.button_one_border.x + state.button_one_border.w / 2,
                                     y: state.button_one_border.y + state.button_one_border.h / 2,
                                     anchor_x: 0.5,
                                     anchor_y: 0.5,
                                     text: "Button One")

      # Create button two using a border and a label
      state.button_two_border ||= { x: 1, y: 12, w: 82, h: 10 }
      nokia.borders << state.button_two_border
      nokia.labels << sm_label.merge(x: state.button_two_border.x + state.button_two_border.w / 2,
                                     y: state.button_two_border.y + state.button_two_border.h / 2,
                                     anchor_x: 0.5,
                                     anchor_y: 0.5,
                                     text: "Button Two")

      # Initialize the state variable that tracks which button was clicked to "" (empty stringI
      state.last_button_clicked ||= "--"

      # If a click occurs, check to see if either button one, or button two was clicked
      # using the inside_rect? method of the mouse
      # set state.last_button_clicked accordingly
      if inputs.mouse.click
        if Geometry.inside_rect?(nokia_mouse_position, state.button_one_border)
          state.last_button_clicked = "Button One Clicked!"
        elsif Geometry.inside_rect?(nokia_mouse_position, state.button_two_border)
          state.last_button_clicked = "Button Two Clicked!"
        else
          state.last_button_clicked = "--"
        end
      end

      # Render the current value of state.last_button_clicked
      nokia.labels << sm_label.merge(x: 84 / 2,
                                     y: 0,
                                     text: state.last_button_clicked,
                                     anchor_x: 0.5)
    end

    def shooter_game
      # render instructions
      nokia.labels << sm_label.merge(x: 84 / 2,
                                     y: 0,
                                     text: "Move: WASD/ARROWS",
                                     anchor_y: 0,
                                     anchor_x: 0.5)

      nokia.labels << sm_label.merge(x: 84 / 2,
                                     y: 0,
                                     text: "Space: Shoot",
                                     anchor_y: -1.0,
                                     anchor_x: 0.5)

      # initialize game state
      state.bullets ||= [] # array representing bullets
      state.targets ||= [] # array representing targets
      state.ship ||= { x: 0, y: 0, w: 10, h: 10 } # hash representing the ship

      # if space is pressed, add a bullet to the bullets array
      if inputs.keyboard.key_down.space
        state.bullets << {
          x: state.ship.x + state.ship.w / 2 - 1,
          y: state.ship.y + state.ship.h - 1,
          w: 2,
          h: 2
        }
      end

      # if a or left arrow is pressed/held, decrement the ships x position
      if inputs.keyboard.left
        state.ship.x -= 1
      end

      # if d or right arrow is pressed/held, increment the ships x position
      if inputs.keyboard.right
        state.ship.x += 1
      end

      # if s or down arrow is pressed/held, decrement the ships y position
      if inputs.keyboard.down
        state.ship.y -= 1
      end

      # if w or up arrow is pressed/held, increment the ships y position
      if inputs.keyboard.up
        state.ship.y += 1
      end

      # if there are no targets, add 10 targets to the targets array
      if state.targets.length == 0
        10.times do
          state.targets << {
            x: rand(70) + 10,
            y: rand(25) + 20,
            w: 3,
            h: 3
          }
        end
      end

      # move each bullet upwards
      state.bullets.each do |bullet|
        bullet.y += 1
      end

      # remove bullets that are off screen
      state.bullets.reject! do |bullet|
        bullet.y > 48
      end

      # for each bullet, check if it intersects with a target
      # if it does, remove the bullet and the target
      state.bullets.each do |bullet|
        state.targets.each do |target|
          if Geometry.intersect_rect?(bullet, target)
            state.bullets.delete bullet
            state.targets.delete target
          end
        end
      end

      # render the bullets
      nokia.sprites << state.bullets.map do |bullet|
        {
          x: bullet.x,
          y: bullet.y,
          w: bullet.w,
          h: bullet.h,
          path: :solid,
          r: 0,
          g: 0,
          b: 0
        }
      end

      # render the targets
      nokia.sprites << state.targets.map do |target|
        {
          x: target.x,
          y: target.y,
          w: target.w,
          h: target.w,
          path: :solid,
          r: 0,
          g: 0,
          b: 0
        }
      end

      # render the sprite to the screen using the position stored in state.ship
      nokia.sprites << {
        x: state.ship.x,
        y: state.ship.y,
        w: state.ship.w,
        h: state.ship.h,
        path: 'sprites/monochrome-ship.png',
        # parameters beyond this point are optional
        angle: 0, # Note: rotation angle is denoted in degrees NOT radians
        r: 0,
        g: 0,
        b: 0,
        a: 255
      }
    end

    def sm_label
      { x: 0, y: 0, size_px: 5, font: "fonts/lowrez.ttf", anchor_x: 0, anchor_y: 0 }
    end

    def md_label
      { x: 0, y: 0, size_px: 10, font: "fonts/lowrez.ttf", anchor_x: 0, anchor_y: 0 }
    end

    def lg_label
      { x: 0, y: 0, size_px: 15, font: "fonts/lowrez.ttf", anchor_x: 0, anchor_y: 0 }
    end

    def xl_label
      { x: 0, y: 0, size_px: 20, font: "fonts/lowrez.ttf", anchor_x: 0, anchor_y: 0 }
    end

    def nokia
      outputs[:nokia]
    end

    def outputs
      @args.outputs
    end

    def inputs
      @args.inputs
    end

    def state
      @args.state
    end
  end

  # DR.reset will reset your entire game
  # it's useful for debugging and starting fresh
  # comment this line out if you want to retain your
  # current game state in between hot reloads
  DR.reset

```

### Nokia 3310 - nokia_emulation.rb
```ruby
  # ./samples/99_genre_lowrez/nokia_3310/app/nokia_emulation.rb
  # Logical canvas width and height
  WIDTH = 1280
  HEIGHT = 720

  # Nokia screen dimensions
  NOKIA_WIDTH = 84
  NOKIA_HEIGHT = 48

  # Determine best fit zoom level
  ZOOM_WIDTH = (WIDTH / NOKIA_WIDTH).floor
  ZOOM_HEIGHT = (HEIGHT / NOKIA_HEIGHT).floor
  ZOOM = [ZOOM_WIDTH, ZOOM_HEIGHT].min

  # Compute the offset to center the Nokia screen
  OFFSET_X = (WIDTH - NOKIA_WIDTH * ZOOM) / 2
  OFFSET_Y = (HEIGHT - NOKIA_HEIGHT * ZOOM) / 2

  # Compute the scaled dimensions of the Nokia screen
  ZOOMED_WIDTH = NOKIA_WIDTH * ZOOM
  ZOOMED_HEIGHT = NOKIA_HEIGHT * ZOOM

  def boot args
    args.state = {}
  end

  def tick args
    # set the background color to black
    args.outputs.background_color = [0, 0, 0]

    # define a render target that represents the Nokia screen
    args.outputs[:nokia].w = 84
    args.outputs[:nokia].h = 48
    args.outputs[:nokia].background_color = [199, 240, 216]

    # new up the game if it hasn't been created yet
    $game ||= Game.new

    # pass args environment to the game
    $game.args = args

    # compute the mouse position in the Nokia screen
    $game.nokia_mouse_position = {
      x: (args.inputs.mouse.x - OFFSET_X).idiv(ZOOM),
      y: (args.inputs.mouse.y - OFFSET_Y).idiv(ZOOM),
      w: 1,
      h: 1,
    }

    # update the game
    $game.tick

    # render the game scaled to fit the screen
    args.outputs.sprites << {
      x: WIDTH / 2,
      y: HEIGHT / 2,
      w: ZOOMED_WIDTH,
      h: ZOOMED_HEIGHT,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: :nokia,
    }
  end

  # if DR.reset is called
  # clear out the game so that it can be re-initialized
  def reset args
    $game = nil
  end

```

### Nokia 33snake - main.rb
```ruby
  # ./samples/99_genre_lowrez/nokia_3310_snake/app/main.rb
  # this file sets up the main game loop (no need to modify it)
  require "app/nokia_emulation.rb"

  class Game
    attr :args, :nokia_mouse_position

    def tick
      # create a new game on frame zero
      new_game if Kernel.tick_count == 0
      # calc game
      calc
      # render game
      render
      # increment the clock
      state.clock += 1
    end

    def calc
      calc_game
      calc_restart
    end

    def calc_game
      # return if the game is over
      return if state.game_over

      # return if the game is just starting
      return if state.clock < 30

      # begin capturing input after the initial countdown
      if inputs.keyboard.left && snake.direction.x == 0
        # if keyboard left is pressed or held, and
        # if the snake is not moving left or right,
        # set the next direction to left
        snake.next_direction = { x: -1, y: 0 }
        snake.next_angle = 180
      elsif inputs.keyboard.right && snake.direction.x == 0
        # if keyboard right is pressed or held, and
        # if the snake is not moving left or right,
        # set the next direction to right
        snake.next_direction = { x: 1, y: 0 }
        snake.next_angle = 0
      end

      if inputs.keyboard.up && snake.direction.y == 0
        # if keyboard up is pressed or held, and
        # if the snake is not moving up or down,
        # set the next direction to up
        snake.next_direction = { x: 0, y: 1 }
        snake.next_angle = 90
      elsif inputs.keyboard.down && snake.direction.y == 0
        # if keyboard down is pressed or held, and
        # if the snake is not moving up or down,
        # set the next direction to down
        snake.next_direction = { x: 0, y: -1 }
        snake.next_angle = 270
      end

      # return if the game is in the initial countdown
      return if state.clock < 60

      # process the movement of the snake every 15 frames
      return if !state.clock.zmod?(15)

      # add a new segment to the end of the snake
      snake.body.push_back({ x: snake.head.x, y: snake.head.y })

      # update the snake's direction based on what input was captured
      snake.direction = { **snake.next_direction }

      # update the snake's angle based on what input was captured (for rendering)
      snake.angle = snake.next_angle

      # update the snake's head position based on its direction
      snake.head = { x: snake.head.x + snake.direction.x,
                     y: snake.head.y + snake.direction.y }

      # check if the snake has collided with the world boundaries
      if snake.head.x < 0 || snake.head.x >= state.world_dimensions.w ||
         snake.head.y < 0 || snake.head.y >= state.world_dimensions.h
        state.game_over = true
        state.game_over_at = state.clock
      end

      # check if the snake has collided with itself
      if snake.body.include?(snake.head)
        state.game_over = true
        state.game_over_at = state.clock
      end

      # if the snake body is longer than the snake size
      # remove the first segment of the snake body
      if snake.body.length > snake.sz
        snake.body.pop_front
      end

      # check if the snake has eaten the apple
      if snake.head.x == state.apple.x && snake.head.y == state.apple.y
        # increase the snake size
        snake.sz += 1
        # increase the score
        state.score += 1
        # check if the score is higher than the high score
        # and update the high score if necessary
        state.high_score = state.score if state.score > state.high_score
        # generate a new apple
        state.apple = new_apple
      end
    end

    def calc_restart
      # check keyboard input to see if game should be restarted
      # wait 60 frames after game over before accepting input
      return if !state.game_over
      return if state.game_over_at.elapsed_time(state.clock) < 60

      # if any key is pressed, start a new game
      if inputs.keyboard.key_down.truthy_keys.any?
        new_game
      end
    end

    def render
      # render the main game
      render_game
      # render the game over screen if needed
      render_game_over
    end

    def render_game
      # render the snake's head
      nokia.sprites << {
        x: snake.head.x * 3,
        y: snake.head.y * 3,
        w: 3,
        h: 3,
        path: "sprites/head.png",
        angle: snake.angle
      }

      # render the snake's body
      nokia.sprites << snake.body.map do |segment|
        {
          x: segment.x * 3,
          y: segment.y * 3,
          w: 3,
          h: 3,
          path: "sprites/body.png"
        }
      end

      # render the apple
      nokia.sprites << {
        x: state.apple.x * 3,
        y: state.apple.y * 3,
        w: 3,
        h: 3,
        path: "sprites/apple.png"
      }
    end

    def render_game_over
      # return if the game is not over
      return if !state.game_over

      # wait 60 frames after game over before rendering the game over screen/overlay
      return if state.game_over_at.elapsed_time(state.clock) < 60

      # render background
      nokia.sprites << {
        x: 84 / 2, y: 48 / 2, w: 84, h: 18, path: :solid, r: 67, g: 82, b: 61,
        anchor_x: 0.5, anchor_y: 0.5
      }

      # render game over text
      nokia.labels << sm_label.merge(x: 84 / 2,
                                     y: 48 / 2,
                                     r: 199, g: 240, b: 216,
                                     text: "GAME OVER",
                                     anchor_x: 0.5,
                                     anchor_y: -0.5)

      # render score text
      nokia.labels << sm_label.merge(x: 84 / 2,
                                     y: 48 / 2,
                                     r: 199, g: 240, b: 216,
                                     text: "SCORE: #{state.score}",
                                     anchor_x: 0.5,
                                     anchor_y: 0.5)

      # render high score text
      nokia.labels << sm_label.merge(x: 84 / 2,
                                     y: 48 / 2,
                                     r: 199, g: 240, b: 216,
                                     text: "HI SCORE: #{state.high_score}",
                                     anchor_x: 0.5,
                                     anchor_y: 1.75)
    end

    def snake
      # helper function to access the snake state so we aren't writing state.snake everywhere
      state.snake
    end

    def new_game
      # initial state for a new game
      state.clock = 0
      state.world_dimensions = { w: 28, h: 16 }
      state.snake = {
        sz: 3,
        head: { x: 14, y: 8 },
        body: [],
        direction: { x: 1, y: 0 },
        next_direction: { x: 1, y: 0 },
        angle: 0,
        next_angle: 0
      }
      state.high_score ||= 0
      state.score = 0
      state.apple = new_apple
      state.game_over = false
      state.game_over_at = nil
    end

    def new_apple
      # pick a random location for the apple
      potential_apple = { x: Numeric.rand(0..state.world_dimensions.w - 1),
                          y: Numeric.rand(0..state.world_dimensions.h - 1) }

      if snake.body.include?(potential_apple) || state.snake.head == potential_apple
        # if the apple is on the snake or in the snake's head, pick a new location
        new_apple
      else
        # otherwise, return the apple
        potential_apple
      end
    end

    def sm_label
      { x: 0, y: 0, size_px: 5, font: "fonts/lowrez.ttf", anchor_x: 0, anchor_y: 0 }
    end

    def md_label
      { x: 0, y: 0, size_px: 10, font: "fonts/lowrez.ttf", anchor_x: 0, anchor_y: 0 }
    end

    def lg_label
      { x: 0, y: 0, size_px: 15, font: "fonts/lowrez.ttf", anchor_x: 0, anchor_y: 0 }
    end

    def xl_label
      { x: 0, y: 0, size_px: 20, font: "fonts/lowrez.ttf", anchor_x: 0, anchor_y: 0 }
    end

    def nokia
      outputs[:nokia]
    end

    def outputs
      @args.outputs
    end

    def inputs
      @args.inputs
    end

    def state
      @args.state
    end
  end

  # DR.reset will reset your entire game
  # it's useful for debugging and starting fresh
  # comment this line out if you want to retain your
  # current game state in between hot reloads
  DR.reset

```

### Nokia 33snake - nokia_emulation.rb
```ruby
  # ./samples/99_genre_lowrez/nokia_3310_snake/app/nokia_emulation.rb
  # Logical canvas width and height
  WIDTH = 1280
  HEIGHT = 720

  # Nokia screen dimensions
  NOKIA_WIDTH = 84
  NOKIA_HEIGHT = 48

  # Determine best fit zoom level
  ZOOM_WIDTH = (WIDTH / NOKIA_WIDTH).floor
  ZOOM_HEIGHT = (HEIGHT / NOKIA_HEIGHT).floor
  ZOOM = [ZOOM_WIDTH, ZOOM_HEIGHT].min

  # Compute the offset to center the Nokia screen
  OFFSET_X = (WIDTH - NOKIA_WIDTH * ZOOM) / 2
  OFFSET_Y = (HEIGHT - NOKIA_HEIGHT * ZOOM) / 2

  # Compute the scaled dimensions of the Nokia screen
  ZOOMED_WIDTH = NOKIA_WIDTH * ZOOM
  ZOOMED_HEIGHT = NOKIA_HEIGHT * ZOOM

  def boot args
    args.state = {}
  end

  def tick args
    # set the background color to black
    args.outputs.background_color = [0, 0, 0]

    # define a render target that represents the Nokia screen
    args.outputs[:nokia].w = 84
    args.outputs[:nokia].h = 48
    args.outputs[:nokia].background_color = [199, 240, 216]

    # new up the game if it hasn't been created yet
    $game ||= Game.new

    # pass args environment to the game
    $game.args = args

    # compute the mouse position in the Nokia screen
    $game.nokia_mouse_position = {
      x: (args.inputs.mouse.x - OFFSET_X).idiv(ZOOM),
      y: (args.inputs.mouse.y - OFFSET_Y).idiv(ZOOM),
      w: 1,
      h: 1,
    }

    # update the game
    $game.tick

    # render the game scaled to fit the screen
    args.outputs.sprites << {
      x: WIDTH / 2,
      y: HEIGHT / 2,
      w: ZOOMED_WIDTH,
      h: ZOOMED_HEIGHT,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: :nokia,
    }
  end

  # if DR.reset is called
  # clear out the game so that it can be re-initialized
  def reset args
    $game = nil
  end

```

### Resolution 64x64 - lowrez.rb
```ruby
  # ./samples/99_genre_lowrez/resolution_64x64/app/lowrez.rb
  # Emulation of a 64x64 canvas. Don't change this file unless you know what you're doing :-)
  # Head over to main.rb and study the code there.

  LOWREZ_SIZE            = 64
  LOWREZ_ZOOM            = 10
  LOWREZ_ZOOMED_SIZE     = LOWREZ_SIZE * LOWREZ_ZOOM
  LOWREZ_X_OFFSET        = (1280 - LOWREZ_ZOOMED_SIZE).half
  LOWREZ_Y_OFFSET        = ( 720 - LOWREZ_ZOOMED_SIZE).half

  LOWREZ_FONT_XL         = -1
  LOWREZ_FONT_XL_HEIGHT  = 20

  LOWREZ_FONT_LG         = -3.5
  LOWREZ_FONT_LG_HEIGHT  = 15

  LOWREZ_FONT_MD         = -6
  LOWREZ_FONT_MD_HEIGHT  = 10

  LOWREZ_FONT_SM         = -8.5
  LOWREZ_FONT_SM_HEIGHT  = 5

  LOWREZ_FONT_PATH       = 'fonts/lowrez.ttf'


  class LowrezOutputs
    attr_accessor :width, :height

    def initialize args
      @args = args
      @background_color ||= [0, 0, 0]
      @args.outputs.background_color = @background_color
    end

    def background_color
      @background_color ||= [0, 0, 0]
    end

    def background_color= opts
      @background_color = opts
      @args.outputs.background_color = @background_color

      outputs_lowrez.solids << [0, 0, LOWREZ_SIZE, LOWREZ_SIZE, @background_color]
    end

    def outputs_lowrez
      return @args.outputs if Kernel.tick_count <= 0
      return @args.outputs[:lowrez]
    end

    def solids
      outputs_lowrez.solids
    end

    def borders
      outputs_lowrez.borders
    end

    def sprites
      outputs_lowrez.sprites
    end

    def labels
      outputs_lowrez.labels
    end

    def default_label
      {
        x: 0,
        y: 63,
        text: "",
        size_enum: LOWREZ_FONT_SM,
        alignment_enum: 0,
        r: 0,
        g: 0,
        b: 0,
        a: 255,
        font: LOWREZ_FONT_PATH
      }
    end

    def lines
      outputs_lowrez.lines
    end

    def primitives
      outputs_lowrez.primitives
    end

    def click
      return nil unless @args.inputs.mouse.click
      mouse
    end

    def mouse_click
      click
    end

    def mouse_down
      @args.inputs.mouse.down
    end

    def mouse_up
      @args.inputs.mouse.up
    end

    def mouse
      [
        ((@args.inputs.mouse.x - LOWREZ_X_OFFSET).idiv(LOWREZ_ZOOM)),
        ((@args.inputs.mouse.y - LOWREZ_Y_OFFSET).idiv(LOWREZ_ZOOM))
      ]
    end

    def mouse_position
      mouse
    end

    def keyboard
      @args.inputs.keyboard
    end
  end

  class DR::Args
    def init_lowrez
      return if @lowrez
      @lowrez = LowrezOutputs.new self
    end

    def lowrez
      @lowrez
    end
  end

  module DR
    class Runtime
      alias_method :__original_tick_core__, :tick_core unless Runtime.instance_methods.include?(:__original_tick_core__)

      def tick_core
        @args.init_lowrez
        __original_tick_core__

        return if Kernel.tick_count <= 0

        @args.render_target(:lowrez)
             .labels
             .each do |l|
          l.y  += 1
        end

        @args.render_target(:lowrez)
             .lines
             .each do |l|
          l.y  += 1
          l.y2 += 1
          l.y2 += 1 if l.y != l.y2
          l.x2 += 1 if l.x != l.x2
        end

        @args.outputs
             .sprites << { x: 320,
                           y: 40,
                           w: 640,
                           h: 640,
                           source_x: 0,
                           source_y: 0,
                           source_w: 64,
                           source_h: 64,
                           path: :lowrez }
      end
    end
  end

```

### Resolution 64x64 - main.rb
```ruby
  # ./samples/99_genre_lowrez/resolution_64x64/app/main.rb
  require 'app/lowrez.rb'

  def tick args
    # How to set the background color
    args.lowrez.background_color = [255, 255, 255]

    # ==== HELLO WORLD ======================================================
    # Steps to get started:
    # 1. ~def tick args~ is the entry point for your game.
    # 2. There are quite a few code samples below, remove the "##"
    #    before each line and save the file to see the changes.
    # 3. 0,  0 is in bottom left and 63, 63 is in top right corner.
    # 4. Be sure to come to the discord channel if you need
    #    more help: [[http://discord.dragonruby.org]].

    # Commenting and uncommenting code:
    # - Add a "#" infront of lines to comment out code
    # - Remove the "#" infront of lines to comment out code

    # Invoke the hello_world subroutine/method
    hello_world args # <---- add a "#" to the beginning of the line to stop running this subroutine/method.
    # =======================================================================


    # ==== HOW TO RENDER A LABEL ============================================
    # Uncomment the line below to invoke the how_to_render_a_label subroutine/method.
    # Note: The method is defined in this file with the signature ~def how_to_render_a_label args~
    #       Scroll down to the method to see the details.

    # Remove the "#" at the beginning of the line below
    # how_to_render_a_label args # <---- remove the "#" at the begging of this line to run the method
    # =======================================================================


    # ==== HOW TO RENDER A FILLED SQUARE (SOLID) ============================
    # Remove the "#" at the beginning of the line below
    # how_to_render_solids args
    # =======================================================================


    # ==== HOW TO RENDER AN UNFILLED SQUARE (BORDER) ========================
    # Remove the "#" at the beginning of the line below
    # how_to_render_borders args
    # =======================================================================


    # ==== HOW TO RENDER A LINE =============================================
    # Remove the "#" at the beginning of the line below
    # how_to_render_lines args
    # =======================================================================


    # == HOW TO RENDER A SPRITE =============================================
    # Remove the "#" at the beginning of the line below
    # how_to_render_sprites args
    # =======================================================================


    # ==== HOW TO MOVE A SPRITE BASED OFF OF USER INPUT =====================
    # Remove the "#" at the beginning of the line below
    # how_to_move_a_sprite args
    # =======================================================================


    # ==== HOW TO ANIMATE A SPRITE (SEPERATE PNGS) ==========================
    # Remove the "#" at the beginning of the line below
    # how_to_animate_a_sprite args
    # =======================================================================


    # ==== HOW TO ANIMATE A SPRITE (SPRITE SHEET) ===========================
    # Remove the "#" at the beginning of the line below
    # how_to_animate_a_sprite_sheet args
    # =======================================================================


    # ==== HOW TO DETERMINE COLLISION =============================================
    # Remove the "#" at the beginning of the line below
    # how_to_determine_collision args
    # =======================================================================


    # ==== HOW TO CREATE BUTTONS ==================================================
    # Remove the "#" at the beginning of the line below
    # how_to_create_buttons args
    # =======================================================================


    # ==== The line below renders a debug grid, mouse information, and current tick
    render_debug args
  end

  def hello_world args
    args.lowrez.solids  << { x: 0, y: 64, w: 10, h: 10, r: 255 }

    args.lowrez.labels  << {
      x: 32,
      y: 63,
      text: "lowrezjam 2020",
      size_enum: LOWREZ_FONT_SM,
      alignment_enum: 1,
      r: 0,
      g: 0,
      b: 0,
      a: 255,
      font: LOWREZ_FONT_PATH
    }

    args.lowrez.sprites << {
      x: 32 - 10,
      y: 32 - 10,
      w: 20,
      h: 20,
      path: 'sprites/lowrez-ship-blue.png',
      a: Kernel.tick_count % 255,
      angle: Kernel.tick_count % 360
    }
  end


  # =======================================================================
  # ==== HOW TO RENDER A LABEL ============================================
  # =======================================================================
  def how_to_render_a_label args
    # NOTE: Text is aligned from the TOP LEFT corner

    # Render an EXTRA LARGE/XL label (remove the "#" in front of each line below)
    args.lowrez.labels << { x: 0, y: 57, text: "Hello World",
                           size_enum: LOWREZ_FONT_XL,
                           r: 0, g: 0, b: 0, a: 255,
                           font: LOWREZ_FONT_PATH }

    # Render a LARGE/LG label (remove the "#" in front of each line below)
    args.lowrez.labels << { x: 0, y: 36, text: "Hello World",
                            size_enum: LOWREZ_FONT_LG,
                            r: 0, g: 0, b: 0, a: 255,
                            font: LOWREZ_FONT_PATH }

    # Render a MEDIUM/MD label (remove the "#" in front of each line below)
    args.lowrez.labels << { x: 0, y: 20, text: "Hello World",
                            size_enum: LOWREZ_FONT_MD,
                            r: 0, g: 0, b: 0, a: 255,
                            font: LOWREZ_FONT_PATH }

    # Render a SMALL/SM label (remove the "#" in front of each line below)
    args.lowrez.labels << { x: 0, y: 9, text: "Hello World",
                            size_enum: LOWREZ_FONT_SM,
                            r: 0, g: 0, b: 0, a: 255,
                            font: LOWREZ_FONT_PATH }

    # You are provided args.lowrez.default_label which returns a Hash that you
    # can ~merge~ properties with
    # Example 1
    args.lowrez.labels << args.lowrez
                              .default_label
                              .merge(text: "Default")

    # Example 2
    args.lowrez.labels << args.lowrez
                              .default_label
                              .merge(x: 31,
                                     text: "Default",
                                     r: 128,
                                     g: 128,
                                     b: 128)
  end

  ## # =============================================================================
  ## # ==== HOW TO RENDER FILLED SQUARES (SOLIDS) ==================================
  ## # =============================================================================
  def how_to_render_solids args
    # Render a red square at 0, 0 with a width and height of 1
    args.lowrez.solids << { x: 0, y: 0, w: 1, h: 1, r: 255, g: 0, b: 0, a: 255 }

    # Render a red square at 1, 1 with a width and height of 2
    args.lowrez.solids << { x: 1, y: 1, w: 2, h: 2, r: 255, g: 0, b: 0, a: 255 }

    # Render a red square at 3, 3 with a width and height of 3
    args.lowrez.solids << { x: 3, y: 3, w: 3, h: 3, r: 255, g: 0, b: 0 }

    # Render a red square at 6, 6 with a width and height of 4
    args.lowrez.solids << { x: 6, y: 6, w: 4, h: 4, r: 255, g: 0, b: 0 }
  end

  ## # =============================================================================
  ## # ==== HOW TO RENDER UNFILLED SQUARES (BORDERS) ===============================
  ## # =============================================================================
  def how_to_render_borders args
    # Render a red square at 0, 0 with a width and height of 3
    args.lowrez.borders << { x: 0, y: 0, w: 3, h: 3, r: 255, g: 0, b: 0, a: 255 }

    # Render a red square at 3, 3 with a width and height of 3
    args.lowrez.borders << { x: 3, y: 3, w: 4, h: 4, r: 255, g: 0, b: 0, a: 255 }

    # Render a red square at 5, 5 with a width and height of 4
    args.lowrez.borders << { x: 7, y: 7, w: 5, h: 5, r: 255, g: 0, b: 0, a: 255 }
  end

  ## # =============================================================================
  ## # ==== HOW TO RENDER A LINE ===================================================
  ## # =============================================================================
  def how_to_render_lines args
    # Render a horizontal line at the bottom
    args.lowrez.lines << { x: 0, y: 0, x2: 63, y2:  0, r: 255 }

    # Render a vertical line at the left
    args.lowrez.lines << { x: 0, y: 0, x2:  0, y2: 63, r: 255 }

    # Render a diagonal line starting from the bottom left and going to the top right
    args.lowrez.lines << { x: 0, y: 0, x2: 63, y2: 63, r: 255 }
  end

  ## # =============================================================================
  ## # == HOW TO RENDER A SPRITE ===================================================
  ## # =============================================================================
  def how_to_render_sprites args
    # Loop 10 times and create 10 sprites in 10 positions
    # Render a sprite at the bottom left with a width and height of 5 and a path of 'sprites/lowrez-ship-blue.png'
    10.times do |i|
      args.lowrez.sprites << {
        x: i * 5,
        y: i * 5,
        w: 5,
        h: 5,
        path: 'sprites/lowrez-ship-blue.png'
      }
    end

    # Given an array of positions create sprites
    positions = [
      { x: 10, y: 42 },
      { x: 15, y: 45 },
      { x: 22, y: 33 },
    ]

    positions.each do |position|
      # use Ruby's ~Hash#merge~ function to create a sprite
      args.lowrez.sprites << position.merge(path: 'sprites/lowrez-ship-red.png',
                                            w: 5,
                                            h: 5)
    end
  end

  ## # =============================================================================
  ## # ==== HOW TO ANIMATE A SPRITE (SEPERATE PNGS) ==========================
  ## # =============================================================================
  def how_to_animate_a_sprite args
    # STEP 1: Define when you want the animation to start. The animation in this case will start in 3 seconds
    start_animation_on_tick = 180

    # STEP 2: Get the frame_index given the start tick.
    sprite_index = start_animation_on_tick.frame_index count: 7,     # how many sprites?
                                                       hold_for: 4,  # how long to hold each sprite?
                                                       repeat: true  # should it repeat?

    # STEP 3: frame_index will return nil if the frame hasn't arrived yet
    if sprite_index
      # if the sprite_index is populated, use it to determine the sprite path and render it
      sprite_path  = "sprites/explosion-#{sprite_index}.png"
      args.lowrez.sprites << { x: 0, y: 0, w: 64, h: 64, path: sprite_path }
    else
      # if the sprite_index is nil, render a countdown instead
      countdown_in_seconds = ((start_animation_on_tick - Kernel.tick_count) / 60).round(1)

      args.lowrez.labels  << args.lowrez
                                 .default_label
                                 .merge(x: 32,
                                        y: 32,
                                        text: "Count Down: #{countdown_in_seconds}",
                                        alignment_enum: 1)
    end

    # render the current tick and the resolved sprite index
    args.lowrez.labels  << args.lowrez
                                 .default_label
                                 .merge(x: 0,
                                        y: 11,
                                        text: "Tick: #{Kernel.tick_count}")
    args.lowrez.labels  << args.lowrez
                                 .default_label
                                 .merge(x: 0,
                                        y: 5,
                                        text: "sprite_index: #{sprite_index}")
  end

  ## # =============================================================================
  ## # ==== HOW TO ANIMATE A SPRITE (SPRITE SHEET) =================================
  ## # =============================================================================
  def how_to_animate_a_sprite_sheet args
    # STEP 1: Define when you want the animation to start. The animation in this case will start in 3 seconds
    start_animation_on_tick = 180

    # STEP 2: Get the frame_index given the start tick.
    sprite_index = start_animation_on_tick.frame_index count: 7,     # how many sprites?
                                                       hold_for: 4,  # how long to hold each sprite?
                                                       repeat: true  # should it repeat?

    # STEP 3: frame_index will return nil if the frame hasn't arrived yet
    if sprite_index
      # if the sprite_index is populated, use it to determine the source rectangle and render it
      args.lowrez.sprites << {
        x: 0,
        y: 0,
        w: 64,
        h: 64,
        path:  "sprites/explosion-sheet.png",
        source_x: 32 * sprite_index,
        source_y: 0,
        source_w: 32,
        source_h: 32
      }
    else
      # if the sprite_index is nil, render a countdown instead
      countdown_in_seconds = ((start_animation_on_tick - Kernel.tick_count) / 60).round(1)

      args.lowrez.labels  << args.lowrez
                                 .default_label
                                 .merge(x: 32,
                                        y: 32,
                                        text: "Count Down: #{countdown_in_seconds}",
                                        alignment_enum: 1)
    end

    # render the current tick and the resolved sprite index
    args.lowrez.labels  << args.lowrez
                                 .default_label
                                 .merge(x: 0,
                                        y: 11,
                                        text: "tick: #{Kernel.tick_count}")
    args.lowrez.labels  << args.lowrez
                                 .default_label
                                 .merge(x: 0,
                                        y: 5,
                                        text: "sprite_index: #{sprite_index}")
  end

  ## # =============================================================================
  ## # ==== HOW TO STORE STATE, ACCEPT INPUT, AND RENDER SPRITE BASED OFF OF STATE =
  ## # =============================================================================
  def how_to_move_a_sprite args
    args.lowrez.labels << args.lowrez
                              .default_label
                              .merge(x: 32,
                                     y: 62, text: "Use Arrow Keys",
                                     alignment_enum: 1)

    args.lowrez.labels << args.lowrez
                              .default_label
                              .merge(x: 32,
                                     y: 56, text: "Use WASD",
                                     alignment_enum: 1)

    args.lowrez.labels << args.lowrez
                              .default_label
                              .merge(x: 32,
                                     y: 50, text: "Or Click",
                                     alignment_enum: 1)

    # set the initial values for x and y using ||= ("or equal operator")
    args.state.ship.x ||= 0
    args.state.ship.y ||= 0

    # if a mouse click occurs, update the ship's x and y to be the location of the click
    if args.lowrez.mouse_click
      args.state.ship.x = args.lowrez.mouse_click.x
      args.state.ship.y = args.lowrez.mouse_click.y
    end

    # if a or left arrow is pressed/held, decrement the ships x position
    if args.lowrez.keyboard.left
      args.state.ship.x -= 1
    end

    # if d or right arrow is pressed/held, increment the ships x position
    if args.lowrez.keyboard.right
      args.state.ship.x += 1
    end

    # if s or down arrow is pressed/held, decrement the ships y position
    if args.lowrez.keyboard.down
      args.state.ship.y -= 1
    end

    # if w or up arrow is pressed/held, increment the ships y position
    if args.lowrez.keyboard.up
      args.state.ship.y += 1
    end

    # render the sprite to the screen using the position stored in args.state.ship
    args.lowrez.sprites << {
      x: args.state.ship.x,
      y: args.state.ship.y,
      w: 5,
      h: 5,
      path: 'sprites/lowrez-ship-blue.png',
      # parameters beyond this point are optional
      angle: 0, # Note: rotation angle is denoted in degrees NOT radians
      r: 255,
      g: 255,
      b: 255,
      a: 255
    }
  end

  # =======================================================================
  # ==== HOW TO DETERMINE COLLISION =======================================
  # =======================================================================
  def how_to_determine_collision args
    # Render the instructions
    args.lowrez.labels << args.lowrez
                              .default_label
                              .merge(x: 32,
                                     y: 62, text: "Click Anywhere",
                                     alignment_enum: 1)

    # if a mouse click occurs:
    # - set ship_one if it isn't set
    # - set ship_two if it isn't set
    # - otherwise reset ship one and ship two
    if args.lowrez.mouse_click
      # is ship_one set?
      if !args.state.ship_one
        args.state.ship_one = { x: args.lowrez.mouse_click.x - 10,
                                y: args.lowrez.mouse_click.y - 10,
                                w: 20,
                                h: 20 }
      # is ship_one set?
      elsif !args.state.ship_two
        args.state.ship_two = { x: args.lowrez.mouse_click.x - 10,
                                y: args.lowrez.mouse_click.y - 10,
                                w: 20,
                                h: 20 }
      # should we reset?
      else
        args.state.ship_one = nil
        args.state.ship_two = nil
      end
    end

    # render ship one if it's set
    if args.state.ship_one
      # use Ruby's .merge method which is available on ~Hash~ to set the sprite and alpha
      # render ship one
      args.lowrez.sprites << args.state.ship_one.merge(path: 'sprites/lowrez-ship-blue.png', a: 100)
    end

    if args.state.ship_two
      # use Ruby's .merge method which is available on ~Hash~ to set the sprite and alpha
      # render ship two
      args.lowrez.sprites << args.state.ship_two.merge(path: 'sprites/lowrez-ship-red.png', a: 100)
    end

    # if both ship one and ship two are set, then determine collision
    if args.state.ship_one && args.state.ship_two
      # collision is determined using the intersect_rect? method
      if args.state.ship_one.intersect_rect? args.state.ship_two
        # if collision occurred, render the words collision!
        args.lowrez.labels << args.lowrez
                              .default_label
                              .merge(x: 31,
                                     y: 5,
                                     text: "Collision!",
                                     alignment_enum: 1)
      else
        # if collision occurred, render the words no collision.
        args.lowrez.labels << args.lowrez
                              .default_label
                              .merge(x: 31,
                                     y: 5,
                                     text: "No Collision.",
                                     alignment_enum: 1)
      end
    else
      # if both ship one and ship two aren't set, then render --
        args.lowrez.labels << args.lowrez
                              .default_label
                              .merge(x: 31,
                                     y: 6,
                                     text: "--",
                                     alignment_enum: 1)
    end
  end

  ## # =============================================================================
  ## # ==== HOW TO CREATE BUTTONS ==================================================
  ## # =============================================================================
  def how_to_create_buttons args
    # Define a button style
    args.state.button_style = { w: 62, h: 10, r: 80, g: 80, b: 80 }
    args.state.label_style  = { r: 80, g: 80, b: 80 }

    # Render instructions
    args.state.button_message ||= "Press a Button!"
    args.lowrez.labels << args.lowrez
                              .default_label
                              .merge(args.state.label_style)
                              .merge(x: 32,
                                     y: 62,
                                     text: args.state.button_message,
                                     alignment_enum: 1)


    # Creates button one using a border and a label
    args.state.button_one_border = args.state.button_style.merge( x: 1, y: 32)
    args.lowrez.borders << args.state.button_one_border
    args.lowrez.labels  << args.lowrez
                               .default_label
                               .merge(args.state.label_style)
                               .merge(x: args.state.button_one_border.x + 2,
                                      y: args.state.button_one_border.y + LOWREZ_FONT_SM_HEIGHT + 2,
                                      text: "Button One")

    # Creates button two using a border and a label
    args.state.button_two_border = args.state.button_style.merge( x: 1, y: 20)

    args.lowrez.borders << args.state.button_two_border
    args.lowrez.labels << args.lowrez
                              .default_label
                              .merge(args.state.label_style)
                              .merge(x: args.state.button_two_border.x + 2,
                                     y: args.state.button_two_border.y + LOWREZ_FONT_SM_HEIGHT + 2,
                                     text: "Button Two")

    # Initialize the state variable that tracks which button was clicked to "" (empty stringI
    args.state.last_button_clicked ||= "--"

    # If a click occurs, check to see if either button one, or button two was clicked
    # using the inside_rect? method of the mouse
    # set args.state.last_button_clicked accordingly
    if args.lowrez.mouse_click
      if args.lowrez.mouse_click.inside_rect? args.state.button_one_border
        args.state.last_button_clicked = "One Clicked!"
      elsif args.lowrez.mouse_click.inside_rect? args.state.button_two_border
        args.state.last_button_clicked = "Two Clicked!"
      else
        args.state.last_button_clicked = "--"
      end
    end

    # Render the current value of args.state.last_button_clicked
    args.lowrez.labels << args.lowrez
                               .default_label
                               .merge(args.state.label_style)
                               .merge(x: 32,
                                      y: 5,
                                      text: args.state.last_button_clicked,
                                      alignment_enum: 1)
  end


  def render_debug args
    if !args.state.grid_rendered
      65.map_with_index do |i|
        args.outputs.static_debug << {
          x:  LOWREZ_X_OFFSET,
          y:  LOWREZ_Y_OFFSET + (i * 10),
          x2: LOWREZ_X_OFFSET + LOWREZ_ZOOMED_SIZE,
          y2: LOWREZ_Y_OFFSET + (i * 10),
          r: 128,
          g: 128,
          b: 128,
          a: 80
        }.line!

        args.outputs.static_debug << {
          x:  LOWREZ_X_OFFSET + (i * 10),
          y:  LOWREZ_Y_OFFSET,
          x2: LOWREZ_X_OFFSET + (i * 10),
          y2: LOWREZ_Y_OFFSET + LOWREZ_ZOOMED_SIZE,
          r: 128,
          g: 128,
          b: 128,
          a: 80
        }.line!
      end
    end

    args.state.grid_rendered = true

    args.state.last_click ||= 0
    args.state.last_up    ||= 0
    args.state.last_click   = Kernel.tick_count if args.lowrez.mouse_down # you can also use args.lowrez.click
    args.state.last_up      = Kernel.tick_count if args.lowrez.mouse_up
    args.state.label_style  = { size_enum: -1.5 }

    args.state.watch_list = [
      "Kernel.tick_count is:           #{Kernel.tick_count}",
      "args.lowrez.mouse_position is:  #{args.lowrez.mouse_position.x}, #{args.lowrez.mouse_position.y}",
      "args.lowrez.mouse_down tick:    #{args.state.last_click || "never"}",
      "args.lowrez.mouse_up tick:      #{args.state.last_up || "false"}",
    ]

    args.outputs.debug << args.state
                              .watch_list
                              .map_with_index do |text, i|
      {
        x: 5,
        y: 720 - (i * 20),
        text: text,
        size_enum: -1.5
      }.label!
    end

    args.outputs.debug << {
      x: 640,
      y:  25,
      text: "INFO: dev mode is currently enabled. Comment out the invocation of ~render_debug~ within the ~tick~ method to hide the debug layer.",
      size_enum: -0.5,
      alignment_enum: 1
    }.label!
  end

  DR.reset

```
