### Mouse Click - main.rb
```ruby
  # ./samples/05_mouse/01_mouse_click/app/main.rb
  =begin

   APIs listing that haven't been encountered in previous sample apps:

   - product: Returns an array of all combinations of elements from all arrays.

     For example, [1,2].product([1,2]) would return the following array...
     [[1,1], [1,2], [2,1], [2,2]]
     More than two arrays can be given to product and it will still work,
     such as [1,2].product([1,2],[3,4]). What would product return in this case?

     Answer:
     [[1,1,3],[1,1,4],[1,2,3],[1,2,4],[2,1,3],[2,1,4],[2,2,3],[2,2,4]]

   - num1.fdiv(num2): Returns the float division (will have a decimal) of the two given numbers.
     For example, 5.fdiv(2) = 2.5 and 5.fdiv(5) = 1.0

   - yield: Allows you to call a method with a code block and yield to that block.

   Reminders:

   - Hash#inside_rect?: Returns true or false depending on if the point is inside the rect.

   - String interpolation: Uses #{} syntax; everything between the #{ and the } is evaluated
     as Ruby code, and the placeholder is replaced with its corresponding value or result.

   - args.inputs.mouse.click: This property will be set if the mouse was clicked.

   - Ternary operator (?): Will evaluate a statement (just like an if statement)
     and perform an action if the result is true or another action if it is false.

   - reject: Removes elements from a collection if they meet certain requirements.

   - args.outputs.borders: An array. The values generate a border.
     The parameters are [X, Y, WIDTH, HEIGHT, RED, GREEN, BLUE]
     For more information about borders, go to mygame/documentation/03-solids-and-borders.md.

   - args.outputs.labels: An array. The values generate a label.
     The parameters are [X, Y, TEXT, SIZE, ALIGNMENT, RED, GREEN, BLUE, ALPHA, FONT STYLE]
     For more information about labels, go to mygame/documentation/02-labels.

  =end

  # This sample app is a classic game of Tic Tac Toe.
  class TicTacToe
    attr_dr # class macro that adds outputs, inputs, state, etc to class

    def tick
      init_new_game
      render_board
      input_board
    end

    def init_new_game
      state.current_turn       ||= :x
      state.space_combinations ||= [-1, 0, 1].product([-1, 0, 1]).to_a
      if !state.spaces
        state.square_size ||= 80
        state.board_left  ||= grid.w_half - state.square_size * 1.5
        state.board_top   ||= grid.h_half - state.square_size * 1.5
        state.spaces = {}
        state.space_combinations.each do |x, y|
          state.spaces[x]    ||= {}
          state.spaces[x][y] ||= {}
          state.spaces[x][y].hitbox ||= {
            x: state.board_left + (x + 1) * state.square_size,
            y: state.board_top  + (y + 1) * state.square_size,
            w: state.square_size,
            h: state.square_size
          }
        end
      end
    end

    # Uses borders to create grid squares for the game's board. Also outputs the game pieces using labels.
    def render_board
      # At first glance, the add(1) looks pretty trivial. But if you remove it,
      # you'll see that the positioning of the board would be skewed without it!
      # Or if you put 2 in the parenthesis, the pieces will be placed in the wrong squares
      # due to the change in board placement.
      outputs.borders << all_spaces.map do |space| # outputs borders for all board spaces
                           space.hitbox
                         end

      hovered_box = all_spaces.find do |space|
        inputs.mouse.inside_rect?(space.hitbox) && !space.piece
      end

      if hovered_box && !state.game_over
        args.outputs.solids << { x: hovered_box.hitbox.x,
                                 y: hovered_box.hitbox.y,
                                 w: hovered_box.hitbox.w,
                                 h: hovered_box.hitbox.h,
                                 r: 0,
                                 g: 100,
                                 b: 200,
                                 a: 80 }
      end

      # put label in each filled space of board
      outputs.labels << filled_spaces.map do |space|
        { x: space.hitbox.x + space.hitbox.w / 2,
          y: space.hitbox.y + space.hitbox.h / 2,
          anchor_x: 0.5,
          anchor_y: 0.5,
          size_px: 40,
          text: space.piece }
      end

      # Uses a label to output whether x or o won, or if a draw occurred.
      # If the game is ongoing, a label shows whose turn it currently is.
      outputs.labels << if state.x_won
                          { x: 640, y: 600, text: "x won", size_px: 40, anchor_x: 0.5, anchor_y: 0.5 }
                        elsif state.o_won
                          { x: 640, y: 600, text: "o won", size_px: 40, anchor_x: 0.5, anchor_y: 0.5 }
                        elsif state.draw
                          { x: 640, y: 600, text: "draw", size_px: 40, anchor_x: 0.5, anchor_y: 0.5 }
                        else
                          { x: 640, y: 600, text: "turn: #{state.current_turn}", size_px: 40, anchor_x: 0.5, anchor_y: 0.5 }
                        end
    end

    # Calls the methods responsible for handling user input and determining the winner.
    # Does nothing unless the mouse is clicked.
    def input_board
      return unless inputs.mouse.click
      input_place_piece
      input_restart_game
      determine_winner
    end

    # Handles user input for placing pieces on the board.
    def input_place_piece
      return if state.game_over

      # Checks to find the space that the mouse was clicked inside of, and makes sure the space does not already
      # have a piece in it.
      space = all_spaces.find do |space|
        inputs.mouse.click.point.inside_rect?(space.hitbox) && !space.piece
      end

      # The piece that goes into the space belongs to the player whose turn it currently is.
      return unless space

      space.piece = state.current_turn

      # This ternary operator statement allows us to change the current player's turn.
      # If it is currently x's turn, it becomes o's turn. If it is not x's turn, it become's x's turn.
      state.current_turn = state.current_turn == :x ? :o : :x
    end

    # Resets the game.
    def input_restart_game
      return unless state.game_over
      gtk.reset
      init_new_game
    end

    # Checks if x or o won the game.
    # If neither player wins and all nine squares are filled, a draw happens.
    # Once a player is chosen as the winner or a draw happens, the game is over.
    def determine_winner
      state.x_won = won? :x # evaluates to either true or false (boolean values)
      state.o_won = won? :o
      state.draw = true if filled_spaces.length == 9 && !state.x_won && !state.o_won
      state.game_over = state.x_won || state.o_won || state.draw
    end

    # Determines if a player won by checking if there is a horizontal match or vertical match.
    # Horizontal_match and vertical_match have boolean values. If either is true, the game has been won.
    def won? piece
      # performs action on all space combinations
      won = [[-1, 0, 1]].product([-1, 0, 1]).map do |xs, y|
        # Checks if the 3 grid spaces with the same y value (or same row) and
        # x values that are next to each other have pieces that belong to the same player.
        # Remember, the value of piece is equal to the current turn (which is the player).
        horizontal_match = state.spaces[xs[0]][y].piece == piece &&
                           state.spaces[xs[1]][y].piece == piece &&
                           state.spaces[xs[2]][y].piece == piece

        # Checks if the 3 grid spaces with the same x value (or same column) and
        # y values that are next to each other have pieces that belong to the same player.
        # The && represents an "and" statement: if even one part of the statement is false,
        # the entire statement evaluates to false.
        vertical_match = state.spaces[y][xs[0]].piece == piece &&
                         state.spaces[y][xs[1]].piece == piece &&
                         state.spaces[y][xs[2]].piece == piece

        horizontal_match || vertical_match # if either is true, true is returned
      end

      # Sees if there is a diagonal match, starting from the bottom left and ending at the top right.
      # Is added to won regardless of whether the statement is true or false.
      won << (state.spaces[-1][-1].piece == piece && # bottom left
              state.spaces[ 0][ 0].piece == piece && # center
              state.spaces[ 1][ 1].piece == piece)   # top right

      # Sees if there is a diagonal match, starting at the bottom right and ending at the top left
      # and is added to won.
      won << (state.spaces[ 1][-1].piece == piece && # bottom right
              state.spaces[ 0][ 0].piece == piece && # center
              state.spaces[-1][ 1].piece == piece)   # top left

      # Any false statements (meaning false diagonal matches) are rejected from won
      won.reject_false.any?
    end

    # Defines filled spaces on the board by rejecting all spaces that do not have game pieces in them.
    # The ! before a statement means "not". For example, we are rejecting any space combinations that do
    # NOT have pieces in them.
    def filled_spaces
      all_spaces.reject { |space| !space.piece } # reject spaces with no pieces in them
    end

    # Defines all spaces on the board.
    def all_spaces
      state.space_combinations.map do |x, y|
        state.spaces[x][y] # yield if a block is given
      end
    end
  end

  $tic_tac_toe = nil

  def tick args
    args.outputs.labels << { x: 640,
                             y: 700,
                             anchor_x: 0.5,
                             anchor_y: 0.5,
                             text: "Sample app shows how to work with mouse clicks and hitboxes." }
    $tic_tac_toe ||= TicTacToe.new
    $tic_tac_toe.args = args
    $tic_tac_toe.tick
  end

```

### Mouse Move - main.rb
```ruby
  # ./samples/05_mouse/02_mouse_move/app/main.rb
  =begin

   Reminders:

   - find_all: Finds all elements of a collection that meet certain requirements.
     For example, in this sample app, we're using find_all to find all zombies that have intersected
     or hit the player's sprite since these zombies have been killed.

   - args.inputs.keyboard.key_down.KEY: Determines if a key is being held or pressed.
     Stores the frame the "down" event occurred.
     For more information about the keyboard, go to mygame/documentation/06-keyboard.md.

   - args.outputs.sprites: An array. The values generate a sprite.
     The parameters are [X, Y, WIDTH, HEIGHT, PATH, ANGLE, ALPHA, RED, GREEN, BLUE]
     For more information about sprites, go to mygame/documentation/05-sprites.md.

   - args.state.new_entity: Used when we want to create a new object, like a sprite or button.
     When we want to create a new object, we can declare it as a new entity and then define
     its properties. (Remember, you can use state to define ANY property and it will
     be retained across frames.)

   - String interpolation: Uses #{} syntax; everything between the #{ and the } is evaluated
     as Ruby code, and the placeholder is replaced with its corresponding value or result.

   - map: Ruby method used to transform data; used in arrays, hashes, and collections.
     Can be used to perform an action on every element of a collection, such as multiplying
     each element by 2 or declaring every element as a new entity.

   - sample: Chooses a random element from the array.

   - reject: Removes elements that meet certain requirements.
     In this sample app, we're removing/rejecting zombies that reach the center of the screen. We're also
     rejecting zombies that were killed more than 30 frames ago.

  =end

  # This sample app allows users to move around the screen in order to kill zombies. Zombies appear from every direction so the goal
  # is to kill the zombies as fast as possible!

  class ProtectThePuppiesFromTheZombies
    attr_accessor :grid, :inputs, :state, :outputs

    # Calls the methods necessary for the game to run properly.
    def tick
      defaults
      render
      calc
      input
    end

    # Sets default values for the zombies and for the player.
    # Initialization happens only in the first frame.
    def defaults
      state.flash_at               ||= 0
      state.zombie_min_spawn_rate  ||= 60
      state.zombie_spawn_countdown ||= random_spawn_countdown state.zombie_min_spawn_rate
      state.zombies                ||= []
      state.killed_zombies         ||= []

      # Declares player as a new entity and sets its properties.
      # The player begins the game in the center of the screen, not moving in any direction.
      state.player ||= { x: 640,
                         y: 360,
                         w: 4 * 3,
                         h: 8 * 3,
                         attack_angle: 0,
                         dx: 0,
                         dy: 0,
                         created_at: Kernel.tick_count }
    end

    # Outputs a gray background.
    # Calls the methods needed to output the player, zombies, etc onto the screen.
    def render
      outputs.background_color = [100, 100, 100]
      render_zombies
      render_killed_zombies
      render_player
      render_flash
    end

    # Outputs the zombies on the screen and sets values for the sprites, such as the position, width, height, and animation.
    def render_zombies
      outputs.sprites << state.zombies.map do |z| # performs action on all zombies in the collection
        z.merge path: animation_sprite(z)  # sets definition for sprite, calls animation_sprite method
      end
    end

    # Outputs sprites of killed zombies, and displays a slash image to show that a zombie has been killed.
    def render_killed_zombies
      outputs.sprites << state.killed_zombies.map do |z| # performs action on all killed zombies in collection
        zombie = { x: z.x,
                   y: z.y,
                   w: 4 * 3,
                   h: 8 * 3,
                   path: animation_sprite(z, z.death_at), # calls animation_sprite method
                   a: 255 * z.death_at.ease(30, :flip) }  # transparency of a zombie changes when they die

        # Sets values to output the slash over the zombie's sprite when a zombie is killed.
        # The slash is tilted 45 degrees from the angle of the player's attack.
        # Change the 3 inside scale_rect to 30 and the slash will be HUGE! Scale_rect positions
        # the slash over the killed zombie's sprite.
        [zombie,
         zombie.merge(path: 'sprites/slash.png',
                      angle: 45 + (state.player.attack_angle_on_click || 0)).scale_rect(3, 0.5, 0.5)]
      end
    end

    # Outputs the player sprite using the images in the sprites folder.
    def render_player
      # Outputs a small red square that previews the angles that the player can attack in.
      # It can be moved in a perfect circle around the player to show possible movements.
      # Change the 60 in the parenthesis and see what happens to the movement of the red square.
      outputs.sprites << { x: state.player.x + state.player.attack_angle.vector_x(60),
                           y: state.player.y + state.player.attack_angle.vector_y(60),
                           w: 3,
                           h: 3,
                           r: 255,
                           g: 0,
                           b: 0,
                           path: :solid }

      outputs.sprites << { x: state.player.x,
                           y: state.player.y,
                           w: 4 * 3,
                           h: 8 * 3,
                           path: "sprites/player-#{animation_index(state.player.created_at.elapsed_time)}.png" } # string interpolation
    end

    # Renders flash as a solid. The screen turns white for 10 frames when a zombie is killed.
    def render_flash
      return if state.flash_at.elapsed_time > 10 # return if more than 10 frames have passed since flash.
      # Transparency gradually changes (or eases) during the 10 frames of flash.
      outputs.primitives << { **grid.rect, r: 255, g: 255, b: 255, a: 255 * state.flash_at.ease(10, :flip), path: :solid }
    end

    # Calls all methods necessary for performing calculations.
    def calc
      calc_spawn_zombie
      calc_move_zombies
      calc_player
      calc_kill_zombie
    end

    # Decreases the zombie spawn countdown by 1 if it has a value greater than 0.
    def calc_spawn_zombie
      if state.zombie_spawn_countdown > 0
        state.zombie_spawn_countdown -= 1
        return
      end

      # New zombies are created, positioned on the screen, and added to the zombies collection.
      state.zombies << (if rand > 0.5
                         {
                           x: grid.rect.w.randomize(:ratio), # random x position on screen (within grid scope)
                           y: [-10, 730].sample, # y position is set to either -10 or 730 (randomly chosen)
                           w: 4 * 3, h: 8 * 3,
                           created_at: Kernel.tick_count
                         }
                        else
                         {
                           x: [-10, 1290].sample, # x position is set to either -10 or 1290 (randomly chosen)
                           y: grid.rect.w.randomize(:ratio), # random y position on screen
                           w: 4 * 3, h: 8 * 3,
                           created_at: Kernel.tick_count
                         }
                        end)

      # Calls random_spawn_countdown method (determines how fast new zombies appear)
      state.zombie_spawn_countdown = random_spawn_countdown state.zombie_min_spawn_rate
      state.zombie_min_spawn_rate -= 1
      # set to either the current zombie_min_spawn_rate or 0, depending on which value is greater
      state.zombie_min_spawn_rate  = state.zombie_min_spawn_rate.clamp(0)
    end

    # Moves all zombies towards the center of the screen.
    # All zombies that reach the center (640, 360) are rejected from the zombies collection and disappear.
    def calc_move_zombies
      state.zombies.each do |z| # for each zombie in the collection
        z.y = z.y.towards(360, 0.1) # move the zombie towards the center (640, 360) at a rate of 0.1
        z.x = z.x.towards(640, 0.1) # change 0.1 to 1.1 and see how much faster the zombies move to the center
      end
      state.zombies = state.zombies.reject { |z| z.y == 360 && z.x == 640 } # remove zombies that are in center
    end

    # Calculates the position and movement of the player on the screen.
    def calc_player
      state.player.x += state.player.dx # changes x based on dx (change in x)
      state.player.y += state.player.dy # changes y based on dy (change in y)

      state.player.dx *= 0.9 # scales dx down
      state.player.dy *= 0.9 # scales dy down

      # Compares player's x to 1280 to find lesser value, then compares result to 0 to find greater value.
      # This ensures that the player remains within the screen's scope.
      state.player.x = state.player.x.clamp(0, 1280)
      state.player.y = state.player.y.clamp(0, 720) # same with player's y
    end

    # Finds all zombies that intersect with the player's sprite. These zombies are removed from the zombies collection
    # and added to the killed_zombies collection since any zombie that intersects with the player is killed.
    def calc_kill_zombie

      # Find all zombies that intersect with the player. They are considered killed.
      killed_this_frame = state.zombies.find_all { |z| (z.intersect_rect? state.player) }
      state.zombies = state.zombies - killed_this_frame # remove newly killed zombies from zombies collection
      state.killed_zombies += killed_this_frame # add newly killed zombies to killed zombies

      if killed_this_frame.length > 0 # if atleast one zombie was killed in the frame
        state.flash_at = Kernel.tick_count # flash_at set to the frame when the zombie was killed
      # Don't forget, the rendered flash lasts for 10 frames after the zombie is killed (look at render_flash method)
      end

      # Sets the tick_count (passage of time) as the value of the death_at variable for each killed zombie.
      # Death_at stores the frame a zombie was killed.
      killed_this_frame.each do |z|
        z.death_at = Kernel.tick_count
      end

      # Zombies are rejected from the killed_zombies collection depending on when they were killed.
      # They are rejected if more than 30 frames have passed since their death.
      state.killed_zombies = state.killed_zombies.reject { |z| Kernel.tick_count - z.death_at > 30 }
    end

    # Uses input from the user to move the player around the screen.
    def input

      # If the "a" key or left key is pressed, the x position of the player decreases.
      # Otherwise, if the "d" key or right key is pressed, the x position of the player increases.
      if inputs.keyboard.key_held.a || inputs.keyboard.key_held.left
        state.player.x -= 5
      elsif inputs.keyboard.key_held.d || inputs.keyboard.key_held.right
        state.player.x += 5
      end

      # If the "w" or up key is pressed, the y position of the player increases.
      # Otherwise, if the "s" or down key is pressed, the y position of the player decreases.
      if inputs.keyboard.key_held.w || inputs.keyboard.key_held.up
        state.player.y += 5
      elsif inputs.keyboard.key_held.s || inputs.keyboard.key_held.down
        state.player.y -= 5
      end

      # Sets the attack angle so the player can move and attack in the precise direction it wants to go.
      # If the mouse is moved, the attack angle is changed (based on the player's position and mouse position).
      # Attack angle also contributes to the position of red square.
      if inputs.mouse.moved
        state.player.attack_angle = inputs.mouse.position.angle_from [state.player.x, state.player.y]
      end

      if inputs.mouse.click && state.player.dx < 0.5 && state.player.dy < 0.5
        state.player.attack_angle_on_click = inputs.mouse.position.angle_from [state.player.x, state.player.y]
        state.player.attack_angle = state.player.attack_angle_on_click # player's attack angle is set
        state.player.dx = state.player.attack_angle.vector_x(25) # change in player's position
        state.player.dy = state.player.attack_angle.vector_y(25)
      end
    end

    # Sets the zombie spawn's countdown to a random number.
    # How fast zombies appear (change the 60 to 6 and too many zombies will appear at once!)
    def random_spawn_countdown minimum
      10.randomize(:ratio, :sign).to_i + 60
    end

    # Helps to iterate through the images in the sprites folder by setting the animation index.
    # 3 frames is how long to show an image, and 6 is how many images to flip through.
    def animation_index at
      at.idiv(3).mod(6)
    end

    # Animates the zombies by using the animation index to go through the images in the sprites folder.
    def animation_sprite zombie, at = nil
      at ||= zombie.created_at.elapsed_time # how long it is has been since a zombie was created
      index = animation_index at
      "sprites/zombie-#{index}.png" # string interpolation to iterate through images
    end
  end

  $protect_the_puppies_from_the_zombies = ProtectThePuppiesFromTheZombies.new

  def tick args
    $protect_the_puppies_from_the_zombies.grid    = args.grid
    $protect_the_puppies_from_the_zombies.inputs  = args.inputs
    $protect_the_puppies_from_the_zombies.state    = args.state
    $protect_the_puppies_from_the_zombies.outputs = args.outputs
    $protect_the_puppies_from_the_zombies.tick
    tick_instructions args, "How to get the mouse position and translate it to an x, y position using .vector_x and .vector_y. CLICK to play."
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

### Mouse Move Paint App - main.rb
```ruby
  # ./samples/05_mouse/03_mouse_move_paint_app/app/main.rb
  # This sample app shows an empty grid that the user can paint on.
  # To paint, the user must keep their mouse presssed and drag it around the grid.
  # The "clear" button allows users to clear the grid so they can start over.
  class Game
    attr_dr

    # Runs methods necessary for the game to function properly.
    def tick
      tick_draw
      render_title
      render_grid
      render_button
    end

    # Prints the title onto the screen by using a label.
    # Also separates the title from the grid with a line as a horizontal separator.
    def render_title
      args.outputs.labels << { x: 640, y: 700, text: 'Paint!', anchor_x: 0.5, anchor_y: 0.5 }
      args.outputs.labels << { x: 640, y: 700, text: 'Click/hold left mouse button: Draw. Click/hold right mouse button: Delete.', anchor_x: 0.5, anchor_y: 1.5 }
      outputs.lines << horizontal_separator(660, 0, 1280)
    end

    # Sets the starting position, ending position, and color for the horizontal separator.
    # The starting and ending positions have the same y values.
    def horizontal_separator y, x, x2
      { x: x, y: y, x2: x2, y2: y, r: 150, g: 150, b: 150 }
    end

    # Sets the starting position, ending position, and color for the vertical separator.
    # The starting and ending positions have the same x values.
    def vertical_separator x, y, y2
      { x: x, y: y, x2: x, y2: y2, r: 150, g: 150, b: 150 }
    end

    # Outputs a border and a grid containing empty squares onto the screen.
    def render_grid
      # Sets the x, y, height, and width of the grid.
      # There are 31 horizontal lines and 31 vertical lines in the grid.
      # Feel free to count them yourself before continuing!
      x, y, h, w = 640 - 500/2, 640 - 500, 500, 500 # calculations done so the grid appears in screen's center
      lines_h = 31
      lines_v = 31

      # Sets values for the grid's border, grid lines, and filled squares.
      # The filled_squares variable is initially set to an empty array.
      state.grid_border ||= { x: x, y: y, w: w, h: h } # definition of grid's outer border
      state.grid_lines ||= draw_grid(x, y, w, h, lines_h, lines_v) # calls draw_grid method
      state.filled_squares ||= [] # there are no filled squares until the user fills them in

      # Outputs the grid lines, border, and filled squares onto the screen.
      outputs.lines << state.grid_lines
      outputs.borders << state.grid_border
      outputs.sprites << state.filled_squares
    end

    # Draws the grid by adding in vertical and horizontal separators.
    def draw_grid x, y, h, w, lines_h, lines_v
      # The grid starts off empty.
      grid = []

      # Calculates the placement and adds horizontal lines or separators into the grid.
      curr_y = y # start at the bottom of the box
      dist_y = h / (lines_h + 1) # finds distance to place horizontal lines evenly throughout 500 height of grid
      lines_h.times do
        curr_y += dist_y # increment curr_y by the distance between the horizontal lines
        grid << horizontal_separator(curr_y, x, x + w - 1) # add a separator into the grid
      end

      # Calculates the placement and adds vertical lines or separators into the grid.
      curr_x = x # now start at the left of the box
      dist_x = w / (lines_v + 1) # finds distance to place vertical lines evenly throughout 500 width of grid
      lines_v.times do
        curr_x += dist_x # increment curr_x by the distance between the vertical lines
        grid << vertical_separator(curr_x, y + 1, y  + h) # add separator
      end

      # paint_grid uses a hash to assign values to keys.
      state.paint_grid ||= {
        x: x,
        y: y,
        h: h,
        w: w,
        lines_h: lines_h,
        lines_v: lines_v,
        dist_x: dist_x,
        dist_y: dist_y
      }

      return grid
    end

    # Draw squares on left click/held, delete squares on right click/held
    def tick_draw
      return if !Geometry.inside_rect?(inputs.mouse, state.grid_border)

      point = {
        x: inputs.mouse.x,
        y: inputs.mouse.y,
      }

      point.x -= state.paint_grid.x # subtracts the value assigned to the "x" key in the paint_grid hash
      point.y -= state.paint_grid.y # subtracts the value assigned to the "y" key in the paint_grid hash

      # Remove code following the .floor and see what happens when you try to fill in grid squares
      point.x = (point.x / state.paint_grid.dist_x).floor * state.paint_grid.dist_x
      point.y = (point.y / state.paint_grid.dist_y).floor * state.paint_grid.dist_y

      point.x += state.paint_grid.x
      point.y += state.paint_grid.y

      # Sets definition of a grid box, meaning its x, y, width, and height.
      # Floor is called on the point.x and point.y variables.
      # Ceil method is called on values of the distance hash keys, setting the width and height of a box.
      grid_box = {
        x: point.x.floor,
        y: point.y.floor,
        w: state.paint_grid.dist_x.ceil,
        h: state.paint_grid.dist_y.ceil,
        r: 0, g: 0, b: 0,
        path: :solid
      }

      if inputs.mouse.left
        if !state.filled_squares.include?(grid_box) # if grid box is already filled in
          state.filled_squares << grid_box # otherwise, box is filled in and added to filled_squares
        end
      elsif inputs.mouse.right
        if state.filled_squares.include?(grid_box) # if grid box is already filled in
          state.filled_squares.delete grid_box # otherwise, box is filled in and added to filled_squares
        end
      end
    end

    # Creates and outputs a "Clear" button on the screen using a label and a border.
    # If the button is clicked, the filled squares are cleared, making the filled_squares collection empty.
    def render_button
      x, y, w, h = 390, 50, 240, 50
      state.clear_button ||= {
        label: {
          x: x + w / 2,
          y: y + h / 2,
          text: "Clear",
          anchor_x: 0.5,
          anchor_y: 0.5
        },
        border: { x: x, y: y, w: w, h: h, primitive_marker: :border }
      }

      # If the mouse is clicked inside the borders of the clear button,
      # the filled_squares collection is emptied and the squares are cleared.
      if inputs.mouse.click && Geometry.inside_rect?(inputs.mouse, state.clear_button.border)
        state.clear_button.clicked_at = Kernel.tick_count
        state.filled_squares.clear
      end

      outputs.primitives << state.clear_button.label
      outputs.primitives << state.clear_button.border

      # When the clear button is clicked, the color of the button changes
      # and the transparency changes, as well. If you change the time from
      # 0.25.seconds to 1.25.seconds or more, the change will last longer.
      if state.clear_button.clicked_at
        perc = Easing.smooth_stop(start_at: state.clear_button.clicked_at,
                                  duration: 0.25.seconds,
                                  tick_count: Kernel.tick_count,
                                  flip: true)
        outputs.sprites << {
          x: x,
          y: y,
          w: w,
          h: h,
          path: :solid,
          r: 0,
          g: 180,
          b: 80,
          a: 255 * perc
        }
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

  DR.reset

```

### Coordinate Systems - main.rb
```ruby
  # ./samples/05_mouse/04_coordinate_systems/app/main.rb
  =begin

   APIs listing that haven't been encountered in previous sample apps:

   - args.inputs.mouse.click.position: Coordinates of the mouse's position on the screen.
     Unlike args.inputs.mouse.click.point, the mouse does not need to be pressed down for
     position to know the mouse's coordinates.
     For more information about the mouse, go to mygame/documentation/07-mouse.md.

   Reminders:

   - args.inputs.mouse.click: This property will be set if the mouse was clicked.

   - args.inputs.mouse.click.point.(x|y): The x and y location of the mouse.

   - String interpolation: Uses #{} syntax; everything between the #{ and the } is evaluated
     as Ruby code, and the placeholder is replaced with its corresponding value or result.

     In this sample app, string interpolation is used to show the current position of the mouse
     in a label.

   - args.outputs.labels: An array that generates a label.
     The parameters are [X, Y, TEXT, SIZE, ALIGN, RED, GREEN, BLUE, ALPHA, FONT STYLE]
     For more information about labels, go to mygame/documentation/02-labels.md.

   - args.outputs.solids: An array that generates a solid.
     The parameters are [X, Y, WIDTH, HEIGHT, RED, GREEN, BLUE, ALPHA]
     For more information about solids, go to mygame/documentation/03-solids-and-borders.md.

   - args.outputs.lines: An array that generates a line.
     The parameters are [X, Y, X2, Y2, RED, GREEN, BLUE, ALPHA]
     For more information about lines, go to mygame/documentation/04-lines.md.

  =end

  # This sample app shows a coordinate system or grid. The user can move their mouse around the screen and the
  # coordinates of their position on the screen will be displayed. Users can choose to view one quadrant or
  # four quadrants by pressing the button.

  def tick args

    # The addition and subtraction in the first two parameters of the label and solid
    # ensure that the outputs don't overlap each other. Try removing them and see what happens.
    pos = args.inputs.mouse.position # stores coordinates of mouse's position
    args.outputs.labels << [pos.x + 10, pos.y + 10, "#{pos}"] # outputs label of coordinates
    args.outputs.solids << [pos.x -  2, pos.y - 2, 5, 5] # outputs small blackk box placed where mouse is hovering

    button = [0, 0, 370, 50] # sets definition of toggle button
    args.outputs.borders << button # outputs button as border (not filled in)
    args.outputs.labels << [10, 35, "click here toggle coordinate system"] # label of button
    args.outputs.lines << [    0, -720,    0, 720] # vertical line dividing quadrants
    args.outputs.lines << [-1280,    0, 1280,   0] # horizontal line dividing quadrants

    if args.inputs.mouse.click # if the user clicks the mouse
      pos = args.inputs.mouse.click.point # pos's value is point where user clicked (coordinates)
      if pos.inside_rect? button # if the click occurred inside the button
        if args.grid.name == :bottom_left # if the grid shows bottom left as origin
          args.grid.origin_center! # origin will be shown in center
        else
          args.grid.origin_bottom_left! # otherwise, the view will change to show bottom left as origin
        end
      end
    end

    tick_instructions args, "Sample app shows the two supported coordinate systems in Game Toolkit."
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

### Clicking Buttons - main.rb
```ruby
  # ./samples/05_mouse/05_clicking_buttons/app/main.rb
  def tick args
    # create buttons
    args.state.buttons ||= [
      create_button(args, id: :button_1, row: 0, col: 0, text: "button 1"),
      create_button(args, id: :button_2, row: 1, col: 0, text: "button 2"),
      create_button(args, id: :clear,    row: 2, col: 0, text: "clear")
    ]

    # render button's border and label
    args.outputs.primitives << args.state.buttons.map do |b|
      b.primitives
    end

    # render center label if the text is set
    if args.state.center_label_text
      args.outputs.labels << { x: 640,
                               y: 360,
                               text: args.state.center_label_text,
                               alignment_enum: 1,
                               vertical_alignment_enum: 1 }
    end

    # if the mouse is clicked, see if the mouse click intersected
    # with a button
    if args.inputs.mouse.click
      button = args.state.buttons.find do |b|
        args.inputs.mouse.intersect_rect? b
      end

      # update the center label text based on button clicked
      case button.id
      when :button_1
        args.state.center_label_text = "button 1 was clicked"
      when :button_2
        args.state.center_label_text = "button 2 was clicked"
      when :clear
        args.state.center_label_text = nil
      end
    end
  end

  def create_button args, id:, row:, col:, text:;
    # Layout.rect(row:, col:, w:, h:) is method that will
    # return a rectangle inside of a grid with 12 rows and 24 columns
    rect = Layout.rect row: row, col: col, w: 3, h: 1

    # get senter of rect for label
    center = Geometry.rect_center_point rect

    {
      id: id,
      x: rect.x,
      y: rect.y,
      w: rect.w,
      h: rect.h,
      primitives: [
        {
          x: rect.x,
          y: rect.y,
          w: rect.w,
          h: rect.h,
          primitive_marker: :border
        },
        {
          x: center.x,
          y: center.y,
          text: text,
          size_enum: -1,
          alignment_enum: 1,
          vertical_alignment_enum: 1,
          primitive_marker: :label
        }
      ]
    }
  end

  DR.reset

```
