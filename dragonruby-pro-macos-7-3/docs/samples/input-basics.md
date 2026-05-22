### Keyboard - main.rb
```ruby
  # ./samples/02_input_basics/01_keyboard/app/main.rb
  =begin

  APIs listing that haven't been encountered in a previous sample apps:

  - args.inputs.keyboard.key_up.KEY: The value of the properties will be set
    to the frame  that the key_up event occurred (the frame correlates
    to Kernel.tick_count). Otherwise the value will be nil. For a
    full listing of keys, take a look at docs/api/inputs.md.
  - args.state.PROPERTY: The state property on args is a dynamic
    structure. You can define ANY property here with ANY type of
    arbitrary nesting. Properties defined on args.state will be retained
    across frames. If you attempt access a property that doesn't exist
    on args.state, it will simply return nil (no exception will be thrown).

  =end

  # Along with outputs, inputs are also an essential part of video game development
  # DragonRuby can take input from keyboards, mouse, and controllers.
  # This sample app will cover keyboard input.

  # args.inputs.keyboard.key_up.a will check to see if the a key has been pressed
  # This will work with the other keys as well


  def tick args
    tick_instructions args, "Sample app shows how keyboard events are registered and accessed.", 360
    args.outputs.labels << { x: 460, y: row_to_px(args, 0), text: "Current game time: #{Kernel.tick_count}", size_enum: -1 }
    args.outputs.labels << { x: 460, y: row_to_px(args, 2), text: "Keyboard input: args.inputs.keyboard.key_up.h", size_enum: -1 }
    args.outputs.labels << { x: 460, y: row_to_px(args, 3), text: "Press \"h\" on the keyboard.", size_enum: -1 }

    # Input on a specifc key can be found through args.inputs.keyboard.key_up followed by the key
    if args.inputs.keyboard.key_up.h
      args.state.h_pressed_at = Kernel.tick_count
    end

    # This code simplifies to if args.state.h_pressed_at has not been initialized, set it to false
    args.state.h_pressed_at ||= false

    if args.state.h_pressed_at
      args.outputs.labels << { x: 460, y: row_to_px(args, 4), text: "\"h\" was pressed at time: #{args.state.h_pressed_at}", size_enum: -1 }
    else
      args.outputs.labels << { x: 460, y: row_to_px(args, 4), text: "\"h\" has never been pressed.", size_enum: -1 }
    end

    tick_help_text args
  end

  def row_to_px args, row_number, y_offset = 20
    # This takes a row_number and converts it to pixels DragonRuby understands.
    # Row 0 starts 5 units below the top of the grid
    # Each row afterward is 20 units lower
    args.grid.top - 5 - (y_offset * row_number)
  end

  # Don't worry about understanding the code within this method just yet.
  # This method shows you the help text within the game.
  def tick_help_text args
    return unless args.state.h_pressed_at

    args.state.key_value_history      ||= {}
    args.state.key_down_value_history ||= {}
    args.state.key_held_value_history ||= {}
    args.state.key_up_value_history   ||= {}

    if (args.inputs.keyboard.key_down.truthy_keys.length > 0 ||
        args.inputs.keyboard.key_held.truthy_keys.length > 0 ||
        args.inputs.keyboard.key_up.truthy_keys.length > 0)
      args.state.help_available = true
      args.state.no_activity_debounce = nil
    else
      args.state.no_activity_debounce ||= 5.seconds
      args.state.no_activity_debounce -= 1
      if args.state.no_activity_debounce <= 0
        args.state.help_available = false
        args.state.key_value_history        = {}
        args.state.key_down_value_history   = {}
        args.state.key_held_value_history   = {}
        args.state.key_up_value_history     = {}
      end
    end

    args.outputs.labels << { x: 10, y: row_to_px(args, 6), text: "This is the api for the keys you've pressed:", size_enum: -1, r: 180 }

    if !args.state.help_available
      args.outputs.labels << [10, row_to_px(args, 7),  "Press a key and I'll show code to access the key and what value will be returned if you used the code."]
      return
    end

    args.outputs.labels << { x: 10 , y: row_to_px(args, 7), text: "args.inputs.keyboard",          size_enum: -2 }
    args.outputs.labels << { x: 330, y: row_to_px(args, 7), text: "args.inputs.keyboard.key_down", size_enum: -2 }
    args.outputs.labels << { x: 650, y: row_to_px(args, 7), text: "args.inputs.keyboard.key_held", size_enum: -2 }
    args.outputs.labels << { x: 990, y: row_to_px(args, 7), text: "args.inputs.keyboard.key_up",   size_enum: -2 }

    fill_history args, :key_value_history,      :down_or_held, nil
    fill_history args, :key_down_value_history, :down,        :key_down
    fill_history args, :key_held_value_history, :held,        :key_held
    fill_history args, :key_up_value_history,   :up,          :key_up

    render_help_labels args, :key_value_history,      :down_or_held, nil,      10
    render_help_labels args, :key_down_value_history, :down,        :key_down, 330
    render_help_labels args, :key_held_value_history, :held,        :key_held, 650
    render_help_labels args, :key_up_value_history,   :up,          :key_up,   990
  end

  def fill_history args, history_key, state_key, keyboard_method
    fill_single_history args, history_key, state_key, keyboard_method, :raw_key
    fill_single_history args, history_key, state_key, keyboard_method, :char
    args.inputs.keyboard.keys[state_key].each do |key_name|
      fill_single_history args, history_key, state_key, keyboard_method, key_name
    end
  end

  def fill_single_history args, history_key, state_key, keyboard_method, key_name
    current_value = args.inputs.keyboard.send(key_name)
    if keyboard_method
      current_value = args.inputs.keyboard.send(keyboard_method).send(key_name)
    end
    args.state.as_hash[history_key][key_name] ||= []
    args.state.as_hash[history_key][key_name] << current_value
    args.state.as_hash[history_key][key_name] = args.state.as_hash[history_key][key_name].reverse.uniq.take(3).reverse
  end

  def render_help_labels args, history_key, state_key, keyboard_method, x
    idx = 8
    args.outputs.labels << args.state
                             .as_hash[history_key]
                             .keys
                             .reverse
                             .map
                             .with_index do |k, i|
      v = args.state.as_hash[history_key][k]
      current_value = args.inputs.keyboard.send(k)
      if keyboard_method
        current_value = args.inputs.keyboard.send(keyboard_method).send(k)
      end
      idx += 2
      [
        { x: x, y: row_to_px(args, idx + 0, 16), text: "    .#{k} is #{current_value || "nil"}", size_enum: -2 },
        { x: x, y: row_to_px(args, idx + 1, 16), text: "       was #{v}", size_enum: -2 }
      ]
    end
  end


  def tick_instructions args, text, y = 715
    return if args.state.key_event_occurred
    if args.inputs.mouse.click ||
       args.inputs.keyboard.directional_vector ||
       args.inputs.keyboard.key_down.enter ||
       args.inputs.keyboard.key_down.escape
      args.state.key_event_occurred = true
    end

    args.outputs.debug << { x: 0,   y: y - 50, w: 1280, h: 60 }.solid!
    args.outputs.debug << { x: 640, y: y,      text: text,
                            size_enum: 1, alignment_enum: 1, r: 255, g: 255, b: 255 }.label!
    args.outputs.debug << { x: 640, y: y - 25, text: "(click to dismiss instructions)",
                            size_enum: -2, alignment_enum: 1, r: 255, g: 255, b: 255 }.label!
  end

```

### Moving A Sprite - main.rb
```ruby
  # ./samples/02_input_basics/01_moving_a_sprite/app/main.rb
  def boot args
    # initialize state to an empty top level hash on boot
    args.state = {}
  end

  def tick args
    # Create a player and set default values
    # NOTE: args.state is a construct that lets you define properties on the fly
    args.state.player ||= { x: 100,
                            y: 100,
                            w: 50,
                            h: 50,
                            path: 'sprites/square/green.png' }

    # move the player around by consulting args.inputs
    # the top level args.inputs checks the keyboard's arrow keys, WASD,
    # and controller one
    if args.inputs.up
      args.state.player.y += 10
    elsif args.inputs.down
      args.state.player.y -= 10
    end

    if args.inputs.left
      args.state.player.x -= 10
    elsif args.inputs.right
      args.state.player.x += 10
    end

    # Render the player to the screen
    args.outputs.sprites << args.state.player
  end

```

### Mouse - main.rb
```ruby
  # ./samples/02_input_basics/02_mouse/app/main.rb
  =begin

  APIs that haven't been encountered in a previous sample apps:

  - args.inputs.mouse.click: This property will be set if the mouse was clicked.
  - args.inputs.mouse.click.(x|y): The x and y location of the mouse.
  - args.inputs.mouse.click.created_at: The frame the mouse click occurred in.
  - args.inputs.mouse.click.created_at_elapsed: How many frames have passed
    since the click event.

  Reminder:

  - args.state.PROPERTY: The state property on args is a dynamic
    structure. You can define ANY property here with ANY type of
    arbitrary nesting. Properties defined on args.state will be retained
    across frames. If you attempt access a property that doesn't exist
    on args.state, it will simply return nil (no exception will be thrown).

  =end

  # This code demonstrates DragonRuby mouse input

  # To see if the a mouse click occurred
  # Use args.inputs.mouse.click
  # Which returns a boolean

  # To see where a mouse click occurred
  # Use args.inputs.mouse.click.x AND
  # args.inputs.mouse.click.y

  # To see which frame the click occurred
  # Use args.inputs.mouse.click.created_at

  # To see how many frames its been since the click occurred
  # Use args.inputs.mouse.click.created_at_elapsed

  # Saving the click in args.state can be quite useful

  def tick args
    args.outputs.labels << { x: 640,
                             y: 700,
                             anchor_x: 0.5,
                             anchor_y: 0.5,
                             text: "Sample app shows how mouse events are registered and how to measure elapsed time." }

    args.outputs.labels << { x: 640, y: 540, text: "Mouse input: args.inputs.mouse", anchor_x: 0.5, anchor_y: 0.5 }

    if args.inputs.mouse.click
      args.state.last_mouse_click = args.inputs.mouse.click
    end

    if args.state.last_mouse_click
      click = args.state.last_mouse_click
      args.outputs.labels << { x: 640, y: 360, text: "Mouse click happened at: #{click.created_at}", anchor_x: 0.5, anchor_y: 0.5 - 1 }
      args.outputs.labels << { x: 640, y: 360, text: "Mouse clicked #{click.created_at_elapsed} ticks ago", anchor_x: 0.5, anchor_y: 0.5 }
      args.outputs.labels << { x: 640, y: 360, text: "Mouse click location: #{click.x}, #{click.y}", anchor_x: 0.5, anchor_y: 0.5 + 1 }
    else
      args.outputs.labels << { x: 640, y: 360, text: "Mouse click has not occurred yet.", anchor_x: 0.5, anchor_y: 0.5 - 0.5 }
      args.outputs.labels << { x: 640, y: 360, text: "Please click mouse.", anchor_x: 0.5, anchor_y: 0.5 + 0.5 }
    end
  end

```

### Mouse Properties - main.rb
```ruby
  # ./samples/02_input_basics/02_mouse_properties/app/main.rb
  def tick args
    args.state.properties = [
      { name: "Top Level properties" },
      { name: "mouse.x", value: args.inputs.mouse.x },
      { name: "mouse.y", value: args.inputs.mouse.y },
      { name: "mouse.wheel", value: args.inputs.mouse.wheel },
      { name: "mouse.moved", value: args.inputs.mouse.moved },
      { name: "mouse.moved_at", value: args.inputs.mouse.moved_at },
      { name: "mouse.click", value: args.inputs.mouse.click },
      { name: "mouse.click_at", value: args.inputs.mouse.click_at },
      { name: "mouse.held", value: args.inputs.mouse.held },
      { name: "mouse.held_at", value: args.inputs.mouse.held_at },
      { name: "mouse.up", value: args.inputs.mouse.up },
      { name: "mouse.up_at", value: args.inputs.mouse.up_at },
      { name: "" },
      { name: "Keys" },
      { name: "mouse.key_down.left", value: args.inputs.mouse.key_down.left },
      { name: "mouse.key_held.left", value: args.inputs.mouse.key_held.left },
      { name: "mouse.key_up.left", value: args.inputs.mouse.key_up.left },
      { name: "mouse.key_down.right", value: args.inputs.mouse.key_down.right },
      { name: "mouse.key_held.right", value: args.inputs.mouse.key_held.right },
      { name: "mouse.key_up.right", value: args.inputs.mouse.key_up.right },
      { name: "mouse.button_bits.to_s(2)", value: args.inputs.mouse.button_bits.to_s(2) },
      { name: "mouse.button_left", value: args.inputs.mouse.button_left },
      { name: "mouse.button_right", value: args.inputs.mouse.button_right },
      { name: "" },
      { name: "Buttons" },
      { name: "mouse.button_bits", value: args.inputs.mouse.button_bits.to_s(2) },
      { name: "mouse.button_left", value: args.inputs.mouse.button_left },
      { name: "mouse.buttons.left.click", value: args.inputs.mouse.buttons.left.click },
      { name: "mouse.buttons.left.click_at", value: args.inputs.mouse.buttons.left.click_at },
      { name: "mouse.buttons.left.held", value: args.inputs.mouse.buttons.left.held },
      { name: "mouse.buttons.left.held_at", value: args.inputs.mouse.buttons.left.held_at },
      { name: "mouse.buttons.left.up", value: args.inputs.mouse.buttons.left.up },
      { name: "mouse.buttons.left.up_at", value: args.inputs.mouse.buttons.left.up_at },
      { name: "mouse.buttons.left.buffered_click", value: args.inputs.mouse.buttons.left.buffered_click },
      { name: "mouse.buttons.left.buffered_held", value: args.inputs.mouse.buttons.left.buffered_held },
      { name: "mouse.button_right", value: args.inputs.mouse.button_left },
      { name: "mouse.buttons.right.click", value: args.inputs.mouse.buttons.right.click },
      { name: "mouse.buttons.right.click_at", value: args.inputs.mouse.buttons.right.click_at },
      { name: "mouse.buttons.right.held", value: args.inputs.mouse.buttons.right.held },
      { name: "mouse.buttons.right.held_at", value: args.inputs.mouse.buttons.right.held_at },
      { name: "mouse.buttons.right.up", value: args.inputs.mouse.buttons.right.up },
      { name: "mouse.buttons.right.up_at", value: args.inputs.mouse.buttons.right.up_at },
      { name: "mouse.buttons.right.buffered_click", value: args.inputs.mouse.buttons.right.buffered_click },
      { name: "mouse.buttons.right.buffered_held", value: args.inputs.mouse.buttons.right.buffered_held },
    ]

    args.outputs.primitives << args.state.highlight_fx

    args.outputs.labels << args.state.properties.map_with_index do |property, i|
      text = if property.key?(:value)
               "#{property.name}: #{property.value.inspect}"
             else
               property.name
             end
      {
        x: 16,
        y: 720 - 8 - i * 16,
        text: text,
        size_px: 14
      }
    end
  end

```

### Mouse Point To Rect - main.rb
```ruby
  # ./samples/02_input_basics/03_mouse_point_to_rect/app/main.rb
  =begin
  - Example usage of Hash#inside_rect? to determine if a mouse click happened
    inside of a box.
    ```
    rect_1 = { x: 100, y: 100, w:   1, h:   1 }
    rect_2 = { x:   0, y:   0, w: 500, h: 500 }
    result = rect_1.inside_rect? rect_2
    ```
  =end
  def tick args
    # initialize the rectangle
    args.state.box ||= { x: 785, y: 370, w: 50, h: 50, r: 0, g: 0, b: 170 }

    # store the mouse click and the frame the click occurred
    # and whether it was inside or outside the box
    if args.inputs.mouse.click
      args.state.last_mouse_click = args.inputs.mouse.click
      args.state.last_mouse_click_at = Kernel.tick_count
      if args.state.last_mouse_click.inside_rect? args.state.box
        args.state.was_inside_rect = true
      else
        args.state.was_inside_rect = false
      end
    end

    # render
    args.outputs.labels << { x: 640, y: 700, anchor_x: 0.5, anchor_y: 0.5, text: "Sample app shows how to determine if a click happened inside a rectangle." }
    args.outputs.labels << { x: 340, y: 420, text:  "Click inside (or outside) the blue box ---->" }

    args.outputs.borders << args.state.box

    if args.state.last_mouse_click
      if args.state.was_inside_rect
        args.outputs.labels << { x: 810,
                                 y: 340,
                                 anchor_x: 0.5,
                                 anchor_y: 0.5,
                                 text: "Mouse click happened *inside* the box [frame #{args.state.last_mouse_click_at}]." }
      else
        args.outputs.labels << { x: 810,
                                 y: 340,
                                 anchor_x: 0.5,
                                 anchor_y: 0.5,
                                 text: "Mouse click happened *outside* the box [frame #{args.state.last_mouse_click_at}]." }
      end
    else
      args.outputs.labels << { x: 810,
                               y: 340,
                               anchor_x: 0.5,
                               anchor_y: 0.5,
                               text: "Waiting for mouse click..." }
    end
  end

```

### Mouse Drag And Drop - main.rb
```ruby
  # ./samples/02_input_basics/04_mouse_drag_and_drop/app/main.rb
  def tick args
    # create 10 random squares on the screen
    if !args.state.squares
      # the squares will be contained in lookup/Hash so that we can access via their id
      args.state.squares = {}
      10.times_with_index do |id|
        # for each square, store it in the hash with
        # the id (we're just using the index 0-9 as the index)
        args.state.squares[id] = {
          id: id,
          x: 100 + (rand * 1080),
          y: 100 + (520 * rand),
          w: 100,
          h: 100,
          path: "sprites/square/blue.png"
        }
      end
    end

    # two key variables are set here
    # - square_reference: this represents the square that is currently being dragged
    # - square_under_mouse: this represents the square that the mouse is currently being hovered over
    if args.state.currently_dragging_square_id
      # if the currently_dragging_square_id is set, then set the "square_under_mouse" to
      # the same square as square_reference
      square_reference = args.state.squares[args.state.currently_dragging_square_id]
      square_under_mouse = square_reference
    else
      # if currently_dragging_square_id isn't set, then see if there is a square that
      # the mouse is currently hovering over (the square reference will be nil since
      # we haven't selected a drag target yet)
      square_under_mouse = Geometry.find_intersect_rect args.inputs.mouse, args.state.squares.values
      square_reference = nil
    end


    # if a click occurs, and there is a square under the mouse
    if args.inputs.mouse.click && square_under_mouse
      # capture the id of the square that the mouse is hovering over
      args.state.currently_dragging_square_id = square_under_mouse.id

      # also capture where in the square the mouse was clicked so that
      # the movement of the square will smoothly transition with the mouse's
      # location
      args.state.mouse_point_inside_square = {
        x: args.inputs.mouse.x - square_under_mouse.x,
        y: args.inputs.mouse.y - square_under_mouse.y,
      }
    elsif args.inputs.mouse.held && args.state.currently_dragging_square_id
      # if the mouse is currently being held and the currently_dragging_square_id was set,
      # then update the x and y location of the referenced square (taking into consideration the
      # relative position of the mouse when the square was clicked)
      square_reference.x = args.inputs.mouse.x - args.state.mouse_point_inside_square.x
      square_reference.y = args.inputs.mouse.y - args.state.mouse_point_inside_square.y
    elsif args.inputs.mouse.up
      # if the mouse is released, then clear out the currently_dragging_square_id
      args.state.currently_dragging_square_id = nil
    end

    # render all the squares on the screen
    args.outputs.sprites << args.state.squares.values

    # if there was a square under the mouse, add an "overlay"
    if square_under_mouse
      args.outputs.sprites << square_under_mouse.merge(path: "sprites/square/red.png")
    end
  end

  DR.recording.on_replay_completed_successfully do |args|
    raise "Square was not in the right place" if args.state.squares[2].x.floor != 746
  end

```

### Mouse Rect To Rect - main.rb
```ruby
  # ./samples/02_input_basics/04_mouse_rect_to_rect/app/main.rb
  =begin

  APIs that haven't been encountered in a previous sample apps:

  - args.outputs.borders: An array. Values in this array will be rendered as
    unfilled rectangles on the screen.
  - ARRAY#intersect_rect?: An array with at least four values is
    considered a rect. The intersect_rect? function returns true
    or false depending on if the two rectangles intersect.

    ```
    # Rect One: x: 100, y: 100, w: 100, h: 100
    # Rect Two: x: 0, y: 0, w: 500, h: 500
    # Result:   true

    [100, 100, 100, 100].intersect_rect? [0, 0, 500, 500]
    ```

    ```
    # Rect One: x: 100, y: 100, w: 10, h: 10
    # Rect Two: x: 500, y: 500, w: 10, h: 10
    # Result:   false

    [100, 100, 10, 10].intersect_rect? [500, 500, 10, 10]
    ```

  =end

  # Similarly, whether rects intersect can be found through
  # rect1.intersect_rect? rect2

  def tick args
    tick_instructions args, "Sample app shows how to determine if two rectangles intersect."
    x = 460

    args.outputs.labels << small_label(args, x, 3, "Click anywhere on the screen")
    # red_box = [460, 250, 355, 90, 170, 0, 0]
    # args.outputs.borders << red_box

    # args.state.box_collision_one and args.state.box_collision_two
    # Are given values of a solid when they should be rendered
    # They are stored in game so that they do not get reset every tick
    if args.inputs.mouse.click
      if !args.state.box_collision_one
        args.state.box_collision_one = { x: args.inputs.mouse.click.point.x - 25,
                                         y: args.inputs.mouse.click.point.y - 25,
                                         w: 125, h: 125,
                                         r: 180, g: 0, b: 0, a: 180 }
      elsif !args.state.box_collision_two
        args.state.box_collision_two = { x: args.inputs.mouse.click.point.x - 25,
                                         y: args.inputs.mouse.click.point.y - 25,
                                         w: 125, h: 125,
                                         r: 0, g: 0, b: 180, a: 180 }
      else
        args.state.box_collision_one = nil
        args.state.box_collision_two = nil
      end
    end

    if args.state.box_collision_one
      args.outputs.solids << args.state.box_collision_one
    end

    if args.state.box_collision_two
      args.outputs.solids << args.state.box_collision_two
    end

    if args.state.box_collision_one && args.state.box_collision_two
      if args.state.box_collision_one.intersect_rect? args.state.box_collision_two
        args.outputs.labels << small_label(args, x, 4, 'The boxes intersect.')
      else
        args.outputs.labels << small_label(args, x, 4, 'The boxes do not intersect.')
      end
    else
      args.outputs.labels << small_label(args, x, 4, '--')
    end
  end

  def small_label args, x, row, message
    { x: x, y: row_to_px(args, row), text: message, size_enum: -2 }
  end

  def row_to_px args, row_number
    args.grid.top - 5 - (20 * row_number)
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

### Controller - main.rb
```ruby
  # ./samples/02_input_basics/05_controller/app/main.rb
  =begin

   APIs listing that haven't been encountered in previous sample apps:

   - args.current_controller.key_held.KEY: Will check to see if a specific key
     is being held down on the controller.
     If there is more than one controller being used, they can be differentiated by
     using names like controller_one and controller_two.

     For a full listing of buttons, take a look at mygame/documentation/08-controllers.md.

   Reminder:

   - args.state.PROPERTY: The state property on args is a dynamic
     structure. You can define ANY property here with ANY type of
     arbitrary nesting. Properties defined on args.state will be retained
     across frames. If you attempt to access a property that doesn't exist
     on args.state, it will simply return nil (no exception will be thrown).

     In this sample app, args.state.BUTTONS is an array that stores the buttons of the controller.
     The parameters of a button are:
     1. the position (x, y)
     2. the input key held on the controller
     3. the text or name of the button

  =end

  # This sample app provides a visual demonstration of a standard controller, including
  # the placement and function of all buttons.

  class ControllerDemo
    attr_accessor :inputs, :state, :outputs

    # Calls the methods necessary for the app to run successfully.
    def tick
      process_inputs
      render
    end

    # Starts with an empty collection of buttons.
    # Adds buttons that are on the controller to the collection.
    def process_inputs
      state.target  ||= :controller_one
      state.buttons = []

      if inputs.keyboard.key_down.tab
        if state.target == :controller_one
          state.target = :controller_two
        elsif state.target == :controller_two
          state.target = :controller_three
        elsif state.target == :controller_three
          state.target = :controller_four
        elsif state.target == :controller_four
          state.target = :controller_one
        end
      end

      state.buttons << { x: 100,  y: 500, active: current_controller.key_held.l1, text: "L1"}
      state.buttons << { x: 100,  y: 600, active: current_controller.key_held.l2, text: "L2"}
      state.buttons << { x: 1100, y: 500, active: current_controller.key_held.r1, text: "R1"}
      state.buttons << { x: 1100, y: 600, active: current_controller.key_held.r2, text: "R2"}
      state.buttons << { x: 540,  y: 450, active: current_controller.key_held.select, text: "Select"}
      state.buttons << { x: 660,  y: 450, active: current_controller.key_held.start, text: "Start"}
      state.buttons << { x: 200,  y: 300, active: current_controller.key_held.left, text: "Left"}
      state.buttons << { x: 300,  y: 400, active: current_controller.key_held.up, text: "Up"}
      state.buttons << { x: 400,  y: 300, active: current_controller.key_held.right, text: "Right"}
      state.buttons << { x: 300,  y: 200, active: current_controller.key_held.down, text: "Down"}
      state.buttons << { x: 800,  y: 300, active: current_controller.key_held.x, text: "X"}
      state.buttons << { x: 900,  y: 400, active: current_controller.key_held.y, text: "Y"}
      state.buttons << { x: 1000, y: 300, active: current_controller.key_held.a, text: "A"}
      state.buttons << { x: 900,  y: 200, active: current_controller.key_held.b, text: "B"}
      state.buttons << { x: 450 + current_controller.left_analog_x_perc * 100,
                         y: 100 + current_controller.left_analog_y_perc * 100,
                         active: current_controller.key_held.l3,
                         text: "L3" }
      state.buttons << { x: 750 + current_controller.right_analog_x_perc * 100,
                         y: 100 + current_controller.right_analog_y_perc * 100,
                         active: current_controller.key_held.r3,
                         text: "R3" }
    end

    # Gives each button a square shape.
    # If the button is being pressed or held (which means it is considered active),
    # the square is filled in. Otherwise, the button simply has a border.
    def render
      state.buttons.each do |b|
        rect = { x: b.x, y: b.y, w: 75, h: 75 }

        if b.active # if button is pressed
          outputs.solids << rect # rect is output as solid (filled in)
        else
          outputs.borders << rect # otherwise, output as border
        end

        # Outputs the text of each button using labels.
        outputs.labels << { x: b.x, y: b.y + 95, text: b.text } # add 95 to place label above button
      end

      outputs.labels << { x:  10, y: 60, text: "Left Analog x: #{current_controller.left_analog_x_raw} (#{current_controller.left_analog_x_perc * 100}%)" }
      outputs.labels << { x:  10, y: 30, text: "Left Analog y: #{current_controller.left_analog_y_raw} (#{current_controller.left_analog_y_perc * 100}%)" }
      outputs.labels << { x: 1270, y: 60, text: "Right Analog x: #{current_controller.right_analog_x_raw} (#{current_controller.right_analog_x_perc * 100}%)", alignment_enum: 2 }
      outputs.labels << { x: 1270, y: 30, text: "Right Analog y: #{current_controller.right_analog_y_raw} (#{current_controller.right_analog_y_perc * 100}%)" , alignment_enum: 2 }

      outputs.labels << { x: 640, y: 60, text: "Target: #{state.target} (press tab to go to next controller)", alignment_enum: 1 }
      outputs.labels << { x: 640, y: 30, text: "Connected: #{current_controller.connected}", alignment_enum: 1 }
    end

    def current_controller
      if state.target == :controller_one
        return inputs.controller_one
      elsif state.target == :controller_two
        return inputs.controller_two
      elsif state.target == :controller_three
        return inputs.controller_three
      elsif state.target == :controller_four
        return inputs.controller_four
      end
    end
  end

  $controller_demo = ControllerDemo.new

  def tick args
    tick_instructions args, "Sample app shows how controller input is handled. You'll need to connect a USB controller."
    $controller_demo.inputs = args.inputs
    $controller_demo.state = args.state
    $controller_demo.outputs = args.outputs
    $controller_demo.tick
  end

  # Resets the app.
  def r
    DR.reset
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

### Touch - main.rb
```ruby
  # ./samples/02_input_basics/06_touch/app/main.rb
  def tick args
    args.outputs.background_color = [ 0, 0, 0 ]
    args.outputs.primitives << [640, 700, "Touch your screen.", 5, 1, 255, 255, 255].label

    # If you don't want to get fancy, you can just look for finger_one
    #  (and _two, if you like), which are assigned in the order new touches hit
    #  the screen. If not nil, they are touching right now, and are just
    #  references to specific items in the args.input.touch hash.
    # If finger_one lifts off, it will become nil, but finger_two, if it was
    #  touching, remains until it also lifts off. When all fingers lift off, the
    #  the next new touch will be finger_one again, but until then, new touches
    #  don't fill in earlier slots.
    if !args.inputs.finger_one.nil?
      args.outputs.primitives << { x: 640, y: 650, text: "Finger #1 is touching at (#{args.inputs.finger_one.x}, #{args.inputs.finger_one.y}).",
                                   size_enum: 5, alignment_enum: 1, r: 255, g: 255, b: 255 }.label!
    end
    if !args.inputs.finger_two.nil?
      args.outputs.primitives << { x: 640, y: 600, text: "Finger #2 is touching at (#{args.inputs.finger_two.x}, #{args.inputs.finger_two.y}).",
                                   size_enum: 5, alignment_enum: 1, r: 255, g: 255, b: 255 }.label!
    end

    # Here's the more flexible interface: this will report as many simultaneous
    #  touches as the system can handle, but it's a little more effort to track
    #  them. Each item in the args.input.touch hash has a unique key (an
    #  incrementing integer) that exists until the finger lifts off. You can
    #  tell which order the touches happened globally by the key value, or
    #  by the touch[id].touch_order field, which resets to zero each time all
    #  touches have lifted.

    args.state.colors ||= [
      0xFF0000, 0x00FF00, 0x1010FF, 0xFFFF00, 0xFF00FF, 0x00FFFF, 0xFFFFFF
    ]

    size = 100
    args.inputs.touch.each { |k,v|
      color = args.state.colors[v.touch_order % 7]
      r = (color & 0xFF0000) >> 16
      g = (color & 0x00FF00) >> 8
      b = (color & 0x0000FF)
      args.outputs.primitives << { x: v.x - (size / 2), y: v.y + (size / 2), w: size, h: size, r: r, g: g, b: b, a: 255 }.solid!
      args.outputs.primitives << { x: v.x, y: v.y + size, text: k.to_s, alignment_enum: 1 }.label!
    }
  end

```

### Touch Onscreen Joystick - main.rb
```ruby
  # ./samples/02_input_basics/06_touch_onscreen_joystick/app/main.rb
  class OnScreenGamepad
    attr :inputs, :directional_vector, :directional_angle, :dpad_vector

    def initialize inputs, side: :left
      @side = side
      @inputs = inputs
    end

    def tick
      if finger
        @joystick ||= {
          center: { x: inputs.mouse.x, y: inputs.mouse.y },
          a: 0
        }
        @joystick.distance = Geometry.distance(inputs.mouse, @joystick.center)
        @joystick.angle = Geometry.angle(inputs.mouse, @joystick.center)
        @joystick.vector = @joystick.angle.to_vector
        if @joystick.distance > 160
          @joystick.center.x = @joystick.center.x.lerp(finger.x + @joystick.vector.x * 160, 0.1)
          @joystick.center.y = @joystick.center.y.lerp(finger.y + @joystick.vector.y * 160, 0.1)
        end

        perc = @joystick.distance.clamp(0, 48).fdiv(48)
        @directional_angle = (@joystick.angle + 180) % 360

        @directional_vector = {
          x: @directional_angle.to_vector.x * perc ** 4,
          y: @directional_angle.to_vector.y * perc ** 4,
        }

        if perc > 0.8
          @dpad_vector = {
            x: Geometry.angle_cardinal_vec2(@directional_angle).x,
            y: Geometry.angle_cardinal_vec2(@directional_angle).y,
          }
        else
          @dpad_vector = nil
        end

        @joystick.a = @joystick.a.lerp(128, 0.01)
      elsif @joystick
        @joystick.a = @joystick.a.lerp(0, 0.25)
        @directional_vector = nil
        @dpad_vector = nil
        @joystick = nil if @joystick.a < 1
      end
    end

    def joystick_primitive
      return nil if !@joystick
      {
        **@joystick.center,
        w: 64,
        h: 64,
        path: "sprites/circle/solid.png",
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: 255,
        g: 255,
        b: 255,
        a: @joystick.a
      }
    end

    def finger
      if @side == :left
        inputs.finger_left
      else
        inputs.finger_right
      end
    end

    def direction_indicator_primitive
      return nil if !finger
      return nil if !@joystick

      joystick_center = if @joystick.distance > 48
                          { x: @joystick.center.x + 48 * -@joystick.vector.x,
                            y: @joystick.center.y + 48 * -@joystick.vector.y }
                        else
                          finger
                        end

      {
        x: joystick_center.x,
        y: joystick_center.y,
        w: 16,
        h: 16,
        path: "sprites/circle/solid.png",
        r: 255,
        g: 0,
        b: 0,
        a: @joystick.a,
        anchor_x: 0.5,
        anchor_y: 0.5
      }
    end

    def primitives
      [
        joystick_primitive,
        direction_indicator_primitive
      ]
    end
  end

  class Game
    attr_dr

    def initialize args
      @player = { x: 640 - 16, y: 360 - 16, w: 32, h: 32, path: "sprites/circle/solid.png", r: 0, g: 128, b: 128 }
      @on_screen_gamepad = OnScreenGamepad.new args.inputs
    end

    def tick
      @on_screen_gamepad.tick
      if @on_screen_gamepad.directional_vector
        @player.x += @on_screen_gamepad.directional_vector.x * 4
        @player.y += @on_screen_gamepad.directional_vector.y * 4
      end

      outputs.background_color = [30, 30, 30]
      outputs.primitives << primitives
    end

    def primitives
      [
        @on_screen_gamepad.primitives,
        @player
      ]
    end
  end

  def self.boot args
    args.state = {}
  end

  def self.tick args
    $game ||= Game.new args
    $game.args = args
    $game.tick
  end

  def self.reset args
    $game = nil
  end

  DR.reset

```

### Managing Scenes - main.rb
```ruby
  # ./samples/02_input_basics/07_managing_scenes/app/main.rb
  def tick args
    # initialize the scene to scene 1
    args.state.current_scene ||= :title_scene
    # capture the current scene to verify it didn't change through
    # the duration of tick
    current_scene = args.state.current_scene

    # tick whichever scene is current
    case current_scene
    when :title_scene
      tick_title_scene args
    when :game_scene
      tick_game_scene args
    when :game_over_scene
      tick_game_over_scene args
    end

    # make sure that the current_scene flag wasn't set mid tick
    if args.state.current_scene != current_scene
      raise "Scene was changed incorrectly. Set args.state.next_scene to change scenes."
    end

    # if next scene was set/requested, then transition the current scene to the next scene
    if args.state.next_scene
      args.state.current_scene = args.state.next_scene
      args.state.next_scene = nil
    end
  end

  def tick_title_scene args
    args.outputs.labels << { x: 640,
                             y: 360,
                             text: "Title Scene (click to go to game)",
                             alignment_enum: 1 }

    if args.inputs.mouse.click
      args.state.next_scene = :game_scene
    end
  end

  def tick_game_scene args
    args.outputs.labels << { x: 640,
                             y: 360,
                             text: "Game Scene (click to go to game over)",
                             alignment_enum: 1 }

    if args.inputs.mouse.click
      args.state.next_scene = :game_over_scene
    end
  end

  def tick_game_over_scene args
    args.outputs.labels << { x: 640,
                             y: 360,
                             text: "Game Over Scene (click to go to title)",
                             alignment_enum: 1 }

    if args.inputs.mouse.click
      args.state.next_scene = :title_scene
    end
  end

```

### Managing Scenes Advanced - main.rb
```ruby
  # ./samples/02_input_basics/07_managing_scenes_advanced/app/main.rb
  # representation of a game that has a healing mechanic
  class Game
    # game has access to args and hp
    attr :args, :hp

    # initialize game with 100 hp
    def initialize
      @hp = 100
    end

    # take damage function that reduces hp
    def take_damage
      @hp -= 10
    end

    # heal function that increases hp
    def heal
      @hp += 10
    end

    # game over if hp <= 0
    def dead?
      @hp <= 0
    end

    # resets the game from the start
    def restart
      @hp = 100
    end
  end

  # scene that represents game over
  class GameOverScene
    # property reference to game and args
    attr :game, :args

    # initialize scene with game reference
    def initialize game
      @game = game
    end

    # id for scene lookup
    def id
      :game_over_scene
    end

    # main tick function for scene
    def tick
      # click to restart game
      if args.inputs.mouse.click
        # mark the game as restarted
        @game.restart

        # set the scene to be the heal scene
        args.state.next_scene = :heal_scene
      end

      # render label with instructions
      args.outputs.labels << { x: 640,
                               y: 360,
                               text: "Game Over. Click to restart.",
                               anchor_x: 0.5,
                               anchor_y: 0.5 }
    end
  end

  # scene that represents healing
  class HealScene
    # property reference to game and args
    attr :game, :args

    # initialize scene with game reference
    def initialize game
      @game = game
    end

    # id for scene lookup
    def id
      :heal_scene
    end

    # main tick function for scene
    def tick
      # if mouse is clicked, go to the damage scene
      if args.inputs.click
        args.state.next_scene = :damage_scene
      end

      # if enter is pressed, heal
      if args.inputs.keyboard.key_down.enter
        @game.heal
      end

      # render instructions and current hp
      args.outputs.labels << { x: 640,
                               y: 360,
                               text: "I am Heal Scene. Click to go to Damage Scene. Press enter to Heal.",
                               anchor_x: 0.5,
                               anchor_y: 0.5 }

      args.outputs.labels << { x: 640,
                               y: 360,
                               text: "Current HP: #{@game.hp}",
                               anchor_x: 0.5,
                               anchor_y: 1.5 }
    end
  end

  # scene that represents damage
  class DamageScene
    # property reference to game and args
    attr :game, :args

    # initialize scene with game reference
    def initialize game
      @game = game
    end

    # id for scene lookup
    def id
      :damage_scene
    end

    # main tick function for scene
    def tick
      # if mouse is clicked, go to heal scene
      if args.inputs.click
        args.state.next_scene = :heal_scene
      end

      # if enter is pressed, take damage
      if args.inputs.keyboard.key_down.enter
        @game.take_damage
      end

      # if the player is dead, go to the game over scene
      if @game.dead?
        args.state.next_scene = :game_over_scene
      end

      # render instructions and current hp
      args.outputs.labels << { x: 640,
                               y: 360,
                               text: "I am Damage Scene. Click to go to Heal Scene. Press enter to Take Damage.",
                               anchor_x: 0.5,
                               anchor_y: 0.5 }

      args.outputs.labels << { x: 640,
                               y: 360,
                               text: "Current HP: #{@game.hp}",
                               anchor_x: 0.5,
                               anchor_y: 1.5 }
    end
  end

  # root scene holds game and all other scenes
  class RootScene
    # property reference to game and args
    attr :args, :game

    # initialize the root scene with game and all scenes
    def initialize
      @game = Game.new
      @heal_scene = HealScene.new @game
      @damage_scene = DamageScene.new @game
      @game_over_scene = GameOverScene.new @game
      @scenes = [@heal_scene, @damage_scene, @game_over_scene]
    end

    # set the starting state to the heal
    def defaults
      args.state.scene ||= :heal_scene
    end

    # top level tick function
    def tick
      # initialize defaults
      defaults

      # we want to make sure that scene transitions happen at the end
      # (you never want to swap scenes mid-tick since it makes things hard to debug)
      scene_before_tick = args.state.scene

      # get the current scene that should be ticked
      scene = get_current_scene
      # set that scene's args reference
      scene.args = args
      # invoke tick on the scene
      scene.tick

      # check to make sure that the current scene wasn't changed within the tick
      if args.state.scene != scene_before_tick
        raise "Do not change the scene mid tick, set state.next_scene"
      end

      # check to see if next scene was set, and if so do the scene transition here
      if args.state.next_scene
        args.state.scene = args.state.next_scene
        args.state.next_scene = nil
      end
    end

    # function is used to find the current scene that should be ticked
    def get_current_scene
      # each scene has a scene id, we use args.state.scene to search for the
      # correct scene to call tick on
      scene = @scenes.find { |scene| scene.id == args.state.scene }
      # raise an error if no scene was found
      raise "Scene with id #{args.state.scene} does not exist." if !scene

      # return the scene that was found
      scene
    end
  end

  # entry point
  def tick args
    # set root scene if it isn't initialized, set args, and invoke tick
    $root_scene ||= RootScene.new
    $root_scene.args = args
    $root_scene.tick
  end

  # reset method that clears out root scene
  def reset args
    $root_scene = nil
  end

  DR.reset

```
