### Easing Functions - main.rb
```ruby
  # ./samples/08_tweening_lerping_easing_functions/01_easing_functions/app/main.rb
  def tick args
    # STOP! Watch the following presentation first!!!!
    # Math for Game Programmers: Fast and Funky 1D Nonlinear Transformations
    # https://www.youtube.com/watch?v=mr5xkf6zSzk

    # You've watched the talk, yes? YES???

    # define starting and ending points of properties to animate
    args.state.target_x = 1180
    args.state.target_y = 620
    args.state.target_w = 100
    args.state.target_h = 100
    args.state.starting_x = 0
    args.state.starting_y = 0
    args.state.starting_w = 300
    args.state.starting_h = 300

    # define start time and duration of animation
    args.state.start_animate_at = 3.seconds # this is the same as writing 60 * 5 (or 300)
    args.state.duration = 2.seconds # this is the same as writing 60 * 2 (or 120)

    # define type of animations
    # Here are all the options you have for values you can put in the array:
    # :identity, :quad, :cube, :quart, :quint, :flip

    # Linear is defined as:
    # [:identity]
    #
    # Smooth start variations are:
    # [:quad]
    # [:cube]
    # [:quart]
    # [:quint]

    # Linear reversed, and smooth stop are the same as the animations defined above, but reversed:
    # [:flip, :identity, :flip]
    # [:flip, :quad, :flip]
    # [:flip, :cube, :flip]
    # [:flip, :quart, :flip]
    # [:flip, :quint, :flip]

    # You can also do custom definitions. See the bottom of the file details
    # on how to do that. I've defined a couple for you:
    # [:smoothest_start]
    # [:smoothest_stop]

    # CHANGE THIS LINE TO ONE OF THE LINES ABOVE TO SEE VARIATIONS
    args.state.animation_type = [:identity]
    # args.state.animation_type = [:quad]
    # args.state.animation_type = [:cube]
    # args.state.animation_type = [:quart]
    # args.state.animation_type = [:quint]
    # args.state.animation_type = [:flip, :identity, :flip]
    # args.state.animation_type = [:flip, :quad, :flip]
    # args.state.animation_type = [:flip, :cube, :flip]
    # args.state.animation_type = [:flip, :quart, :flip]
    # args.state.animation_type = [:flip, :quint, :flip]
    # args.state.animation_type = [:smoothest_start]
    # args.state.animation_type = [:smoothest_stop]

    # THIS IS WHERE THE MAGIC HAPPENS!
    # Numeric#ease
    progress = args.state.start_animate_at.ease(args.state.duration, args.state.animation_type)

    # Numeric#ease needs to called:
    # 1. On the number that represents the point in time you want to start, and takes two parameters:
    #   a. The first parameter is how long the animation should take.
    #   b. The second parameter represents the functions that need to be called.
    #
    # For example, if I wanted an animate to start 3 seconds in, and last for 10 seconds,
    # and I want to animation to start fast and end slow, I would do:
    # (60 * 3).ease(60 * 10, :flip, :quint, :flip)

    #        initial value           delta to the final value
    calc_x = args.state.starting_x + (args.state.target_x - args.state.starting_x) * progress
    calc_y = args.state.starting_y + (args.state.target_y - args.state.starting_y) * progress
    calc_w = args.state.starting_w + (args.state.target_w - args.state.starting_w) * progress
    calc_h = args.state.starting_h + (args.state.target_h - args.state.starting_h) * progress

    args.outputs.solids << [calc_x, calc_y, calc_w, calc_h, 0, 0, 0]

    # count down
    count_down = args.state.start_animate_at - Kernel.tick_count
    if count_down > 0
      args.outputs.labels << [640, 375, "Running: #{args.state.animation_type} in...", 3, 1]
      args.outputs.labels << [640, 345, "%.2f" % count_down.fdiv(60), 3, 1]
    elsif progress >= 1
      args.outputs.labels << [640, 360, "Click screen to reset.", 3, 1]
      if args.inputs.click
        DR.reset
      end
    end
  end

  # DR.reset

  # you can make own variations of animations using this
  module Easing
    # you have access to all the built in functions: identity, flip, quad, cube, quart, quint
    def self.smoothest_start x
      quad(quint(x))
    end

    def self.smoothest_stop x
      flip(quad(quint(flip(x))))
    end

    # this is the source for the existing easing functions
    def self.identity x
      x
    end

    def self.flip x
      1 - x
    end

    def self.quad x
      x * x
    end

    def self.cube x
      x * x * x
    end

    def self.quart x
      x * x * x * x * x
    end

    def self.quint x
      x * x * x * x * x * x
    end
  end

```

### Cubic Bezier - main.rb
```ruby
  # ./samples/08_tweening_lerping_easing_functions/02_cubic_bezier/app/main.rb
  def self.boot args
    args.state = {}
  end

  def self.tick args
    # init
    if Kernel.tick_count == 0
      control_points = [
        [
          [0.05, 0.58],
          [0.1,  0.95],
          [0.55, 0.86],
          [0.69, 0.75],
        ],
        [
          [0.69, 0.75],
          [0.96, 0.58],
          [1.00, 0.27],
          [0.76, 0.16],
        ],
        [
          [0.76, 0.16],
          [0.39, 0.08],
          [0.51, 0.4 ],
          [0.29, 0.36],
        ],
        [
          [0.29, 0.36],
          [0.11, 0.34],
          [0.04, 0.43],
          [0.05, 0.58],
        ],
      ]

      args.state.curves = control_points.map do |points|
        p0, p1, p2, p3 = points
        {
          color: { r: 128 + rand(128), g: 128 + rand(128), b: 128 + rand(128) },
          points: {
            p0: { x: p0[0], y: p0[1] },
            p1: { x: p1[0], y: p1[1] },
            p2: { x: p2[0], y: p2[1] },
            p3: { x: p3[0], y: p3[1] },
          }
        }
      end
    end

    # calc
    if args.inputs.mouse.held
      all_points = args.state.curves.flat_map do |curve|
        curve.points.values.map do |point|
          point
        end
      end

      args.state.currently_dragging_point ||= all_points.find do |point|
        mouse_inside_scene = args.inputs.mouse.rect(offset: { x: -280, y: 0 })
        Geometry.intersect_rect?(mouse_inside_scene,
                                 to_rect(point))
      end

      if args.state.currently_dragging_point
        args.state.currently_dragging_point.x = (args.inputs.mouse.x - 280).fdiv(720).clamp(0, 1)
        args.state.currently_dragging_point.y = (args.inputs.mouse.y).fdiv(720).clamp(0, 1)
      end
    else
      args.state.currently_dragging_point = nil
    end

    # render
    args.outputs[:scene].set w: 720,
                             h: 720,
                             background_color: [0, 0, 0, 0]

    args.outputs[:scene].primitives << args.state.curves.map do |curve|
      curve.points.values.map do |point|
        to_rect(point).merge(path: "sprites/circle/solid.png", **curve.color, a: 128)
      end
    end

    args.outputs[:scene].primitives << args.state.curves.map do |curve|
      bezier_primitives(curve.points.p0,
                        curve.points.p1,
                        curve.points.p2,
                        curve.points.p3,
                        step: 20,
                        color: { **curve.color, a: 255 })
    end

    args.outputs.background_color = [30, 30, 30]
    args.outputs.primitives << { x: 280, y: 0, w: 720, h: 720, path: :scene }
  end

  def self.to_rect point
    {
      x: point.x * 720,
      y: point.y * 720,
      w: 16,
      h: 16,
      anchor_x: 0.5,
      anchor_y: 0.5,
    }
  end

  def self.bezier_primitives(p0, p1, p2, p3, step: 20, color:)
    curve = points_for_bezier(
      p0,
      p1,
      p2,
      p3,
      step: step
    ).each_cons(2)
     .map do |p0, p1|
       {
         x: p0.x  * 720,
         y: p0.y  * 720,
         x2: p1.x * 720,
         y2: p1.y * 720,
         **color
       }
     end

    control_points = points_for_bezier(
      p0,
      p1,
      p2,
      p3,
      step: 0
    ).each_cons(2)
     .map do |p0, p1|
       {
         x: p0.x  * 720,
         y: p0.y  * 720,
         x2: p1.x * 720,
         y2: p1.y * 720,
         **color
       }
     end

    [
      curve,
      control_points
    ]
  end

  def self.points_for_bezier(p0, p1, p2, p3, step:)
    points = []
    if step == 0
      [p0, p1, p2, p3]
    else
      t_step = 1.fdiv(step + 1)
      t = 0
      t += t_step
      points = []
      while t < 1
        points << Geometry.cubic_bezier_vec2(p0, p1, p2, p3, t)
        t += t_step
      end

      [
        p0,
        *points,
        p3
      ]
    end
  end

  DR.reset

```

### Easing And Lerping Combined - main.rb
```ruby
  # ./samples/08_tweening_lerping_easing_functions/02_easing_and_lerping_combined/app/main.rb
  def boot args
    args.state = {}
  end

  def tick args
    # create 100 things and set the seed to a numeric value
    # the seed will be used to create a delay for each thing when the up and down keys are pressed
    args.state.things ||= 220.map do |i|
      x_ordinal = i % 20
      y_ordinal = i.idiv(20)
      {
        seed: i,
        # seed: Numeric.rand(30), # try this as a seed value (cool effect to try out)
        x: 6 + x_ordinal * 64,
        y: 6 + 8 + y_ordinal * 64,
        w: 52,
        h: 52,
        path: :solid,
        r: 80,
        g: 128,
        b: 200,
        a: 255,
        target_a: 255,
        target_a_at: nil
      }
    end

    # change these variable to control how closely the alpha transitions
    # are queued
    args.state.speed_multiplier ||= 1

    # change this variable to control how long the transition takes
    args.state.smooth_stop_duration ||= 15

    if args.inputs.keyboard.key_down.down
      # if down is pressed then queue fade out for each thing
      # schedule the fade out to start at a different time
      # for each thing based on the seed value
      args.state.things.each do |thing|
        thing.target_a = 64
        thing.target_a_at = Kernel.tick_count + thing.seed.idiv(args.state.speed_multiplier) * 2
      end
    elsif args.inputs.keyboard.key_down.up
      # otherwise if up is pressed then queue fade in for each thing
      args.state.things.each do |thing|
        thing.target_a = 255
        thing.target_a_at = Kernel.tick_count + thing.seed.idiv(args.state.speed_multiplier) * 2
      end
    end

    # enumerate each thing and check if it has a target_a_at value.
    # Then use Easing.smooth_stop to calculate the percentage of a.
    # clear out the target_a_at value and set a to the target_a value when the percentage is 1.
    args.state
        .things
        .find_all { |thing| thing.target_a_at }
        .each do |thing|
          perc = Easing.smooth_stop(start_at: thing.target_a_at,
                                    duration: args.state.smooth_stop_duration,
                                    power: 2,
                                    tick_count: Kernel.tick_count)
          thing.a = thing.a.lerp(thing.target_a, perc)
          thing.target_a_at = nil if perc == 1
        end

    args.outputs.background_color = [30, 30, 30]
    args.outputs.primitives << args.state.things
  end

  DR.reset

```

### Easing Using Spline - main.rb
```ruby
  # ./samples/08_tweening_lerping_easing_functions/03_easing_using_spline/app/main.rb
  def tick args
    args.state.duration = 10.seconds
    args.state.spline_definition = [
      [0.0, 0.33, 0.66, 1.0],
      [1.0, 1.0,  1.0,  1.0],
      [1.0, 0.66, 0.33, 0.0],
    ]

    args.state.simulation_tick = Kernel.tick_count % args.state.duration
    progress = Easing.spline 0, args.state.simulation_tick, args.state.duration, args.state.spline_definition
    args.outputs.borders << args.grid.rect
    args.outputs.solids << [20 + 1240 * progress,
                            20 +  680 * progress,
                            20, 20].anchor_rect(0.5, 0.5)
    args.outputs.labels << [10,
                            710,
                            "perc: #{"%.2f" % (args.state.simulation_tick / args.state.duration)} t: #{args.state.simulation_tick}"]
  end

```

### Easing Using Splines Bouncing Box - main.rb
```ruby
  # ./samples/08_tweening_lerping_easing_functions/03_easing_using_splines_bouncing_box/app/main.rb
  def tick args
    args.state.box ||= {
      x: 640,
      y: 360,
      w: 80,
      h: 80,
      path: :solid,
      r: 0,
      g: 80,
      b: 80,
      anchor_x: 0.5,
      anchor_y: 0.0,
      bounce_at: 0,
      bounce_duration: 30,
      bounce_spline: [
        [0.0, 0.0, 0.66, 1.0],
        [1.0, 0.33, 0.0,  0.0]
      ]
    }

    calc_bounce args.state.box
    args.outputs.sprites << bounce_prefab(args.state.box)
  end

  def calc_bounce box
    if box.bounce_at.elapsed_time == box.bounce_duration
      box.bounce_at = Kernel.tick_count
      puts "bounce complete"
    end
  end

  def bounce_prefab box
    perc = Easing.spline box.bounce_at,
                         Kernel.tick_count,
                         box.bounce_duration,
                         box.bounce_spline

    box.merge(w: box.h + 20 * perc,
              h: box.w - 40 * perc)
  end

  DR.reset

```

### Pulsing Button - main.rb
```ruby
  # ./samples/08_tweening_lerping_easing_functions/04_pulsing_button/app/main.rb
  # game concept from: https://youtu.be/Tz-AinJGDIM

  # This class encapsulates the logic of a button that pulses when clicked.
  # It is used in the StartScene and GameOverScene classes.
  class PulseButton
    # a block is passed into the constructor and is called when the button is clicked,
    # and after the pulse animation is complete
    def initialize rect, text, &on_click
      @rect = rect
      @text = text
      @on_click = on_click
      @pulse_animation_spline = [[0.0, 0.90, 1.0, 1.0], [1.0, 0.10, 0.0, 0.0]]
      @duration = 10
    end

    # the button is ticked every frame and check to see if the mouse
    # intersects the button's bounding box.
    # if it does, then pertinent information is stored in the @clicked_at variable
    # which is used to calculate the pulse animation
    def tick tick_count, mouse
      @tick_count = tick_count

      if @clicked_at && @clicked_at.elapsed_time > @duration
        @clicked_at = nil
        @on_click.call
      end

      return if !mouse.click
      return if !mouse.inside_rect? @rect
      @clicked_at = tick_count
    end

    # this function returns an array of primitives that can be rendered
    def primitives
      # calculate the percentage of the pulse animation that has completed
      # and use the percentage to compute the size and position of the button
      perc = if @clicked_at
               Easing.spline @clicked_at, @tick_count, @duration, @pulse_animation_spline
             else
               0
             end

      rect = { x: @rect.x - 50 * perc / 2,
               y: @rect.y - 50 * perc / 2,
               w: @rect.w + 50 * perc,
               h: @rect.h + 50 * perc }

      point = { x: @rect.x + @rect.w / 2, y: @rect.y + @rect.h / 2 }
      [
        { **rect, path: :solid },
        { **point, text: @text, size_px: 32, anchor_x: 0.5, anchor_y: 0.5 }
      ]
    end
  end

  class Game
    attr_dr

    def initialize args
      self.args = args
      @pulse_button ||= PulseButton.new({ x: 640 - 100, y: 360 - 50, w: 200, h: 100 }, 'Click Me!') do
        DR.notify! "Animation complete and block invoked!"
      end
    end

    def tick
      @pulse_button.tick Kernel.tick_count, inputs.mouse
      outputs.primitives << @pulse_button.primitives
    end
  end

  def tick args
    $game ||= Game.new args
    $game.args = args
    $game.tick
  end

```

### Scene Transitions - main.rb
```ruby
  # ./samples/08_tweening_lerping_easing_functions/05_scene_transitions/app/main.rb
  # This sample app shows a more advanced implementation of scenes:
  # 1. "Scene 1" has a label on it that says "I am scene ONE. Press enter to go to scene TWO."
  # 2. "Scene 2" has a label on it that says "I am scene TWO. Press enter to go to scene ONE."
  # 3. When the game starts, Scene 1 is presented.
  # 4. When the player presses enter, the scene transitions to Scene 2 (fades out Scene 1 over half a second, then fades in Scene 2 over half a second).
  # 5. When the player presses enter again, the scene transitions to Scene 1 (fades out Scene 2 over half a second, then fades in Scene 1 over half a second).
  # 6. During the fade transitions, spamming the enter key is ignored (scenes don't accept a transition/respond to the enter key until the current transition is completed).
  class SceneOne
    attr_dr

    def tick
      outputs[:scene].labels << { x: 640,
                                  y: 360,
                                  text: "I am scene ONE. Press enter to go to scene TWO.",
                                  alignment_enum: 1,
                                  vertical_alignment_enum: 1 }

      state.next_scene = :scene_two if inputs.keyboard.key_down.enter
    end
  end

  class SceneTwo
    attr_dr

    def tick
      outputs[:scene].labels << { x: 640,
                                  y: 360,
                                  text: "I am scene TWO. Press enter to go to scene ONE.",
                                  alignment_enum: 1,
                                  vertical_alignment_enum: 1 }

      state.next_scene = :scene_one if inputs.keyboard.key_down.enter
    end
  end

  class RootScene
    attr_dr

    def initialize
      @scene_one = SceneOne.new
      @scene_two = SceneTwo.new
    end

    def tick
      defaults
      render
      tick_scene
    end

    def defaults
      set_current_scene! :scene_one if Kernel.tick_count == 0
      state.scene_transition_duration ||= 30
    end

    def render
      a = if state.transition_scene_at
            255 * state.transition_scene_at.ease(state.scene_transition_duration, :flip)
          elsif state.current_scene_at
            255 * state.current_scene_at.ease(state.scene_transition_duration)
          else
            255
          end

      outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: :scene, a: a }
    end

    def tick_scene
      current_scene = state.current_scene

      @current_scene.args = args
      @current_scene.tick

      if current_scene != state.current_scene
        raise "state.current_scene changed mid tick from #{current_scene} to #{state.current_scene}. To change scenes, set state.next_scene."
      end

      if state.next_scene && state.next_scene != state.transition_scene && state.next_scene != state.current_scene
        state.transition_scene_at = Kernel.tick_count
        state.transition_scene = state.next_scene
      end

      if state.transition_scene_at && state.transition_scene_at.elapsed_time >= state.scene_transition_duration
        set_current_scene! state.transition_scene
      end

      state.next_scene = nil
    end

    def set_current_scene! id
      return if state.current_scene == id
      state.current_scene = id
      state.current_scene_at = Kernel.tick_count
      state.transition_scene = nil
      state.transition_scene_at = nil

      if state.current_scene == :scene_one
        @current_scene = @scene_one
      elsif state.current_scene == :scene_two
        @current_scene = @scene_two
      end
    end
  end

  def tick args
    $game ||= RootScene.new
    $game.args = args
    $game.tick
  end

```

### Animation Queues - main.rb
```ruby
  # ./samples/08_tweening_lerping_easing_functions/06_animation_queues/app/main.rb
  # here's how to create a "fire and forget" sprite animation queue
  def tick args
    args.outputs.labels << { x: 640,
                             y: 360,
                             text: "Click anywhere on the screen.",
                             alignment_enum: 1,
                             vertical_alignment_enum: 1 }

    # initialize the queue to an empty array
    args.state.fade_out_queue ||=[]

    # if the mouse is click, add a sprite to the fire and forget
    # queue to be processed
    if args.inputs.mouse.click
      args.state.fade_out_queue << {
        x: args.inputs.mouse.x - 20,
        y: args.inputs.mouse.y - 20,
        w: 40,
        h: 40,
        path: "sprites/square/blue.png"
      }
    end

    # process the queue
    args.state.fade_out_queue.each do |item|
      # default the alpha value if it isn't specified
      item.a ||= 255

      # decrement the alpha by 5 each frame
      item.a -= 5
    end

    # remove the item if it's completely faded out
    args.state.fade_out_queue.reject! { |item| item.a <= 0 }

    # render the sprites in the queue
    args.outputs.sprites << args.state.fade_out_queue
  end

```

### Animation Queues Advanced - main.rb
```ruby
  # ./samples/08_tweening_lerping_easing_functions/07_animation_queues_advanced/app/main.rb
  # sample app shows how to perform a fire and forget animation when a collision occurs
  def tick args
    defaults args
    spawn_bullets args
    calc_bullets args
    render args
  end

  def defaults args
    # place a player on the far left with sprite and hp information
    args.state.player ||= { x: 100, y: 360 - 50, w: 100, h: 100, path: "sprites/square/blue.png", hp: 30 }
    # create an array of bullets
    args.state.bullets ||= []
    # create a queue for handling bullet explosions
    args.state.explosion_queue ||= []
  end

  def spawn_bullets args
    # span a bullet in a random location on the far right every half second
    return if !Kernel.tick_count.zmod? 30
    args.state.bullets << {
      x: 1280 - 100,
      y: rand(720 - 100),
      w: 100,
      h: 100,
      path: "sprites/square/red.png"
    }
  end

  def calc_bullets args
    # for each bullet
    args.state.bullets.each do |b|
      # move it to the left by 20 pixels
      b.x -= 20

      # determine if the bullet collides with the player
      if b.intersect_rect? args.state.player
        # decrement the player's health if it does
        args.state.player.hp -= 1
        # mark the bullet as exploded
        b.exploded = true

        # queue the explosion by adding it to the explosion queue
        args.state.explosion_queue << b.merge(exploded_at: Kernel.tick_count)
      end
    end

    # remove bullets that have exploded so they wont be rendered
    args.state.bullets.reject! { |b| b.exploded }

    # remove animations from the animation queue that have completed
    # frame index will return nil once the animation has completed
    args.state.explosion_queue.reject! { |e| !e.exploded_at.frame_index(7, 4, false) }
  end

  def render args
    # render the player's hp above the sprite
    args.outputs.labels << {
      x: args.state.player.x + 50,
      y: args.state.player.y + 110,
      text: "#{args.state.player.hp}",
      alignment_enum: 1,
      vertical_alignment_enum: 0
    }

    # render the player
    args.outputs.sprites << args.state.player

    # render the bullets
    args.outputs.sprites << args.state.bullets

    # process the animation queue
    args.outputs.sprites << args.state.explosion_queue.map do |e|
      number_of_frames = 7
      hold_each_frame_for = 4
      repeat_animation = false
      # use the exploded_at property and the frame_index function to determine when the animation should start
      frame_index = e.exploded_at.frame_index(number_of_frames, hold_each_frame_for, repeat_animation)
      # take the explosion primitive and set the path variariable
      e.merge path: "sprites/misc/explosion-#{frame_index}.png"
    end
  end

```

### Tower Of Hanoi - main.rb
```ruby
  # ./samples/08_tweening_lerping_easing_functions/09_tower_of_hanoi/app/main.rb
  class Game
    attr_dr

    # get solution for hanoi tower
    # https://youtu.be/rf6uf3jNjbo
    def solve count, from, to, other
      solve_recur(count, from, to, other).flatten
    end

    # recursive function for getting solution
    def solve_recur count, from, to, other
      if count == 1
        [{ from: from, to: to }]
      else
        [
          solve(count - 1, from, other, to),
          { from: from, to: to },
          solve(count - 1, other, to, from)
        ]
      end
    end

    def post_message message
      return if state.message_at && state.message == message && state.message_at.elapsed_time < 180
      state.message = message
      state.message_at = Kernel.tick_count
    end

    # initialize default values
    def defaults
      # number of discs for tower
      state.disc_count ||= 4
      # queue for peg selection (items in queue are processed after animations complete)
      state.select_peg_queue ||= []

      # precompute button locations based off of a 24x12 grid
      state.undo_button_rect ||= Layout.rect(row: 11, col: 8, w: 4, h: 1)
      state.auto_solve_button_rect ||= Layout.rect(row: 11, col: 12, w: 4, h: 1)
      state.select_peg_1_button_rect ||= Layout.rect(row: 10, col: 1.5, w: 5, h: 1)
      state.select_peg_2_button_rect ||= Layout.rect(row: 10, col: 9.5, w: 5, h: 1)
      state.select_peg_3_button_rect ||= Layout.rect(row: 10, col: 17.5, w: 5, h: 1)

      # default duration for disc animations
      state.animation_duration ||= 15

      # history of moves (used for undoing and resetting game)
      state.move_history ||= []

      if !state.tower
        # generate discs
        discs = state.disc_count.map do |i|
          { sz: i + 1 }
        end

        # create pegs
        state.tower = {
          pegs: [
            { index: 0, discs: discs.reverse },
            { index: 1, discs: [] },
            { index: 2, discs: [] },
          ]
        }

        # calculate peg render and click locations
        state.tower.pegs.each do |peg|
          x = Layout.rect(row: 0, col: peg.index * 8, w: 8, h: 1).center.x
          y, h = Layout.rect(row: 2, col: 0, w: 1, h: 8).slice(:y, :h).values
          peg.render_box = {
            x: x,
            y: y,
            w: 32,
            h: h,
            anchor_x: 0.5,
          }

          peg.hit_box = {
            x: x,
            y: y,
            w: 256,
            h: h,
            anchor_x: 0.5,
          }
        end

        # associate buttons to pegs
        state.tower.pegs[0].button_rect = state.select_peg_1_button_rect
        state.tower.pegs[1].button_rect = state.select_peg_2_button_rect
        state.tower.pegs[2].button_rect = state.select_peg_3_button_rect
      end

      # compute hanoi solution
      state.solution ||= solve(state.disc_count, 0, 2, 1)
    end

    # queue peg selection
    def queue_select_peg(peg, add_history:, animation_duration:)
      state.select_peg_queue.push_back peg: peg,
                                       add_history: add_history,
                                       animation_duration: animation_duration
    end

    # select peg action
    def select_peg(peg, add_history:, animation_duration:)
      # return if peg is nil
      return if !peg

      if !state.from_peg && peg.discs.any?
        # if from_peg is not set and the peg that is being selected has discs
        # set the from_peg
        state.from_peg = peg
        # generate a disc event (used for animations)
        state.disc_event = {
          type: :take,
          from_peg: peg,
          to_peg: peg,
          at: Kernel.tick_count,
          disc: peg.discs.last,
          duration: animation_duration
        }

        # reset the destination peg
        state.to_peg = nil

        # record move history if option is true
        # (when undoing moves, we don't want to record history)
        state.move_history << peg.index if add_history
      elsif state.from_peg == peg
        # if the destination peg is the same as the start peg
        # create an animation event that is half way done so
        # that only the drop disc part of the animation is performed
        state.to_peg = peg
        state.disc_event = {
          type: :drop,
          from_peg: peg,
          to_peg: peg,
          disc: state.from_peg.discs.last,
          at: Kernel.tick_count - animation_duration,
          duration: animation_duration * 2
        }
        # set from peg to nil
        state.from_peg = nil
        # record move history
        state.move_history << peg.index if add_history
      elsif state.from_peg
        # if the start and destination pegs are different
        # check to see if the destination location is valid
        # (top disc must be larger than disc being placed)
        state.to_peg = peg
        disc = state.from_peg.discs.pop_back
        valid_move = !state.to_peg.discs.last || (state.to_peg.discs.last.sz > disc.sz)

        if valid_move
          # if it's valid, then pop the disc from the source
          # and place it at the destination
          state.to_peg.discs.push_back disc
          # create a drop event to animate disc
          state.disc_event = {
            type: :drop,
            from_peg: state.from_peg,
            to_peg: state.to_peg,
            disc: disc,
            at: Kernel.tick_count,
            duration: animation_duration * 2
          }
          # record move history
          state.move_history << peg.index if add_history
        else
          post_message "Invalid Move..."
          # if it's invalid, place the disc back onto its source peg
          state.from_peg.discs.push_back disc
          # create drop event to animate disc
          state.disc_event = {
            type: :drop,
            from_peg: state.from_peg,
            to_peg: state.from_peg,
            disc: disc,
            at: Kernel.tick_count,
            duration: animation_duration * 2
          }

          # remove the entry in history
          state.move_history.pop_back
        end

        # clear the origination peg
        state.from_peg = nil
      end
    end

    def calc_disc_positions
      # every frame, calculate the render location of discs
      state.tower.pegs.each do |peg|
        # for each peg
        peg.discs.each_with_index do |disc, i|
          # for each disc calculate the default x and y position for rendering
          default_x = peg.render_box.x
          default_y = peg.render_box.y + i * 32
          removed_from_peg_y = Layout.rect(row: 1, col: 0, w: 1, h: 1).center.y - 16

          if state.disc_event && state.disc_event.disc == disc && state.disc_event.type == :take
            # if there is a "take" disc event and the target is the disc currently being processed
            # compute the easing function and update x, y accordingly
            from_peg_x = state.disc_event.from_peg.render_box.x
            to_peg_x = state.disc_event.to_peg.render_box.x

            perc = Easing.smooth_start(start_at: state.disc_event.at,
                                       end_at: state.disc_event.at + state.disc_event.duration,
                                       tick_count: Kernel.tick_count,
                                       power: 2)

            x = from_peg_x.lerp(to_peg_x, perc)
            y = default_y.lerp(removed_from_peg_y, perc)
          elsif state.disc_event && state.disc_event.disc == disc && state.disc_event.type == :drop
            # if there is a "drop" disc event and the target is the disc currently being processed
            # compute the easing function and update x, y accordingly
            from_peg_x = state.disc_event.from_peg.render_box.x
            to_peg_x = state.disc_event.to_peg.render_box.x

            # first part of the animation is the movement to the new peg
            perc = Easing.smooth_start(start_at: state.disc_event.at,
                                       end_at: state.disc_event.at + state.disc_event.duration / 2,
                                       tick_count: Kernel.tick_count,
                                       power: 2)

            x = from_peg_x.lerp(to_peg_x, perc)

            # second part of the animation is the drop of the peg at the new location
            perc = Easing.smooth_start(start_at: state.disc_event.at + state.disc_event.duration / 2,
                                       end_at: state.disc_event.at + state.disc_event.duration,
                                       tick_count: Kernel.tick_count,
                                       power: 2)

            y = removed_from_peg_y.lerp(default_y, perc)
          else
            # if there is no disc event, then set the x and y value to the defaults
            # for the disc
            x = default_x
            y = default_y
          end

          # width of the disc is the width of the peg multiplied by its size
          w = peg.render_box.w + disc.sz * 32

          # set the disc's render box
          disc.render_box = {
            x: x,
            y: y,
            w: w,
            h: 32,
            anchor_x: 0.5
          }
        end
      end
    end

    def rollback_all_moves
      # based on the number of moves in the move history
      # slowly increase the animation speed during rollback
      move_count = state.move_history.length
      state.move_history.reverse.each_with_index do |entry, index|
        percentage_complete = (index + 1).fdiv move_count
        animation_duration = (state.animation_duration - state.animation_duration * percentage_complete).clamp(4, state.animation_duration)
        peg_index = state.move_history.pop_back
        peg = state.tower.pegs[peg_index]
        queue_select_peg peg, add_history: false, animation_duration: animation_duration.to_i
      end
    end

    def calc_auto_solve
      # return if already auto solving or if the game is completed
      return if state.auto_solving
      return if state.completed_at

      auto_solve_requested   = inputs.mouse.up && inputs.mouse.intersect_rect?(state.auto_solve_button_rect)
      auto_solve_requested ||= inputs.keyboard.key_down.space

      # if space is pressed, do an auto solve of the game
      if auto_solve_requested
        post_message "Auto Solving..."
        state.auto_solving = true
        # rollback all moves before starting the auto solve
        rollback_all_moves
        # based on the number of moves to complete the tower
        # slowly increase the animation speed
        move_count = 2**state.disc_count - 1
        state.solution.each_with_index do |move, index|
          percentage_complete = (index + 1).fdiv move_count
          animation_duration = (state.animation_duration - state.animation_duration * percentage_complete).clamp(4, state.animation_duration)
          queue_select_peg state.tower.pegs[move[:from]], add_history: true, animation_duration: animation_duration.to_i
          queue_select_peg state.tower.pegs[move[:to]], add_history: true, animation_duration: animation_duration.to_i
        end
      end
    end

    def calc_game_ended
      # game is completed if all discs are on the last peg
      all_discs_on_last_peg = state.tower.pegs[0].discs.length == 0 && state.tower.pegs[1].discs.length == 0
      if all_discs_on_last_peg
        state.completed_at ||= Kernel.tick_count
        state.started_at = nil
      end

      if state.completed_at == Kernel.tick_count
        post_message "Complete..."
      end

      # if the game is completed roll back everything so they can play again
      if state.completed_at && state.completed_at.elapsed_time > 60
        rollback_all_moves
      end

      # game is at the start if all discs are on the first peg
      all_discs_on_first_peg = state.tower.pegs[1].discs.length == 0 && state.tower.pegs[2].discs.length == 0
      if all_discs_on_first_peg
        state.completed_at = nil
        state.started_at ||= Kernel.tick_count
      end

      if state.started_at == Kernel.tick_count
        post_message "Ready..."
      end

      # if the game is at the start and there are no moves in
      # the move history or in the select peg queue,
      # then set auto solving to false
      if all_discs_on_first_peg && state.move_history.length == 0 && state.select_peg_queue.length == 0
        state.auto_solving = false
      end
    end

    def calc_input
      return if state.auto_solving
      return if state.completed_at

      # process user input either mouse or keyboard
      state.hovered_peg = state.tower.pegs.find { |peg| inputs.mouse.intersect_rect?(peg.hit_box) || inputs.mouse.intersect_rect?(peg.button_rect) }

      undo_requested   = inputs.mouse.up && inputs.mouse.intersect_rect?(state.undo_button_rect)
      undo_requested ||= inputs.keyboard.key_down.u
      undo_requested   = false if state.move_history.length == 0

      # keyboard j, k, l to select pegs, u to undo
      if inputs.keyboard.key_down.j
        queue_select_peg state.tower.pegs[0], add_history: true, animation_duration: state.animation_duration
      elsif inputs.keyboard.key_down.k
        queue_select_peg state.tower.pegs[1], add_history: true, animation_duration: state.animation_duration
      elsif inputs.keyboard.key_down.l
        queue_select_peg state.tower.pegs[2], add_history: true, animation_duration: state.animation_duration
      elsif undo_requested
        post_message "Undo..."
        if state.move_history.length.even?
          peg_index = state.move_history.pop_back
          peg = state.tower.pegs[peg_index]
          queue_select_peg peg, add_history: false, animation_duration: state.animation_duration

          peg_index = state.move_history.pop_back
          peg = state.tower.pegs[peg_index]
          queue_select_peg peg, add_history: false, animation_duration: state.animation_duration
        else
          peg_index = state.move_history.pop_back
          peg = state.tower.pegs[peg_index]
          queue_select_peg peg, add_history: false, animation_duration: state.animation_duration
        end
      end

      # peg selection using mouse
      if state.hovered_peg && inputs.mouse.up
        queue_select_peg state.hovered_peg, add_history: true, animation_duration: state.animation_duration
      end
    end

    def calc_peg_queue
      # don't process selection queue if there are animation events pending
      disc_event_elapsed = if !state.disc_event
                             true
                           else
                             state.disc_event.at.elapsed_time > state.disc_event.duration
                           end


      # if there are no animation events then process the first item from the queue
      if disc_event_elapsed && state.select_peg_queue.length > 0
        entry = state.select_peg_queue.pop_front
        select_peg entry.peg, add_history: entry.add_history, animation_duration: entry.animation_duration
      end
    end

    def calc
      calc_disc_positions
      calc_auto_solve
      calc_game_ended
      calc_input
      calc_peg_queue
    end

    def render
      # render background
      outputs.background_color = [30, 30, 30]

      # render message
      if state.message && state.message_at
        duration = 180
        # spline represents an easing function for fading in and out
        # of the message
        spline_definition = [
          [0.00, 0.00, 0.66, 1.00],
          [1.00, 1.00, 1.00, 1.00],
          [1.00, 0.66, 0.00, 0.00]
        ]

        perc = Easing.spline state.message_at,
                             Kernel.tick_count,
                             duration,
                             spline_definition

        outputs.primitives << Layout.rect(row: 0, col: 0, w: 24, h: 1)
                                    .center
                                    .merge(text: state.message,
                                           anchor_x: 0.5,
                                           anchor_y: 0.5,
                                           r: 255, g: 255, b: 255,
                                           anchor_x: 0.5,
                                           anchor_y: 0.5,
                                           size_px: 32,
                                           a: 255 * perc)
      end

      # render pegs
      outputs.primitives << state.tower.pegs.map do |peg|
        peg.render_box.merge(path: :solid, r: 128, g: 128, b: 128)
      end

      # render visual indicators for currently hovered peg
      if state.hovered_peg && inputs.last_active == :mouse
        outputs.primitives << state.hovered_peg.render_box.merge(path: :solid, r: 80, g: 128, b: 80)
      end

      # render visual indicator for selected peg
      if state.from_peg
        outputs.primitives << state.from_peg.render_box.merge(path: :solid, r: 80, g: 80, b: 128)
      end

      # render visual indicator for destination peg
      if state.to_peg
        outputs.primitives << state.to_peg.render_box.merge(path: :solid, r: 0, g: 80, b: 80)
      end

      # render disks
      outputs.primitives << state.tower.pegs.map do |peg|
        peg.discs.map do |disc|
          disc.render_box.merge(path: :solid, r: 200, g: 200, b: 200).scale_rect(0.95)
        end
      end

      # render platform/intput specific controls
      if inputs.last_active == :keyboard
        outputs.primitives << button_prefab(state.select_peg_1_button_rect, "J: Select Peg 1")
        outputs.primitives << button_prefab(state.select_peg_2_button_rect, "K: Select Peg 2")
        outputs.primitives << button_prefab(state.select_peg_3_button_rect, "L: Select Peg 3")
        outputs.primitives << button_prefab(state.undo_button_rect, "U: Undo")
        outputs.primitives << button_prefab(state.auto_solve_button_rect, "Space: Auto Solve")
      else
        action_text = if DR.platform?(:touch)
                        "Tap"
                      else
                        "Click"
                      end

        outputs.primitives << button_prefab(state.select_peg_1_button_rect, "#{action_text}: Select Peg 1")
        outputs.primitives << button_prefab(state.select_peg_2_button_rect, "#{action_text}: Select Peg 2")
        outputs.primitives << button_prefab(state.select_peg_3_button_rect, "#{action_text}: Select Peg 3")
        outputs.primitives << button_prefab(state.undo_button_rect, "Undo")
        outputs.primitives << button_prefab(state.auto_solve_button_rect, "Auto Solve")
      end
    end

    def button_prefab rect, text
      color = if inputs.mouse.intersect_rect?(rect)
                { r: 255, g: 255, b: 255 }
              else
                { r: 128, g: 128, b: 128 }
              end
      [
        rect.merge(primitive_marker: :border, **color),
        rect.center.merge(text: text, r: 255, g: 255, b: 255, anchor_x: 0.5, anchor_y: 0.5)
      ]
    end

    def tick
      # execution pipeline
      # initialize game defaults, calculate game, render game
      defaults
      calc
      render
    end
  end

  def boot args
    args.state = { }
  end

  def tick args
    # entry point
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
  end

  DR.reset

```
