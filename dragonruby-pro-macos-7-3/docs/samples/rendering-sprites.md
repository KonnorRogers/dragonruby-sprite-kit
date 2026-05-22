### Animation Using Separate Pngs - main.rb
```ruby
  # ./samples/03_rendering_sprites/01_animation_using_separate_pngs/app/main.rb
  =begin
   Reminders:

   - String interpolation: Uses #{} syntax; everything between the #{ and the } is evaluated
     as Ruby code, and the placeholder is replaced with its corresponding value or result.

     In this sample app, we're using string interpolation to iterate through images in the
     sprites folder using their image path names.

   - args.outputs.sprites: An array. Values in this array generate sprites on the screen.
     The parameters are [X, Y, WIDTH, HEIGHT, IMAGE PATH]
     For more information about sprites, go to mygame/documentation/05-sprites.md.

   - args.outputs.labels: An array. Values in the array generate labels on the screen.
     The parameters are [X, Y, TEXT, SIZE, ALIGNMENT, RED, GREEN, BLUE, ALPHA, FONT STYLE]
     For more information about labels, go to mygame/documentation/02-labels.md.

   - args.inputs.keyboard.key_down.KEY: Determines if a key is in the down state, or pressed.
     Stores the frame that key was pressed on.
     For more information about the keyboard, go to mygame/documentation/06-keyboard.md.

  =end

  # This sample app demonstrates how sprite animations work.
  # There are two sprites that animate forever and one sprite
  # that *only* animates when you press the "f" key on the keyboard.

  # This is the entry point to your game. The `tick` method
  # executes at 60 frames per second. There are two methods
  # in this tick "entry point": `looping_animation`, and the
  # second method is `one_time_animation`.
  def tick args
    # uncomment the line below to see animation play out in slow motion
    # DR.slowmo! 6
    looping_animation args
    one_time_animation args
  end

  # This function shows how to animate a sprite that loops forever.
  def looping_animation args
    # Here we define a few local variables that will be sent
    # into the magic function that gives us the correct sprite image
    # over time. There are four things we need in order to figure
    # out which sprite to show.

    # 1. When to start the animation.
    start_looping_at = 0

    # 2. The number of pngs that represent the full animation.
    number_of_sprites = 6

    # 3. How long to show each png.
    number_of_frames_to_show_each_sprite = 4

    # 4. Whether the animation should loop once, or forever.
    does_sprite_loop = true

    # With the variables defined above, we can get a number
    # which represents the sprite to show by calling the `frame_index` function.
    # In this case the number will be between 0, and 5 (you can see the sprites
    # in the ./sprites directory).
    sprite_index = start_looping_at.frame_index number_of_sprites,
                                                number_of_frames_to_show_each_sprite,
                                                does_sprite_loop

    # Now that we have `sprite_index, we can present the correct file.
    args.outputs.sprites << { x: 100,
                              y: 100,
                              w: 100,
                              h: 100,
                              path: "sprites/dragon_fly_#{sprite_index}.png" }

    # Try changing the numbers below to see how the animation changes:
    args.outputs.sprites << { x: 100,
                              y: 200,
                              w: 100,
                              h: 100,
                              path: "sprites/dragon_fly_#{0.frame_index 6, 4, true}.png" }
  end

  # This function shows how to animate a sprite that executes
  # only once when the "f" key is pressed.
  def one_time_animation args
    # This is just a label the shows instructions within the game.
    args.outputs.labels <<  { x: 220, y: 350, text: "(press f to animate)" }

    # If "f" is pressed on the keyboard...
    if args.inputs.keyboard.key_down.f
      # Print the frame that "f" was pressed on.
      puts "Hello from main.rb! The \"f\" key was in the down state on frame: #{Kernel.tick_count}"

      # And MOST IMPORTANTLY set the point it time to start the animation,
      # equal to "now" which is represented as Kernel.tick_count.

      # Also IMPORTANT, you'll notice that the value of when to start looping
      # is stored in `args.state`. This construct's values are retained across
      # executions of the `tick` method.
      args.state.start_looping_at = Kernel.tick_count
    end

    # These are the same local variables that were defined
    # for the `looping_animation` function.
    number_of_sprites = 6
    number_of_frames_to_show_each_sprite = 4

    # Except this sprite does not loop again. If the animation time has passed,
    # then the frame_index function returns nil.
    does_sprite_loop = false

    if args.state.start_looping_at
      sprite_index = args.state
                         .start_looping_at
                         .frame_index number_of_sprites,
                                      number_of_frames_to_show_each_sprite,
                                      does_sprite_loop
    end

    # This line sets the frame index to zero, if
    # the animation duration has passed (frame_index returned nil).

    # Remeber: we are not looping forever here.
    sprite_index ||= 0

    # Present the sprite.
    args.outputs.sprites << { x: 100,
                              y: 300,
                              w: 100,
                              h: 100,
                              path: "sprites/dragon_fly_#{sprite_index}.png" }

    args.outputs.labels << { x: 640,
                             y: 700,
                             text: "Sample app shows how to use Numeric#frame_index to animate a sprite over time.",
                             anchor_x: 0.5,
                             anchor_y: 0.5 }
  end

```

### Animation Using Sprite Sheet - main.rb
```ruby
  # ./samples/03_rendering_sprites/02_animation_using_sprite_sheet/app/main.rb
  def tick args
    args.state.player ||= { x: 100,
                            y: 100,
                            w: 64,
                            h: 64,
                            direction: 1,
                            is_moving: false }

    # get the keyboard input and set player properties
    if args.inputs.keyboard.right
      args.state.player.x += 3
      args.state.player.direction = 1
      args.state.player.started_running_at ||= Kernel.tick_count
    elsif args.inputs.keyboard.left
      args.state.player.x -= 3
      args.state.player.direction = -1
      args.state.player.started_running_at ||= Kernel.tick_count
    end

    if args.inputs.keyboard.up
      args.state.player.y += 1
      args.state.player.started_running_at ||= Kernel.tick_count
    elsif args.inputs.keyboard.down
      args.state.player.y -= 1
      args.state.player.started_running_at ||= Kernel.tick_count
    end

    # if no arrow keys are being pressed, set the player as not moving
    if !args.inputs.keyboard.directional_vector
      args.state.player.started_running_at = nil
    end

    # wrap player around the stage
    if args.state.player.x > 1280
      args.state.player.x = -64
      args.state.player.started_running_at ||= Kernel.tick_count
    elsif args.state.player.x < -64
      args.state.player.x = 1280
      args.state.player.started_running_at ||= Kernel.tick_count
    end

    if args.state.player.y > 720
      args.state.player.y = -64
      args.state.player.started_running_at ||= Kernel.tick_count
    elsif args.state.player.y < -64
      args.state.player.y = 720
      args.state.player.started_running_at ||= Kernel.tick_count
    end

    # render player as standing or running
    if args.state.player.started_running_at
      args.outputs.sprites << running_sprite(args)
    else
      args.outputs.sprites << standing_sprite(args)
    end
    args.outputs.labels << [30, 700, "Use arrow keys to move around."]
  end

  def standing_sprite args
    {
      x: args.state.player.x,
      y: args.state.player.y,
      w: args.state.player.w,
      h: args.state.player.h,
      path: "sprites/horizontal-stand.png",
      flip_horizontally: args.state.player.direction > 0
    }
  end

  def running_sprite args
    if !args.state.player.started_running_at
      tile_index = 0
    else
      how_many_frames_in_sprite_sheet = 6
      how_many_ticks_to_hold_each_frame = 3
      should_the_index_repeat = true
      tile_index = args.state
                       .player
                       .started_running_at
                       .frame_index(how_many_frames_in_sprite_sheet,
                                    how_many_ticks_to_hold_each_frame,
                                    should_the_index_repeat)
    end

    {
      x: args.state.player.x,
      y: args.state.player.y,
      w: args.state.player.w,
      h: args.state.player.h,
      path: 'sprites/horizontal-run.png',
      tile_x: 0 + (tile_index * args.state.player.w),
      tile_y: 0,
      tile_w: args.state.player.w,
      tile_h: args.state.player.h,
      flip_horizontally: args.state.player.direction > 0
    }
  end

```

### Animation States 1 - main.rb
```ruby
  # ./samples/03_rendering_sprites/03_animation_states_1/app/main.rb
  # this class encapsulates the Game and shows
  # how to manage animations states. The components
  # that control animation states are action, action_at, and Numeric.frame
  class Game
    # expose player and enemies as public properties
    # from the Console you can see their values via $game.player and $game.enemies
    attr :player, :enemies

    # DragonRuby class macro that allows you to access inputs, outputs, state, etc
    # without passing args everywhere
    attr_dr

    def initialize
      # when the game is constructed, create the player at the center of the screen
      @player = {
        speed: 3,
        x: 640,
        y: 360,
        w: 64,
        h: 64,
        x_dir: 1, # the direction the player is facing
        action: :idle, # set the player's current action to :idle
        action_at: 0,  # set the player's action timestamp to 0
        action_lookup: { # frame data for each action
          # when player is standing still
          idle: {
            path: "sprites/horizontal-stand.png",
            hold_for: 3,
            frame_count: 1,
            repeat: true
          },
          # when player is moving
          run: {
            path: "sprites/horizontal-run.png",
            hold_for: 3,
            frame_count: 6,
            repeat: true
          },
          # when player is attacking
          slash: {
            path: "sprites/horizontal-slash.png",
            hold_for: 3,
            frame_count: 5,
            repeat: false
          }
        }
      }

      # collection of enemies
      @enemies = []
    end

    def player_current_action_lookup
      @player.action_lookup[@player.action]
    end

    def player_frame
      # get the frame data for the current action the player is in
      action_lookup = player_current_action_lookup

      # Numeric.frame returns the following hash
      # For example, this would be the frame data for performing an attack
      # {
      #   frame_index: 3,
      #   frame_count: 5,
      #   frames_left: 2,
      #   started: true,
      #   completed: false,
      #   duration: 15,
      #   elapsed_time: 10,
      #   frame_elapsed_time: 1
      # }
      Numeric.frame(start_at: @player.action_at,
                    frame_count: action_lookup.frame_count,
                    hold_for: action_lookup.hold_for,
                    repeat: action_lookup.repeat)
    end

    # function adds an enemy to the enemies collection
    def add_enemy
      @enemies << {
        x: 1200 * rand,
        y: 600 * rand,
        w: 64,
        h: 64,
        anchor_x: 0.5,
        anchor_y: 0.5,
      }
    end

    # return the sprite to display based on the players current action
    def player_prefab
      # first get the action frame data for the player's current action
      # the lookup contains the sprite to display
      lookup = player_current_action_lookup

      # then get the frame information
      frame = player_frame

      {
        x: @player.x,
        y: @player.y,
        w: 128,
        h: 128,
        path: lookup.path, # lookup path
        tile_x: 128 * frame.frame_index, # the pngs are tile sheets, so we offset the tile_x by the frame index
        tile_y: 0,
        tile_w: 128,
        tile_h: 128,
        anchor_x: 0.5,
        anchor_y: 0.5,
        flip_horizontally: @player.x_dir == 1
      }
    end

    # return the representation of an enemy (int this case it's just a solid box)
    def enemy_prefab enemy
      { **enemy, path: :solid, r: 0, g: 0, b: 0, a: 128 }
    end

    # this represents the rectang for the player's sword
    def player_slash_rect
      {
        x: player.x + player.x_dir * 40,
        y: player.y,
        w: 40,
        h: 20,
        anchor_x: 0.5,
        anchor_y: 0.5,
        path: :solid,
        r: 0, g: 0, b: 0
      }
    end

    # slash is requested if controller's A is pressed,
    # J is pressed on the keyboard,
    # or enter is pressed on the keyboard
    def player_slash_requested?
      inputs.controller_one.key_down.a ||
      inputs.keyboard.key_down.j       ||
      inputs.keyboard.key_down.enter
    end

    # the slash of the player can damage an enemy
    # when the animation first transitions to frame index 2
    def player_slash_can_damage?
      @player.action == :slash &&
      player_frame.frame_index == 2 &&
      player_frame.frame_elapsed_time == 0
    end

    def player_action! action
      # set the player action and the timestamp for the action
      # if the player isn't already in that action
      return if @player.action == action
      @player.action = action
      @player.action_at = Kernel.tick_count
    end

    def tick
      # if no enemies exist in the enemies collection,
      # add an enemy at a random location
      add_enemy if @enemies.length == 0

      # if slash is requested, then put the player in the :slash action
      if player_slash_requested?
        player_action! :slash
      end

      # if :slash is completed, then move the player back to idle
      if @player.action == :slash
        if player_frame.completed
          player_action! :idle
        end
      else
        # get the directional vector for the player
        vec = inputs.directional_vector

        # if WASD/arrow keys/DPAD is being activated
        if vec
          # increment player's x by the vector x multiplied by speed
          @player.x += @player.speed * vec.x

          # increment player's y by the vector y multiplied by speed
          @player.y += @player.speed * vec.y

          # set the player's facing direction equal to vec.x's sign if vec.x is not zero
          if vec.x != 0
            @player.x_dir = vec.x.sign
          end

          # set the player action to run
          player_action! :run
        else
          # if no directional vector is being pressed then set the player to idle
          player_action! :idle
        end
      end

      # if the player can damage an enemy
      if player_slash_can_damage?
        # delete all enemies that intersect with the player's sword
        @enemies.reject! { |e| Geometry.intersect_rect? e, player_slash_rect }
      end

      outputs.watch "player action: #{@player.action}: #{@player.action_at}"
      outputs.watch "player frame data: #{pretty_format player_frame}"

      # render the player, they sword collision rect, and enemies
      outputs.primitives << player_slash_rect
      outputs.primitives << player_prefab
      outputs.primitives << @enemies.map { |e| enemy_prefab e }
    end
  end

  def boot args
    args.state = {}
  end

  def tick args
    # new up the game if it hasn't been initialized
    $game ||= Game.new
    # set args on the game
    $game.args = args
    # run tick
    $game.tick
  end

  # if reset is called, then set the game to nil so that it can be initialized again
  def reset args
    $game = nil
  end

  DR.reset

```

### Animation States 2 - main.rb
```ruby
  # ./samples/03_rendering_sprites/03_animation_states_2/app/main.rb
  def tick args
    defaults args
    input args
    calc args
    render args
  end

  def defaults args
    # uncomment the line below to slow the game down by a factor of 4 -> 15 fps (for debugging)
    # DR.slowmo! 4

    args.state.player ||= {
      x: 144,                # render x of the player
      y: 32,                 # render y of the player
      w: 144 * 2,            # render width of the player
      h: 72 * 2,             # render height of the player
      dx: 0,                 # velocity x of the player
      action: :standing,     # current action/status of the player
      action_at: 0,          # frame that the action occurred
      previous_direction: 1, # direction the player was facing last frame
      direction: 1,          # direction the player is facing this frame
      launch_speed: 4,       # speed the player moves when they start running
      run_acceleration: 1,   # how much the player accelerates when running
      run_top_speed: 8,      # the top speed the player can run
      friction: 0.9,         # how much the player slows down when have stopped attempting to run
      anchor_x: 0.5,         # render anchor x of the player
      anchor_y: 0            # render anchor y of the player
    }
  end

  def input args
    # if the directional has been pressed on the input device
    if args.inputs.left_right != 0
      # determine if the player is currently running or not,
      # if they aren't, set their dx to their launch speed
      # otherwise, add the run acceleration to their dx
      if args.state.player.action != :running
        args.state.player.dx = args.state.player.launch_speed * args.inputs.left_right.sign
      else
        args.state.player.dx += args.inputs.left_right * args.state.player.run_acceleration
      end

      # capture the direction the player is facing and the previous direction
      args.state.player.previous_direction = args.state.player.direction
      args.state.player.direction = args.inputs.left_right.sign
    end
  end

  def calc args
    # clamp the player's dx to the top speed
    args.state.player.dx = args.state.player.dx.clamp(-args.state.player.run_top_speed, args.state.player.run_top_speed)

    # move the player by their dx
    args.state.player.x += args.state.player.dx

    # capture the player's hitbox
    player_hitbox = hitbox args.state.player

    # check boundary collisions and stop the player if they are colliding with the ednges of the screen
    if (player_hitbox.x - player_hitbox.w / 2) < 0
      args.state.player.x = player_hitbox.w / 2
      args.state.player.dx = 0
      # if the player is not standing, set them to standing and capture the frame
      if args.state.player.action != :standing
        args.state.player.action = :standing
        args.state.player.action_at = Kernel.tick_count
      end
    elsif (player_hitbox.x + player_hitbox.w / 2) > 1280
      args.state.player.x = 1280 - player_hitbox.w / 2
      args.state.player.dx = 0

      # if the player is not standing, set them to standing and capture the frame
      if args.state.player.action != :standing
        args.state.player.action = :standing
        args.state.player.action_at = Kernel.tick_count
      end
    end

    # if the player's dx is not 0, they are running. update their action and capture the frame if needed
    if args.state.player.dx.abs > 0
      if args.state.player.action != :running || args.state.player.direction != args.state.player.previous_direction
        args.state.player.action = :running
        args.state.player.action_at = Kernel.tick_count
      end
    elsif args.inputs.left_right == 0
      # if the player's dx is 0 and they are not currently trying to run (left_right == 0), set them to standing and capture the frame
      if args.state.player.action != :standing
        args.state.player.action = :standing
        args.state.player.action_at = Kernel.tick_count
      end
    end

    # if the player is not trying to run (left_right == 0), slow them down by the friction amount
    if args.inputs.left_right == 0
      args.state.player.dx *= args.state.player.friction

      # if the player's dx is less than 1, set it to 0
      if args.state.player.dx.abs < 1
        args.state.player.dx = 0
      end
    end
  end

  def render args
    # determine if the player should be flipped horizontally
    flip_horizontally = args.state.player.direction == -1
    # determine the path to the sprite to render, the idle sprite is used if action == :standing
    path = "sprites/link-idle.png"

    # if the player is running, determine the frame to render
    if args.state.player.action == :running
      # the sprite animation's first 3 frames represent the launch of the run, so we skip them on the animation loop
      # by setting the repeat_index to 3 (the 4th frame)
      frame_index = args.state.player.action_at.frame_index(count: 9, hold_for: 8, repeat: true, repeat_index: 3)
      path = "sprites/link-run-#{frame_index}.png"

      args.outputs.labels << { x: args.state.player.x - 144, y: args.state.player.y + 230, text: "action:      #{args.state.player.action}" }
      args.outputs.labels << { x: args.state.player.x - 144, y: args.state.player.y + 200, text: "action_at:   #{args.state.player.action_at}" }
      args.outputs.labels << { x: args.state.player.x - 144, y: args.state.player.y + 170, text: "frame_index: #{frame_index}" }
    else
      args.outputs.labels << { x: args.state.player.x - 144, y: args.state.player.y + 230, text: "action:      #{args.state.player.action}" }
      args.outputs.labels << { x: args.state.player.x - 144, y: args.state.player.y + 200, text: "action_at:   #{args.state.player.action_at}" }
      args.outputs.labels << { x: args.state.player.x - 144, y: args.state.player.y + 170, text: "frame_index: n/a" }
    end


    # render the player's hitbox and sprite (the hitbox is used to determine boundary collision)
    args.outputs.borders << hitbox(args.state.player)
    args.outputs.borders << args.state.player

    # render the player's sprite
    args.outputs.sprites << args.state.player.merge(path: path, flip_horizontally: flip_horizontally)
  end

  def hitbox entity
    {
      x: entity.x,
      y: entity.y + 5,
      w: 64,
      h: 96,
      anchor_x: 0.5,
      anchor_y: 0
    }
  end


  DR.reset

```

### Animation States 3 - main.rb
```ruby
  # ./samples/03_rendering_sprites/03_animation_states_3/app/main.rb
  class Game
    attr_dr

    def request_action name, at: nil
      at ||= Kernel.tick_count
      state.player.requested_action = name
      state.player.requested_action_at = at
    end

    def defaults
      state.player.x                  ||= 64
      state.player.y                  ||= 0
      state.player.dx                 ||= 0
      state.player.dy                 ||= 0
      state.player.action             ||= :standing
      state.player.action_at          ||= 0
      state.player.next_action_queue  ||= {}
      state.player.facing             ||= 1
      state.player.jump_at            ||= 0
      state.player.jump_count         ||= 0
      state.player.max_speed          ||= 1.0
      state.sabre.x                   ||= state.player.x
      state.sabre.y                   ||= state.player.y
      state.actions_lookup            ||= new_actions_lookup
    end

    def render
      outputs.background_color = [32, 32, 32]
      outputs[:scene].w = 128
      outputs[:scene].h = 128
      outputs[:scene].borders << { x: 0, y: 0, w: 128, h: 128, r: 255, g: 255, b: 255 }
      render_player
      render_sabre
      args.outputs.sprites << { x: 320, y: 0, w: 640, h: 640, path: :scene }
      args.outputs.labels << { x: 10, y: 100, text: "Controls:", r: 255, g: 255, b: 255, size_enum: -1 }
      args.outputs.labels << { x: 10, y: 80, text: "Move:   left/right", r: 255, g: 255, b: 255, size_enum: -1 }
      args.outputs.labels << { x: 10, y: 60, text: "Jump:   space | up | right click", r: 255, g: 255, b: 255, size_enum: -1 }
      args.outputs.labels << { x: 10, y: 40, text: "Attack: f     | j  | left click", r: 255, g: 255, b: 255, size_enum: -1 }
    end

    def render_sabre
      return if !state.sabre.is_active
      sabre_index = 0.frame_index count:    4,
                                  hold_for: 2,
                                  repeat:   true
      offset =  0
      offset = -8 if state.player.facing == -1
      outputs[:scene].sprites << { x: state.sabre.x + offset,
                          y: state.sabre.y, w: 16, h: 16, path: "sprites/sabre-throw/#{sabre_index}.png" }
    end

    def new_actions_lookup
      r = {
        slash_0: {
          frame_count: 6,
          interrupt_count: 4,
          path: "sprites/kenobi/slash-0/:index.png"
        },
        slash_1: {
          frame_count: 6,
          interrupt_count: 4,
          path: "sprites/kenobi/slash-1/:index.png"
        },
        throw_0: {
          frame_count: 8,
          throw_frame: 2,
          catch_frame: 6,
          path: "sprites/kenobi/slash-2/:index.png"
        },
        throw_1: {
          frame_count: 9,
          throw_frame: 2,
          catch_frame: 7,
          path: "sprites/kenobi/slash-3/:index.png"
        },
        throw_2: {
          frame_count: 9,
          throw_frame: 2,
          catch_frame: 7,
          path: "sprites/kenobi/slash-4/:index.png"
        },
        slash_5: {
          frame_count: 11,
          path: "sprites/kenobi/slash-5/:index.png"
        },
        slash_6: {
          frame_count: 8,
          interrupt_count: 6,
          path: "sprites/kenobi/slash-6/:index.png"
        }
      }

      r.each.with_index do |(k, v), i|
        v.name               ||= k
        v.index              ||= i

        v.hold_for           ||= 5
        v.duration           ||= v.frame_count * v.hold_for
        v.last_index         ||= v.frame_count - 1

        v.interrupt_count    ||= v.frame_count
        v.interrupt_duration ||= v.interrupt_count * v.hold_for

        v.repeat             ||= false
        v.next_action        ||= r[r.keys[i + 1]]
      end

      r
    end

    def render_player
      flip_horizontally = if state.player.facing == -1
                            true
                          else
                            false
                          end

      player_sprite = { x: state.player.x + 1 - 8,
                        y: state.player.y,
                        w: 16,
                        h: 16,
                        flip_horizontally: flip_horizontally }

      if state.player.action == :standing
        if state.player.y != 0
          if state.player.jump_count <= 1
            outputs[:scene].sprites << { **player_sprite, path: "sprites/kenobi/jumping.png" }
          else
            index = state.player.jump_at.frame_index count: 8, hold_for: 5, repeat: false
            index ||= 7
            outputs[:scene].sprites << { **player_sprite, path: "sprites/kenobi/second-jump/#{index}.png" }
          end
        elsif state.player.dx != 0
          index = state.player.action_at.frame_index count: 4, hold_for: 5, repeat: true
          outputs[:scene].sprites << { **player_sprite, path: "sprites/kenobi/run/#{index}.png" }
        else
          outputs[:scene].sprites << { **player_sprite, path: 'sprites/kenobi/standing.png'}
        end
      else
        v = state.actions_lookup[state.player.action]
        slash_frame_index = state.player.action_at.frame_index count:    v.frame_count,
                                                               hold_for: v.hold_for,
                                                               repeat:   v.repeat
        slash_frame_index ||= v.last_index
        slash_path          = v.path.sub ":index", slash_frame_index.to_s
        outputs[:scene].sprites << { **player_sprite, path: slash_path }
      end
    end

    def calc_input
      if state.player.next_action_queue.length > 2
        raise "Code in calc assums that key length of state.player.next_action_queue will never be greater than 2."
      end

      if inputs.controller_one.key_down.a ||
         inputs.mouse.button_left ||
         inputs.keyboard.key_down.j ||
         inputs.keyboard.key_down.f
        request_action :attack
      end

      should_update_facing = false
      if state.player.action == :standing
        should_update_facing = true
      else
        key_0 = state.player.next_action_queue.keys[0]
        key_1 = state.player.next_action_queue.keys[1]
        if Kernel.tick_count == key_0
          should_update_facing = true
        elsif Kernel.tick_count == key_1
          should_update_facing = true
        elsif key_0 && key_1 && Kernel.tick_count.between?(key_0, key_1)
          should_update_facing = true
        end
      end

      if should_update_facing && inputs.left_right.sign != state.player.facing.sign
        state.player.dx = 0

        if inputs.left
          state.player.facing = -1
        elsif inputs.right
          state.player.facing = 1
        end

        state.player.dx += 0.1 * inputs.left_right
      end

      if state.player.action == :standing
        state.player.dx += 0.1 * inputs.left_right
        if state.player.dx.abs > state.player.max_speed
          state.player.dx = state.player.max_speed * state.player.dx.sign
        end
      end

      was_jump_requested = inputs.keyboard.key_down.up ||
                           inputs.keyboard.key_down.w  ||
                           inputs.mouse.button_right  ||
                           inputs.controller_one.key_down.up ||
                           inputs.controller_one.key_down.b ||
                           inputs.keyboard.key_down.space

      can_jump = state.player.jump_at.elapsed_time > 20
      if state.player.jump_count <= 1
        can_jump = state.player.jump_at.elapsed_time > 10
      end

      if was_jump_requested && can_jump
        if state.player.action == :slash_6
          state.player.action = :standing
        end
        state.player.dy = 1
        state.player.jump_count += 1
        state.player.jump_at     = Kernel.tick_count
      end
    end

    def calc
      calc_input
      calc_requested_action
      calc_next_action
      calc_sabre
      calc_player_movement

      if state.player.y <= 0 && state.player.dy < 0
        state.player.y = 0
        state.player.dy = 0
        state.player.jump_at = 0
        state.player.jump_count = 0
      end
    end

    def calc_player_movement
      state.player.x += state.player.dx
      state.player.y += state.player.dy
      state.player.dy -= 0.05
      if state.player.y <= 0
        state.player.y = 0
        state.player.dy = 0
        state.player.jump_at = 0
        state.player.jump_count = 0
      end

      if state.player.dx.abs < 0.09
        state.player.dx = 0
      end

      state.player.x = 8  if state.player.x < 8
      state.player.x = 120 if state.player.x > 120
    end

    def calc_requested_action
      return if !state.player.requested_action
      return if state.player.requested_action_at > Kernel.tick_count

      player_action = state.player.action
      player_action_at = state.player.action_at

      # first attack
      if state.player.requested_action == :attack
        if player_action == :standing
          state.player.next_action_queue.clear
          state.player.next_action_queue[Kernel.tick_count] = :slash_0
          state.player.next_action_queue[Kernel.tick_count + state.actions_lookup.slash_0.duration] = :standing
        else
          current_action = state.actions_lookup[state.player.action]
          state.player.next_action_queue.clear
          queue_at = player_action_at + current_action.interrupt_duration
          queue_at = Kernel.tick_count if queue_at < Kernel.tick_count
          next_action = current_action.next_action
          next_action ||= { name: :standing,
                            duration: 4 }
          if next_action
          state.player.next_action_queue[queue_at] = next_action.name
          state.player.next_action_queue[player_action_at +
                                         current_action.interrupt_duration +
                                         next_action.duration] = :standing
          end
        end
      end

      state.player.requested_action = nil
      state.player.requested_action_at = nil
    end

    def calc_sabre
      can_throw_sabre = true
      sabre_throws = [:throw_0, :throw_1, :throw_2]
      if !sabre_throws.include? state.player.action
        state.sabre.facing = nil
        state.sabre.is_active = false
        return
      end

      current_action = state.actions_lookup[state.player.action]
      throw_at = state.player.action_at + (current_action.throw_frame) * 5
      catch_at = state.player.action_at + (current_action.catch_frame) * 5
      if !Kernel.tick_count.between? throw_at, catch_at
        state.sabre.facing = nil
        state.sabre.is_active = false
        return
      end

      state.sabre.facing ||= state.player.facing

      state.sabre.is_active = true

      spline_definition = [
        [  0, 0.25, 0.75, 1.0],
        [1.0, 0.75, 0.25,   0]
      ]

      throw_duration = catch_at - throw_at

      current_progress = Easing.spline throw_at,
                                       Kernel.tick_count,
                                       throw_duration,
                                       spline_definition

      farthest_sabre_x = 32
      state.sabre.y = state.player.y
      state.sabre.x = state.player.x + farthest_sabre_x * current_progress * state.sabre.facing
    end

    def calc_next_action
      return if !state.player.next_action_queue[Kernel.tick_count]

      state.player.previous_action = state.player.action
      state.player.previous_action_at = state.player.action_at
      state.player.previous_action_ended_at = Kernel.tick_count
      state.player.action = state.player.next_action_queue[Kernel.tick_count]
      state.player.action_at = Kernel.tick_count

      is_air_born = state.player.y != 0

      if state.player.action == :slash_0
        state.player.dy = 0 if state.player.dy > 0
        if is_air_born
          state.player.dy  = 0.5
        else
          state.player.dx += 0.25 * state.player.facing
        end
      elsif state.player.action == :slash_1
        state.player.dy = 0 if state.player.dy > 0
        if is_air_born
          state.player.dy  = 0.5
        else
          state.player.dx += 0.25 * state.player.facing
        end
      elsif state.player.action == :throw_0
        if is_air_born
          state.player.dy  = 1.0
        end

        state.player.dx += 0.5 * state.player.facing
      elsif state.player.action == :throw_1
        if is_air_born
          state.player.dy  = 1.0
        end

        state.player.dx += 0.5 * state.player.facing
      elsif state.player.action == :throw_2
        if is_air_born
          state.player.dy  = 1.0
        end

        state.player.dx += 0.5 * state.player.facing
      elsif state.player.action == :slash_5
        state.player.dy = 0 if state.player.dy < 0
        if is_air_born
          state.player.dy += 1.0
        else
          state.player.dy += 1.0
        end

        state.player.dx += 1.0 * state.player.facing
      elsif state.player.action == :slash_6
        state.player.dy = 0 if state.player.dy > 0
        if is_air_born
          state.player.dy  = -0.5
        end

        state.player.dx += 0.5 * state.player.facing
      end
    end

    def tick
      defaults
      calc
      render
    end
  end

  $game = Game.new

  def tick args
    $game.args = args
    $game.tick
  end

  DR.reset

```

### Color And Rotation - main.rb
```ruby
  # ./samples/03_rendering_sprites/04_color_and_rotation/app/main.rb
  =begin
   APIs listing that haven't been encountered in previous sample apps:

   - merge: Returns a hash containing the contents of two original hashes.
     Merge does not allow duplicate keys, so the value of a repeated key
     will be overwritten.

     For example, if we had two hashes
     h1 = { "a" => 1, "b" => 2}
     h2 = { "b" => 3, "c" => 3}
     and we called the command
     h1.merge(h2)
     the result would the following hash
     { "a" => 1, "b" => 3, "c" => 3}.

   Reminders:

   - Hashes: Collection of unique keys and their corresponding values. The value can be found
     using their keys.
     In this sample app, we're using a hash to create a sprite.

   - args.outputs.sprites: An array. The values generate a sprite.
     The parameters are [X, Y, WIDTH, HEIGHT, PATH, ANGLE, ALPHA, RED, GREEN, BLUE]
     Before continuing with this sample app, it is HIGHLY recommended that you look
     at mygame/documentation/05-sprites.md.

   - args.inputs.keyboard.key_held.KEY: Determines if a key is being pressed.
     For more information about the keyboard, go to mygame/documentation/06-keyboard.md.

   - args.inputs.controller_one: Takes input from the controller based on what key is pressed.
     For more information about the controller, go to mygame/documentation/08-controllers.md.

   - num1.lesser(num2): Finds the lower value of the given options.

  =end

  # This sample app shows a car moving across the screen. It loops back around if it exceeds the dimensions of the screen,
  # and also can be moved in different directions through keyboard input from the user.

  # Calls the methods necessary for the game to run successfully.
  def tick args
    default args
    render args.grid, args.outputs, args.state
    calc args.state
    process_inputs args
  end

  # Sets default values for the car sprite
  # Initialization ||= only happens in the first frame
  def default args
    args.state.sprite.width    = 19
    args.state.sprite.height   = 10
    args.state.sprite.scale    = 4
    args.state.max_speed       = 5
    args.state.x             ||= 100
    args.state.y             ||= 100
    args.state.speed         ||= 1
    args.state.angle         ||= 0
  end

  # Outputs sprite onto screen
  def render grid, outputs, state
    outputs.background_color = [70, 70, 70]
    outputs.sprites <<  { **destination_rect(state), # sets first four parameters of car sprite
                          path: 'sprites/86.png',    # image path of car
                          angle: state.angle,
                          a: opacity,                # alpha
                          **saturation,
                          **source_rect(state),      # sprite sub division/tile (source x, y, w, h)
                          flip_horizontally: false,
                          flip_vertically: false,    # don't flip sprites
                          **rotation_anchor }
  end

  # Calls the calc_pos and calc_wrap methods.
  def calc state
    calc_pos state
    calc_wrap state
  end

  # Changes sprite's position on screen
  # Vectors have magnitude and direction, so the incremented x and y values give the car direction
  def calc_pos state
    state.x     += state.angle.vector_x * state.speed # increments x by product of angle's x vector and speed
    state.y     += state.angle.vector_y * state.speed # increments y by product of angle's y vector and speed
    state.speed *= 1.1 # scales speed up
    state.speed  = state.speed.lesser(state.max_speed) # speed is either current speed or max speed, whichever has a lesser value (ensures that the car doesn't go too fast or exceed the max speed)
  end

  # The screen's dimensions are 1280x720. If the car goes out of scope,
  # it loops back around on the screen.
  def calc_wrap state

    # car returns to left side of screen if it disappears on right side of screen
    # sprite.width refers to tile's size, which is multipled by scale (4) to make it bigger
    state.x = -state.sprite.width * state.sprite.scale if state.x - 20 > 1280

    # car wraps around to right side of screen if it disappears on the left side
    state.x = 1280 if state.x + state.sprite.width * state.sprite.scale + 20 < 0

    # car wraps around to bottom of screen if it disappears at the top of the screen
    # if you subtract 520 pixels instead of 20 pixels, the car takes longer to reappear (try it!)
    state.y = 0    if state.y - 20 > 720 # if 20 pixels less than car's y position is greater than vertical scope

    # car wraps around to top of screen if it disappears at the bottom of the screen
    state.y = 720  if state.y + state.sprite.height * state.sprite.scale + 20 < 0
  end

  # Changes angle of sprite based on user input from keyboard or controller
  def process_inputs args

    # NOTE: increasing the angle doesn't mean that the car will continue to go
    # in a specific direction. The angle is increasing, which means that if the
    # left key was kept in the "down" state, the change in the angle would cause
    # the car to go in a counter-clockwise direction and form a circle (360 degrees)
    if args.inputs.keyboard.key_held.left # if left key is pressed
      args.state.angle += 2 # car's angle is incremented by 2

    # The same applies to decreasing the angle. If the right key was kept in the
    # "down" state, the decreasing angle would cause the car to go in a clockwise
    # direction and form a circle (360 degrees)
    elsif args.inputs.keyboard.key_held.right # if right key is pressed
      args.state.angle -= 2 # car's angle is decremented by 2

    # Input from a controller can also change the angle of the car
    elsif args.inputs.controller_one.left_analog_x_perc != 0
      args.state.angle += 2 * args.inputs.controller_one.left_analog_x_perc * -1
    end
  end

  # A sprite's center of rotation can be altered
  # Increasing either of these numbers would dramatically increase the
  # car's drift when it turns!
  def rotation_anchor
    { angle_anchor_x: 0.7, angle_anchor_y: 0.5 }
  end

  # Sets opacity value of sprite to 255 so that it is not transparent at all
  # Change it to 0 and you won't be able to see the car sprite on the screen
  def opacity
    255
  end

  # Sets the color of the sprite to white.
  def saturation
    { r: 255, g: 255, b: 255 }
  end

  # Sets definition of destination_rect (used to define the car sprite)
  def destination_rect state
    { x: state.x,
      y: state.y,
      w: state.sprite.width  * state.sprite.scale, # multiplies by 4 to set size
      h: state.sprite.height * state.sprite.scale }
  end

  # Portion of a sprite (a tile)
  # Sub division of sprite is denoted as a rectangle directly related to original size of .png
  # Tile is located at bottom left corner within a 19x10 pixel rectangle (based on sprite.width, sprite.height)
  def source_rect state
    { source_x: 0,
      source_y: 0,
      source_w: state.sprite.width,
      source_h: state.sprite.height }
  end

```

### Particles - main.rb
```ruby
  # ./samples/03_rendering_sprites/05_particles/app/main.rb
  def tick args
    # Set the background color to black
    args.outputs.background_color = [0, 0, 0]

    # Initialize the particle queue if it doesn't exist
    args.state.particle_queue ||= []

    # Add a new particle to the queue if the mouse is clicked
    if args.inputs.mouse.click || args.inputs.mouse.held
      args.state.particle_queue << {
        x: args.inputs.mouse.x,    # Set the x position to the mouse's x position
        y: args.inputs.mouse.y,    # Set the y position to the mouse's y position
        emission_speed: 5,         # Set the emission speed to 5
        emission_angle: rand(360), # Set the emission angle to a random angle
        r: 128,                    # Set the red color to 128
        g: rand(128) + 128,        # Set the green color to a random value between 128 and 255
        b: rand(128) + 128,        # Set the blue color to a random value between 128 and 255
      }
    end

    # Update the particles
    args.state.particle_queue.each do |particle|
      # initialize default values for particle
      particle.a ||= 255
      particle.path ||= :solid
      particle.w ||= 5
      particle.h ||= 5
      particle.anchor_x ||= 0.5
      particle.anchor_y ||= 0.5

      # initialize dx and dy of particle based on the emission speed and angle
      particle.dx ||= particle.emission_speed * particle.emission_angle.vector_x
      particle.dy ||= particle.emission_speed * particle.emission_angle.vector_y

      # update the particle's position based on the dx and dy
      particle.x += particle.dx
      particle.y += particle.dy

      # decrease the speed of the particle
      particle.dx *= 0.95
      particle.dy *= 0.95

      # if the particle's speed is less than 1.0, decrease the alpha value
      if particle.dx.abs < 1.0 && particle.dy.abs < 1.0
        particle.a -= 5
      end
    end

    # Remove particles with an alpha value less than or equal to 0
    args.state.particle_queue.reject! do |particle|
      particle.a <= 0
    end

    args.outputs.labels << {
      x: 640,
      y: 720,
      text: "Click and hold the mouse to create particles.",
      r: 255,
      g: 255,
      b: 255,
      anchor_x: 0.5,
      anchor_y: 1.0,
    }

    # Render the particles
    args.outputs.primitives << args.state.particle_queue
  end

  DR.reset

```
