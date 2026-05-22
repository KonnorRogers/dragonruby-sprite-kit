### Fifteen Puzzle - main.rb
```ruby
  # ./samples/99_genre_board_game/01_fifteen_puzzle/app/main.rb
  class Game
    attr_dr

    def initialize
      # rng is sent to Random so that everyone gets the same levels
      @rng = Random.new 100

      @solved_board = (1..16).to_a

      # rendering size of the cell
      @cell_size = 128

      # compute left and right margins based on cell size
      @left_margin = (Grid.w - 4 * @cell_size) / 2
      @bottom_margin = (Grid.h - 4 * @cell_size) / 2

      # how long notifications should be displayed
      @notification_duration = 110

      # frame that the player won
      @completed_at = nil

      # number of times the player won
      @win_count = 0

      # spline that represents fade in and fade out of notifications
      @notification_spline = [
        [  0, 0.25, 0.75, 1.0],
        [1.0, 1.0,  1.0,  1.0],
        [1.0, 0.75, 0.25,   0]
      ]

      # current moves the player has taken on level
      @current_move_count = 0

      # move history so that undos decreases the move count
      @move_history = []

      # create a new shuffed board
      new_suffled_board!
    end

    def tick
      calc
      render
    end

    def new_suffled_board!
      # set the board to a new board
      @board = new_board

      # while the board is in a solved state
      while solved_board?
        # difficulty increases with the number of wins
        # find the empty cell (the cell with the value 16) and swap it with a random neighbor
        # do this X times (win_count + 1 * 5) to make sure the board is scrambled
        @shuffle_count = ((@win_count + 1) * 2).clamp(7, 100).to_i

        # neighbor to exclude to better shuffle the board
        exclude_neighor = nil
        @shuffle_count.times do
          # get candidate neighbors based off of neighbors of the empty cell
          # exclude the neighbor that is the mirror of the last selected neighbor
          shuffle_candidates = empty_cell_neighbors.reject do |neighbor|
            neighbor.relative_location == exclude_neighor&.mirror_location ||
            neighbor.mirror_location == exclude_neighor&.relative_location
          end

          # select a random neighbor based off of the candidate size and RNG
          selected_neighbor = shuffle_candidates[@rng.rand(shuffle_candidates.length)]

          # if the number of candidates is greater than 2, then update the exclude neighbor
          exclude_neighor = if shuffle_candidates.length >= 2
                              selected_neighbor
                            else
                              nil
                            end

          # shuffle the board by swapping the empty cell with the selected candidate
          swap_with_empty selected_neighbor.cell, empty_cell
        end
      end

      # after shuffling, reset the current move count
      @max_move_count = (@shuffle_count * 1.1).to_i

      # capture the current board state so that the player can try again (game over)
      @try_again_board = @board.copy
      @started_at = Kernel.tick_count

      # reset the completed_at time
      @completed_at = nil

      # clear the move history
      @move_history.clear
    end

    def new_board
      # create a board with cells of the
      # following format:
      # {
      #   value: 1,
      #   loc: { row: 0, col: 0 },
      #   previous_loc: { row: 0, col: 0 },
      #   clicked_at: 0
      # }
      16.map_with_index do |i|
        { value: i + 1 }
      end.sort_by do |cell|
        cell.value
      end.map_with_index do |cell, index|
        row = 3 - index.idiv(4)
        col = index % 4
        cell.merge loc: { row: row, col: col },
                   previous_loc: { row: row, col: col },
                   clicked_at: -100
      end
    end

    def render
      # render the current level and current move count (and max move count)
      outputs.labels << { x: 640, y: 720 - 64, anchor_x: 0.5, anchor_y: 0.5, text: "Level: #{@win_count + 1}", size_px: 64 }
      outputs.labels << { x: 640, y: 64, anchor_x: 0.5, anchor_y: 0.5, text: "Moves: #{@current_move_count} (#{@max_move_count})", size_px: 64 }

      # render each cell
      outputs.sprites << @board.map do |cell|
        # render the board centered in the middle of the screen
        prefab = cell_prefab cell
        prefab.merge x: @left_margin + prefab.x, y: @bottom_margin + prefab.y
      end

      # if the game has just started, display the notification of how many moves the player has to complete the level
      if @started_at && @started_at.elapsed_time < @notification_duration
        alpha_percentage = Easing.spline @started_at,
                                         Kernel.tick_count,
                                         @notification_duration,
                                         @notification_spline

        outputs.primitives << notification_prefab( "Complete in #{@max_move_count} or less.", alpha_percentage)
      end

      # if the game is completed, display the notification based on whether the player won or lost
      if @completed_at && @completed_at.elapsed_time < @notification_duration
        alpha_percentage = Easing.spline @completed_at,
                                         Kernel.tick_count,
                                         @notification_duration,
                                         @notification_spline

        message = if @current_move_count <= @max_move_count
                    "You won!"
                  else
                    "Try again!"
                  end

        outputs.primitives << notification_prefab(message, alpha_percentage)
      end
    end

    # notification prefab that displays a message in the center of the screen
    def notification_prefab text, alpha_percentage
      [
        {
          x: 0,
          y: grid.h.half - @cell_size / 2,
          w: grid.w,
          h: @cell_size,
          path: :pixel,
          r: 0,
          g: 0,
          b: 0,
          a: 255 * alpha_percentage,
        },
        {
          x: grid.w.half,
          y: grid.h.half,
          text: text,
          a: 255 * alpha_percentage,
          anchor_x: 0.5,
          anchor_y: 0.5,
          size_px: 80,
          r: 255,
          g: 255,
          b: 255
        }
      ]
    end

    def calc
      # set the completed_at time if the board is solved
      @completed_at ||= Kernel.tick_count if solved_board?

      # if the game is completed, then reset the board to either a new shuffled board or the try again board
      if @completed_at && @completed_at.elapsed_time > @notification_duration
        @completed_at = nil

        # if the player has not exceeded the max move count, then reset the board to a new shuffled board
        if @current_move_count <= @max_move_count
          new_suffled_board!
          @win_count ||= 0
          @win_count += 1
          @current_move_count = 0
        else
          # otherwise reset the board to the try again board
          @board = @try_again_board.copy
          @current_move_count = 0
        end
      end

      # don't process any input if the game is completed
      return if @completed_at

      # select the cell based on mouse, keyboard, or controller input
      selected_cell = if inputs.mouse.click
                        @board.find do |cell|
                          mouse_rect = {
                            x: inputs.mouse.x - @left_margin,
                            y: inputs.mouse.y - @bottom_margin,
                            w: 1,
                            h: 1,
                          }
                          mouse_rect.intersect_rect? render_rect(cell.loc)
                        end
                      elsif inputs.key_down.left || inputs.controller_one.key_down.x
                        empty_cell_neighbors.find { |n| n.relative_location == :left }&.cell
                      elsif inputs.key_down.right || inputs.controller_one.key_down.b
                        empty_cell_neighbors.find { |n| n.relative_location == :right }&.cell
                      elsif inputs.key_down.up || inputs.controller_one.key_down.y
                        empty_cell_neighbors.find { |n| n.relative_location == :above }&.cell
                      elsif inputs.key_down.down || inputs.controller_one.key_down.a
                        empty_cell_neighbors.find { |n| n.relative_location == :below }&.cell
                      end

      # if no cell is selected, then return
      return if !selected_cell

      # find the clicked cell's neighbors
      clicked_cell_neighbors = neighbors selected_cell

      # return if the cell's neighbors doesn't include the empty cell
      return if !clicked_cell_neighbors.map { |c| c.cell }.include?(empty_cell)

      # set when the cell was clicked so that animation can be performed
      selected_cell.clicked_at = Kernel.tick_count

      # capture the before and after swap locations so that undo can be performed
      before_swap = empty_cell.loc.copy
      swap_with_empty selected_cell, empty_cell
      after_swap = empty_cell.loc.copy
      @move_history.push_front({ before: before_swap, after: after_swap })

      frt_history = @move_history[0]
      snd_history = @move_history[1]

      # check if the last move was a reverse of the previous move, if so then decrease the move count
      if frt_history && snd_history && frt_history.after == snd_history.before && frt_history.before == snd_history.after
        @move_history.pop_front
        @move_history.pop_front
        @current_move_count -= 1
      else
        # otherwise increase the move count
        @current_move_count += 1
      end
    end

    def solved_board?
      # sort the board by the cell's location and map the values (which will be 1 to 16)
      sorted_values = @board.sort_by { |cell| (cell.loc.col + 1) + (16 - (cell.loc.row * 4)) }
                            .map { |cell| cell.value }

      # check if the sorted values are equal to the expected values (1 to 16)
      sorted_values == @solved_board
    end

    def swap_with_empty cell, empty
      # take not of the cell's current location (within previous_loc)
      cell.previous_loc = cell.loc

      # swap the cell's location with the empty cell's location and vice versa
      cell.loc, empty.loc = empty.loc, cell.loc
    end

    def cell_prefab cell
      # determine the percentage for the lerp that should be performed
      percentage = if cell.clicked_at
                     Easing.smooth_stop start_at: cell.clicked_at, duration: 15, tick_count: Kernel.tick_count, power: 5, flip: true
                   else
                     1
                   end

      # determine the cell's current render location
      cell_rect = render_rect cell.loc

      # determine the cell's previous render location
      previous_rect = render_rect cell.previous_loc

      # compute the difference between the current and previous render locations
      x = cell_rect.x + (previous_rect.x - cell_rect.x) * percentage
      y = cell_rect.y + (previous_rect.y - cell_rect.y) * percentage

      # return the cell prefab
      { x: x,
        y: y,
        w: @cell_size,
        h: @cell_size,
        path: "sprites/pieces/#{cell.value}.png" }
    end

    # helper method to determine the render location of a cell in local space
    # which excludes the margins
    def render_rect loc
      {
        x: loc.col * @cell_size,
        y: loc.row * @cell_size,
        w: @cell_size,
        h: @cell_size,
      }
    end

    # helper methods to determine neighbors of a cell
    def neighbors cell
      [
        { mirror_location: :below, relative_location: :above, cell: above_cell(cell) },
        { mirror_location: :above, relative_location: :below, cell: below_cell(cell) },
        { mirror_location: :right, relative_location:  :left, cell: left_cell(cell)  },
        { mirror_location: :left,  relative_location: :right, cell: right_cell(cell) },
      ].reject { |neighbor| !neighbor.cell }
    end

    def empty_cell
      @board.find { |cell| cell.value == 16 }
    end

    def empty_cell_neighbors
      neighbors empty_cell
    end

    def below_cell cell
      find_cell cell, -1, 0
    end

    def above_cell cell
      find_cell cell, 1, 0
    end

    def left_cell cell
      find_cell cell, 0, -1
    end

    def right_cell cell
      find_cell cell, 0, 1
    end

    def find_cell cell, d_row, d_col
      @board.find do |other_cell|
        cell.loc.row == other_cell.loc.row + d_row &&
        cell.loc.col == other_cell.loc.col + d_col
      end
    end
  end

  def boot args
    args.state ||= {}
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
    args.state = {}
  end

  # DR.reset

```

### Sudoku - main.rb
```ruby
  # ./samples/99_genre_board_game/02_sudoku/app/main.rb
  class Sudoku
    def initialize
      @square_lookup = {}
      @candidates_cache = {}
      9.each do |row|
        @square_lookup[row] ||= {}
        9.each do |col|
          @square_lookup[row][col] = { row: row, col: col, value: nil }
        end
      end
      @move_history = []
      @one_to_nine = (1..9).to_a
    end

    def undo!
      return if @move_history.empty?
      last_move = @move_history.pop_back
      set_value(row: last_move.row, col: last_move.col, value: last_move.value, record_history: false)
    end

    def empty_squares
      @square_lookup.keys
                    .flat_map { |k| @square_lookup[k].values }
                    .sort_by  { |s| [s.row, s.col] }
                    .find_all { |s| !s.value }
                    .map      { |s| { row: s.row, col: s.col } }
    end

    def get_value(row:, col:)
      @square_lookup[row][col].value
    end

    def set_value(row:, col:, value:, record_history: true)
      @move_history << { row: row, col: col, value: @square_lookup[row][col].value } if record_history
      @square_lookup[row][col].value = value
      @candidates_cache = {}
    end

    def __candidates_uncached__(row:, col:)
      used_values = relations(row: row, col: col).map { |s| s[:value] }
                                                 .compact
                                                 .uniq
      @one_to_nine - used_values
    end

    def candidates(row:, col:)
      return @candidates_cache[row][col] if @candidates_cache.dig(row, col)
      @candidates_cache[row] ||= {}
      @candidates_cache[row][col] ||= __candidates_uncached__(row: row, col: col)
      candidates(row: row, col: col)
    end

    def square_lookup
      @square_lookup.keys
                    .flat_map { |k| @square_lookup[k].values }
                    .sort_by  { |s| [s.row, s.col] }
    end

    def single_candidates
      singles = []
      squares.map { |s| Hash[row: s.row,
                             col: s.col,
                             candidates: candidates(row: s.row, col: s.col)] }
             .find_all { |s| s.candidates.length == 1 }
             .map { |s| { row: s.row, col: s.col, value: s.candidates.first } }
    end

    def relations(row:, col:)
      related = []

      9.each do |c|
        related << { **@square_lookup[row][c] } if c != col
      end

      9.each do |r|
        related << { **@square_lookup[r][col] } if r != row
      end

      box_start_row = (row.idiv 3) * 3
      box_start_col = (col.idiv 3) * 3
      3.each do |r_offset|
        3.each do |c_offset|
          r = box_start_row + r_offset
          c = box_start_col + c_offset
          related << { **@square_lookup[r][c] } if r != row && c != col
        end
      end

      related.uniq
    end
  end

  class Game
    attr_dr

    attr :sudoku

    PARTITION_BG_COLOR = { r: 96, g: 156, b: 156 }
    PARTITION_OUTER_BG_COLOR = { r: 232, g: 232, b: 232 }
    BACKGROUND_COLOR = [30, 30, 30]
    SELECTED_RECT_COLOR = { r: 255, a: 128 }
    HOVERED_RECT_COLOR = { r: 255, g: 255, b: 255, a: 128 }
    CANDIDATE_COLOR = { r: 0, g: 0, b: 0 }
    NON_CANDIDATE_COLOR = { r: 200, g: 200, b: 200 }
    EMPTY_SQUARE_COLOR = { r: 128, g: 32, b: 32 }
    FILLED_SQUARE_COLOR = { r: 32, g: 64, b: 32 }
    SINGLE_CANDIDATE_DOT_COLOR = { r: 96, g: 255, b: 255 }
    MULTIPLE_CANDIDATE_DOT_COLOR = { r: 96, g: 128, b: 128 }
    LABEL_COLOR = { r: 255, g: 255, b: 255 }

    def initialize
      @sudoku = Sudoku.new
      @board = {}
      board_rects.each do |rect|
        @board[rect.row] ||= {}
        @board[rect.row][rect.col] = rect
      end

      @partition_bgs = 3.flat_map do |row|
        3.map do |col|
          Layout.rect(row: row * 3 + 1.5, col: col * 3 + 7.5, w: 3, h: 3)
                .merge(path: :solid, **PARTITION_BG_COLOR)
        end
      end

      @partition_outer_bgs = 3.flat_map do |row|
        3.map do |col|
          Layout.rect(row: row * 3 + 1.5, col: col * 3 + 7.5, w: 3, h: 3, include_row_gutter: true, include_col_gutter: true)
                .merge(path: :solid, **PARTITION_OUTER_BG_COLOR)
        end
      end

      @number_selection_rects = {
        rects: 10.map do |col|
          n = if col == 9
                nil
              else
                col + 1
              end
          Layout.rect(row: 0, col: 7 + col, w: 1, h: 1)
                .merge(number: n)
        end
      }
    end

    def tick
      @hovered_rect = find_square(inputs.mouse.x, inputs.mouse.y)

      input_click_square
      input_click_number

      outputs.background_color = BACKGROUND_COLOR
      outputs.primitives << board_prefab

      outputs.primitives << number_selection_prefab
      outputs.primitives << @selected_rect&.merge(path: :solid, **SELECTED_RECT_COLOR)
      outputs.primitives << @hovered_rect&.merge(path: :solid, **HOVERED_RECT_COLOR)
    end

    def input_click_square
      return if !@hovered_rect
      return if !inputs.mouse.click

      @selected_rect = @hovered_rect
      @select_number_shown_at = Kernel.tick_count
      @select_number_shown = true
    end

    def input_click_number
      return if !@select_number_shown

      if inputs.mouse.click || inputs.keyboard.key_down.char
        selected_number = if inputs.keyboard.key_down.char
                            n = inputs.keyboard.key_down.char.to_i
                            if n == 0
                              { number: nil}
                            else
                              { number: n }
                            end
                          else
                            @number_selection_rects.rects.find do |r|
                              Geometry.inside_rect?({ x: inputs.mouse.x, y: inputs.mouse.y, w: 1, h: 1 }, r)
                            end
                          end

        if selected_number
          @sudoku.set_value(row: @selected_rect.row, col: @selected_rect.col, value: selected_number.number)
          @selected_rect = nil
          @select_number_shown = false
          @select_number_shown_at = nil
        end
      end
    end

    def number_selection_prefab
      return nil if !@select_number_shown

      candidates = @sudoku.candidates(row: @selected_rect.row, col: @selected_rect.col)

      outputs.primitives << @number_selection_rects.rects.map do |r|
        color = if candidates.include?(r.number)
                  CANDIDATE_COLOR
                else
                  NON_CANDIDATE_COLOR
                end
        [
          r.merge(path: :solid),
          r.center.merge(text: r.number, anchor_x: 0.5, anchor_y: 0.5, **color)
        ]
      end
    end

    def board_rects
      9.flat_map do |row|
        9.map do |col|
          Layout.rect(row: row + 1.5, col: col + 7.5, w: 1, h: 1)
                .merge(row: row, col: col)
        end
      end
    end

    def square_mark_prefabs rect
      one_third_w = rect.w.fdiv 3
      one_third_h = rect.h.fdiv 3
      {
        1 => { x: rect.x + one_third_w * 0.5, y: rect.y + one_third_h * 2.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        2 => { x: rect.x + one_third_w * 1.5, y: rect.y + one_third_h * 2.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        3 => { x: rect.x + one_third_w * 2.5, y: rect.y + one_third_h * 2.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        4 => { x: rect.x + one_third_w * 0.5, y: rect.y + one_third_h * 1.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        5 => { x: rect.x + one_third_w * 1.5, y: rect.y + one_third_h * 1.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        6 => { x: rect.x + one_third_w * 2.5, y: rect.y + one_third_h * 1.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        7 => { x: rect.x + one_third_w * 0.5, y: rect.y + one_third_h * 0.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        8 => { x: rect.x + one_third_w * 1.5, y: rect.y + one_third_h * 0.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 },
        9 => { x: rect.x + one_third_w * 2.5, y: rect.y + one_third_h * 0.5, w: 4, h: 4, anchor_x: 0.5, anchor_y: 0.5 }
      }
    end

    def find_square(mouse_x, mouse_y)
      mouse_rect = { x: mouse_x, y: mouse_y, w: 1, h: 1 }
      @board.each do |row, cols|
        cols.each do |col, rect|
          if Geometry.inside_rect?(mouse_rect, rect)
            return rect.merge(row: row, col: col)
          end
        end
      end

      nil
    end

    def square_prefabs
      @board.keys.flat_map do |row|
        @board[row].keys.map do |col|
          square_prefab(row: row, col: col)
        end
      end
    end

    def board_prefab
      @partition_outer_bgs + @partition_bgs + square_prefabs
    end

    def square_prefab(row:, col:)
      rect = @board[row][col]
      value = @sudoku.get_value(row: row, col: col)
      candidates = @sudoku.candidates(row: row, col: col)

      bg_color = if !value && candidates.empty?
                   EMPTY_SQUARE_COLOR
                 else
                   FILLED_SQUARE_COLOR
                 end

      label = if value
                {
                  x: rect.center.x,
                  y: rect.center.y,
                  text: value,
                  anchor_x: 0.5,
                  anchor_y: 0.5,
                  **LABEL_COLOR
                }
              else
                nil
              end

      dot_color = if candidates.length == 1
                    SINGLE_CANDIDATE_DOT_COLOR
                  else
                    MULTIPLE_CANDIDATE_DOT_COLOR
                  end

      dots = if value
               []
             else
               square_mark_prefabs(rect).find_all { |n, r| candidates.include?(n) }
                                        .map { |n, r| r.merge(path: :solid, **dot_color) }
             end

      [
        rect.merge(path: :solid, **bg_color),
        label,
        dots
      ]
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

### Sudoku - Tests - sudoku_tests.rb
```ruby
  # ./samples/99_genre_board_game/02_sudoku/tests/sudoku_tests.rb
  class SudokuTests
    def test_single_candidates(args, assert)
      s = Sudoku.new
      s.set_value(row: 0, col: 0, value: 1)
      s.set_value(row: 0, col: 1, value: 2)
      s.set_value(row: 0, col: 2, value: 3)
      s.set_value(row: 1, col: 0, value: 4)
      s.set_value(row: 1, col: 1, value: 5)
      s.set_value(row: 1, col: 2, value: 6)
      s.set_value(row: 2, col: 0, value: 7)
      s.set_value(row: 2, col: 1, value: 8)
      assert.equal! s.single_candidates.first, { row: 2, col: 2, value: 9 }
      assert.equal! s.single_candidates.length, 1
    end
  end

```

### Word Game - main.rb
```ruby
  # ./samples/99_genre_board_game/03_word_game/app/main.rb
  class Game
    attr_dr

    GREEN = { r: 98, g: 140, b: 84 }
    YELLOW = { r: 177, g: 159, b: 54 }
    GRAY = { r: 64, g: 64, b: 64 }

    def initialize
      # get the list of words that can be inputed
      @valid_words = DR.read_file("data/valid.txt")
                        .each_line
                        .map { |l| l.strip }
                        .reject { |l| l.length == 0 }

      # get the list of words that will be picked from
      @play_words = DR.read_file("data/play.txt")
                        .each_line
                        .map { |l| l.strip }
                        .reject { |l| l.length == 0 }

      @player_progress = (DR.read_file("user-data/progress.txt") || "")
                           .each_line
                           .map { |l| l.strip }
                           .reject { |l| l.length == 0 }
                           .map do |l|
                             word, result = l.split ","
                             { word: word, result: result.to_sym }
                           end

      # animation spline for when a letter is typed
      @enter_char_spline_duration = 15
      @enter_char_spline = [
        [0.0, 0.0,  0.66, 1.0],
        [1.0, 1.0,  1.0,  1.0],
        [1.0, 0.33, 0.0,  0.0]
      ]

      # animation spline for when a letter is flipped
      @flip_spline_duration = 15
      @flip_spline = [
        [1.0, 0.66, 0.33, 0.0],
        [0.0, 0.33, 0.66, 1.0],
      ]

      # animation spline for an invalid word
      @invalid_spline_duration = 15
      @invalid_spline = [
        [0.0, -0.5, 0.0, 0.5],
        [0.0, -0.5, 0.0, 0.5],
      ]

      # start a new game
      new_game!
    end

    def save_progress!
      content = @player_progress.map do |h|
        "#{h.word},#{h.result}"
      end.join "\n"

      DR.write_file "user-data/progress.txt", content
    end

    def new_game!
      # from the list of playable words, choose a word
      @target_word = @play_words.reject do |w|
        @player_progress.any? { |h| h.word == w }
      end.sample

      # this is a look up table for coloring the keys
      @key_colors = { }

      # the current row the player is on
      @current_guess_index = 0

      # the current char the player is on
      @current_guess_char_index = 0

      # point at which the game has ended
      @game_over_at = nil

      # flag for when the game has endend
      @game_over = false

      # flag denoting whether the player won or lost when the game has ended
      @winner = false

      @new_game_at = Kernel.tick_count

      # data structure for where the guesses will be stored,
      # { rect:, action:, action_at:, char: }

      # Layout api is used to create the board
      @guesses = [
        [
          { rect: Layout.rect(row: 4, col: 1, w: 2, h: 2) },
          { rect: Layout.rect(row: 4, col: 3, w: 2, h: 2) },
          { rect: Layout.rect(row: 4, col: 5, w: 2, h: 2) },
          { rect: Layout.rect(row: 4, col: 7, w: 2, h: 2) },
          { rect: Layout.rect(row: 4, col: 9, w: 2, h: 2) },
        ],
        [
          { rect: Layout.rect(row: 6, col: 1, w: 2, h: 2) },
          { rect: Layout.rect(row: 6, col: 3, w: 2, h: 2) },
          { rect: Layout.rect(row: 6, col: 5, w: 2, h: 2) },
          { rect: Layout.rect(row: 6, col: 7, w: 2, h: 2) },
          { rect: Layout.rect(row: 6, col: 9, w: 2, h: 2) },
        ],
        [
          { rect: Layout.rect(row: 8, col: 1, w: 2, h: 2) },
          { rect: Layout.rect(row: 8, col: 3, w: 2, h: 2) },
          { rect: Layout.rect(row: 8, col: 5, w: 2, h: 2) },
          { rect: Layout.rect(row: 8, col: 7, w: 2, h: 2) },
          { rect: Layout.rect(row: 8, col: 9, w: 2, h: 2) },
        ],
        [
          { rect: Layout.rect(row: 10, col: 1, w: 2, h: 2) },
          { rect: Layout.rect(row: 10, col: 3, w: 2, h: 2) },
          { rect: Layout.rect(row: 10, col: 5, w: 2, h: 2) },
          { rect: Layout.rect(row: 10, col: 7, w: 2, h: 2) },
          { rect: Layout.rect(row: 10, col: 9, w: 2, h: 2) },
        ],
        [
          { rect: Layout.rect(row: 12, col: 1, w: 2, h: 2) },
          { rect: Layout.rect(row: 12, col: 3, w: 2, h: 2) },
          { rect: Layout.rect(row: 12, col: 5, w: 2, h: 2) },
          { rect: Layout.rect(row: 12, col: 7, w: 2, h: 2) },
          { rect: Layout.rect(row: 12, col: 9, w: 2, h: 2) },
        ],
        [
          { rect: Layout.rect(row: 14, col: 1, w: 2, h: 2) },
          { rect: Layout.rect(row: 14, col: 3, w: 2, h: 2) },
          { rect: Layout.rect(row: 14, col: 5, w: 2, h: 2) },
          { rect: Layout.rect(row: 14, col: 7, w: 2, h: 2) },
          { rect: Layout.rect(row: 14, col: 9, w: 2, h: 2) },
        ],
      ]

      # generate the keyboard layout and wire up the button callbacks
      @keyboard =  [
        *keyboard_buttons(17.25 + 1.5 * 0, 0, ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]),
        *keyboard_buttons(17.25 + 1.5 * 1, 0.6, ["A", "S", "D", "F", "G", "H", "J", "K", "L"]),
        *keyboard_buttons(17.25 + 1.5 * 2, 0, ["ENT", "Z", "X", "C", "V", "B", "N", "M", "BKSP"],
                          {
                            "ENT" => lambda { guess_word! },
                            "BKSP" => lambda { unset_char! }
                          })
      ]
    end

    def guess_word!
      # when the player presses enter, or clicks the "ENT" button

      # get the full word for the current row
      full_word = @guesses[@current_guess_index].map { |guess| guess.char }.join

      # the word is valid if its length is 5 and it's in the valid word dictionary
      is_valid = full_word.length == 5 && @valid_words.include?(full_word)

      # if it's valid, then enumerate each one of the guess entries and queue up
      # their animations
      if is_valid
        @guesses[@current_guess_index].each_with_index do |guess, i|
          if @target_word[i] == guess.char
            # if the index of the word matches exactly, then flip to green
            guess.action = :flip_green
            guess.action_at = Kernel.tick_count + i * @flip_spline_duration

            # update the keyboard color lookup and queue it to be rendered
            # after all animations have completed
            if !@key_colors[guess.char] || @key_colors[guess.char].color_id == :yellow || @key_colors[guess.char].color_id == :gray
              @key_colors[guess.char] ||= { **GREEN, at: Kernel.tick_count + 5 * @flip_spline_duration, color_id: :green }
            end
          elsif @target_word.include? guess.char
            # if the target word contains the character, then flip to yellow
            guess.action = :flip_yellow
            guess.action_at = Kernel.tick_count + i * @flip_spline_duration

            # update the keyboard color lookup and queue it to be rendered
            # after all animations have completed
            if !@key_colors[guess.char] || @key_colors[guess.char].color_id == :gray
              @key_colors[guess.char] ||= { **YELLOW, at: Kernel.tick_count + 5 * @flip_spline_duration, color_id: :yellow }
            end
          else
            # otherwise flip to gray
            guess.action = :flip_gray
            guess.action_at = Kernel.tick_count + i * @flip_spline_duration

            # update the keyboard color lookup and queue it to be rendered
            # after all animations have completed
            if !@key_colors[guess.char]
              @key_colors[guess.char] ||= { **GRAY, at: Kernel.tick_count + 5 * @flip_spline_duration, color_id: :gray }
            end
          end
        end

        if full_word == @target_word
          # the player has won if their guess matches the target word
          @game_over = true
          @game_over_at = Kernel.tick_count + 5 * @flip_spline_duration
          @winner = true

          @player_progress << { word: @target_word, result: :win }
        elsif @current_guess_index == 5
          # the player has lost if they've run out of rows
          @game_over = true
          @game_over_at = Kernel.tick_count + 5 * @flip_spline_duration
          @winner = false

          @player_progress << { word: @target_word, result: :loss }
        else
          # increment to the next row after the guess
          @current_guess_index += 1
          @current_guess_char_index = 0
        end
      else
        # if the word they selected isn't in the valid word dictionary,
        # then queue the invalid animation
        @guesses[@current_guess_index].each_with_index do |guess, i|
          guess.action = :invalid
          guess.action_at = Kernel.tick_count
        end
      end
    end

    def generate_letter_prefabs!
      # on frame zero, generate textures/glpyhs for all the letters
      return if Kernel.tick_count != 0

      r = Layout.rect(row: 0, col: 0, w: 2, h: 2)
      ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P",
       "A", "S", "D", "F", "G", "H", "J", "K", "L",
       "Z", "X", "C", "V", "B", "N", "M"].each do |c|
         outputs[c.downcase].w = r.w
         outputs[c.downcase].h = r.h
         outputs[c.downcase].background_color = [0, 0, 0, 0]
         outputs[c.downcase].primitives << { x: r.w / 2, y: r.h / 2, text: c, anchor_x: 0.5, anchor_y: 0.5, size_px: r.h / 2, r: 255, g: 255, b: 255 }
       end
    end

    def calc
      return if @game_over_at && @game_over_at.elapsed_time < 30
      return if @new_game_at && @new_game_at.elapsed_time < 30

      if @game_over
        # if they clicked or pressed enter, then start a new game
        if inputs.mouse.click || inputs.keyboard.key_up.char == "\r" || inputs.keyboard.key_down == "\r"
          save_progress!
          new_game!
        end
      else
        if inputs.mouse.click
          # if they are using the mouse and they click, find the key that the mouse intersects with
          keyboard_key = Geometry.find_intersect_rect(inputs.mouse, @keyboard, using: :rect)

          # if the key is found, then call the on_click callback on the key
          if keyboard_key
            keyboard_key.on_click.call
          end
        elsif inputs.keyboard.key_up.char

          # if they used the keyboard and it's backspace or enter,
          # then delete or guess word
          if inputs.keyboard.key_up.char == "\b"
            unset_char!
          elsif inputs.keyboard.key_up.char == "\r"
            guess_word!
          else
            # if it's any other key, then check to see if the keyboard buttons has
            # the key that was pressed
            key = @keyboard.find do |k|
              k.char == inputs.keyboard.key_up.char.upcase
            end

            # if so, then invoke the on_click callback (as if they clicked it with the mouse)
            key.on_click.call if key
          end
        end
      end
    end

    def tick
      generate_letter_prefabs!
      calc
      render
      # outputs.primitives << Layout.debug_primitives(invert_colors: true)
    end

    def unset_char!
      # unsetting a char/deleting a char logic
      if @current_guess_char_index == 4 && @guesses[@current_guess_index][@current_guess_char_index].char
        # if it's the last spot and there is a char to be deleted, then clear out the char
        @guesses[@current_guess_index][@current_guess_char_index].char = nil
      elsif @current_guess_char_index == 0 && @guesses[@current_guess_index][@current_guess_char_index].char
        # if it's the first spot and there is a char to be deleted, then clear out the char
        @guesses[@current_guess_index][@current_guess_char_index].char = nil
      elsif @current_guess_char_index != 0
        # otherwise move back a spot, and clear out the char in that spot
        @current_guess_char_index -= 1
        @guesses[@current_guess_index][@current_guess_char_index].char = nil
      end
    end

    def set_char! c
      # set the current spot's char and increment to the next spot if they aren't already on the las
      # spot
      if !@guesses[@current_guess_index][@current_guess_char_index].char
        @guesses[@current_guess_index][@current_guess_char_index].char = c
        @guesses[@current_guess_index][@current_guess_char_index].action_at = Kernel.tick_count
        @guesses[@current_guess_index][@current_guess_char_index].action = :set_char
        @current_guess_char_index += 1 if @current_guess_char_index != 4
      end
    end

    def keyboard_buttons(start_row, start_col, chars, callback_overrides = {})
      # button construction
      # layout api is used to create the rectangle, and the call back is set to
      # set_char!(char) by default unless there is a callback override (eg for ENT and BKSP)
      running_col = 0
      chars.map_with_index do |c, i|
        w = if c.length > 1
              1.8
            else
              1.2
            end
        r = if c.length > 1
              Layout.rect(row: start_row, col: start_col + running_col, w: w, h: 1.5)
            else
              Layout.rect(row: start_row, col: start_col + running_col, w: w, h: 1.5)
            end
        running_col += w
        on_click = callback_overrides[c] || ->() { set_char! c }
        { rect: r, char: c, on_click: on_click }
      end
    end

    def guess_char_prefab guess_char
      # this is the prefab for rendering a tile

      # get the location of the spot and a char (if one is there)
      r = guess_char.rect
      c = guess_char.char

      # the default color for the tile is a grayish border
      # with a dark background, and the character texture (if the spot has a character set)
      border_color = if c
                       { r: 90, g: 90, b: 90 }
                     else
                       { r: 45, g: 45, b: 45 }
                     end

      outer_tile = r.center.merge(path: :solid, **border_color, w: r.w, h: r.h, anchor_x: 0.5, anchor_y: 0.5)
      inner_tile = r.center.merge(path: :solid, r: 18, g: 18, b: 18, w: r.w - 4, h: r.h - 4, anchor_x: 0.5, anchor_y: 0.5)
      label_prefab = r.center.merge(path: c.downcase, w: r.w, h: r.h, anchor_x: 0.5, anchor_y: 0.5) if c

      # sorting for rendering so that animations aren't behind other tiles (default is 0)
      sort_order = 0

      if guess_char.action_at && guess_char.action == :set_char
        # if an action as been queued, and the action is :set_char

        # use the enter_char_spline animation to compute the percentage
        perc = if guess_char.action_at && guess_char.action_at.elapsed_time < @enter_char_spline_duration
                 Easing.spline(guess_char.action_at, Kernel.tick_count, @enter_char_spline_duration, @enter_char_spline)
               else
                 0
               end

        # the percentage is used to scale the rect up, and back down
        label_prefab = r.center.merge(path: c.downcase, w: r.w + 32 * perc, h: r.h + 32 * perc, anchor_x: 0.5, anchor_y: 0.5) if c
        outer_tile = r.center.merge(path: :solid, **border_color, w: r.w + 32 * perc, h: r.h + 32 * perc, anchor_x: 0.5, anchor_y: 0.5)
        inner_tile = r.center.merge(path: :solid, r: 18, g: 18, b: 18, w: r.w - 4 + 32 * perc, h: r.h - 4 + 32 * perc, anchor_x: 0.5, anchor_y: 0.5)

        # set the sort order to 1 so that it renders at the top
        sort_order = 1
      elsif guess_char.action_at && guess_char.action == :flip_green
        # if the animation is flip to green, then use the flip animation spline to compute the percentage
        perc = if guess_char.action_at && guess_char.action_at.elapsed_time < @flip_spline_duration && guess_char.action_at.elapsed_time > 0
                 Easing.spline(guess_char.action_at, Kernel.tick_count, @flip_spline_duration, @flip_spline)
               else
                 1
               end

        # default colors before the flip/reveal occurs
        outer_tile_color = { r: 90, g: 90, b: 90 }
        inner_tile_color = { r: 18, g: 18, b: 18 }

        # half way through the animation, flip to green
        if guess_char.action_at.elapsed_time > @flip_spline_duration.idiv(2)
          outer_tile_color = GREEN
          inner_tile_color = GREEN
        end

        # the perc value is used to control the height of the prefab
        label_prefab = r.center.merge(path: c.downcase, w: r.w, h: r.h * perc, anchor_x: 0.5, anchor_y: 0.5) if c
        outer_tile = r.center.merge(path: :solid, w: r.w, h: r.h * perc, anchor_x: 0.5, anchor_y: 0.5, **outer_tile_color)
        inner_tile = r.center.merge(path: :solid, w: r.w - 4, h: (r.h - 4) * perc, anchor_x: 0.5, anchor_y: 0.5, **inner_tile_color)
        sort_order = 1
      elsif guess_char.action_at && guess_char.action == :flip_yellow
        # same as flip_green, but yellow color
        perc = if guess_char.action_at && guess_char.action_at.elapsed_time < @flip_spline_duration && guess_char.action_at.elapsed_time > 0
                 Easing.spline(guess_char.action_at, Kernel.tick_count, @flip_spline_duration, @flip_spline)
               else
                 1
               end

        outer_tile_color = { r: 90, g: 90, b: 90 }
        inner_tile_color = { r: 18, g: 18, b: 18 }

        if guess_char.action_at.elapsed_time > @flip_spline_duration.idiv(2)
          outer_tile_color = YELLOW
          inner_tile_color = YELLOW
        end

        label_prefab = r.center.merge(path: c.downcase, w: r.w, h: r.h * perc, anchor_x: 0.5, anchor_y: 0.5) if c
        outer_tile = r.center.merge(path: :solid, w: r.w, h: r.h * perc, anchor_x: 0.5, anchor_y: 0.5, **outer_tile_color)
        inner_tile = r.center.merge(path: :solid, w: r.w - 4, h: (r.h - 4) * perc, anchor_x: 0.5, anchor_y: 0.5, **inner_tile_color)
        sort_order = 1
      elsif guess_char.action_at && guess_char.action == :flip_gray
        # same logic as flip_green, but gray color
        perc = if guess_char.action_at && guess_char.action_at.elapsed_time < @flip_spline_duration && guess_char.action_at.elapsed_time > 0
                 Easing.spline(guess_char.action_at, Kernel.tick_count, @flip_spline_duration, @flip_spline)
               else
                 1
               end

        outer_tile_color = { r: 90, g: 90, b: 90 }
        inner_tile_color = { r: 18, g: 18, b: 18 }

        if guess_char.action_at.elapsed_time > @flip_spline_duration.idiv(2)
          outer_tile_color = GRAY
          inner_tile_color = GRAY
        end

        label_prefab = r.center.merge(path: c.downcase, w: r.w, h: r.h * perc, anchor_x: 0.5, anchor_y: 0.5) if c
        outer_tile = r.center.merge(path: :solid, w: r.w, h: r.h * perc, anchor_x: 0.5, anchor_y: 0.5, **outer_tile_color)
        inner_tile = r.center.merge(path: :solid, w: r.w - 4, h: (r.h - 4) * perc, anchor_x: 0.5, anchor_y: 0.5, **inner_tile_color)
        sort_order = 1
      elsif guess_char.action_at && guess_char.action == :invalid
        # if the animation that's queued is an invalid word,
        # compute the prec using the @invalid_spline
        perc = if guess_char.action_at && guess_char.action_at.elapsed_time < @invalid_spline_duration && guess_char.action_at.elapsed_time > 0
                 Easing.spline(guess_char.action_at, Kernel.tick_count, @invalid_spline_duration, @invalid_spline)
               else
                 0
               end

        # the perc value is used to shift the x value (shake animation)
        label_prefab = { x: r.center.x + 64 * perc, y: r.center.y, w: r.w, h: r.h, anchor_x: 0.5, anchor_y: 0.5, path: c.downcase } if c
        outer_tile = { x: r.center.x + 64 * perc, y: r.center.y, path: :solid, **border_color, w: r.w, h: r.h, anchor_x: 0.5, anchor_y: 0.5 }
        inner_tile = { x: r.center.x + 64 * perc, y: r.center.y, path: :solid, r: 18, g: 18, b: 18, w: r.w - 4, h: r.h - 4, anchor_x: 0.5, anchor_y: 0.5 }
        sort_order = 1
      end

      # return a structure that contains the sort order for rendering, and the prefab/primitives to render
      {
        sort_order: sort_order,
        prefab: [
          outer_tile,
          inner_tile,
          label_prefab
        ]
      }
    end

    def render
      # set the back ground color
      outputs.background_color = [18, 18, 18]

      # enumerate all the guesses, flat map the prefabs
      # then sort each prefab by the sort order
      # and shovel the prefab data into output.primitives
      outputs.primitives << @guesses.flat_map do |guess|
        guess.map do |guess_char|
          guess_char_prefab(guess_char)
        end
      end.sort_by { |pf_container| pf_container.sort_order }
         .map { |pf| pf.prefab }

      # render the keyboard
      outputs.primitives << @keyboard.map do |keyboard_key|
        c = keyboard_key.char
        r = keyboard_key.rect
        # the color of the key is set to a defualt gray, unless there is a color override
        # in the key_colors lookup (along with a time stamp of when to show the color -> we don't want to change the
        # color during the reveal of a guess)
        color = if @key_colors[keyboard_key.char] && @key_colors[keyboard_key.char].at < Kernel.tick_count
                  @key_colors[keyboard_key.char]
                else
                  { r: 131, g: 131, b: 131 }
                end

        # return the prefab for the key which is a combination of the color, plus a label representing the key
        [
          r.merge(path: :solid, **color),
          r.center.merge(text: c, anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255, size_px: 40)
        ]
      end
    end
  end

  # boot up of game
  def boot args
    args.state = {}
  end

  # top level tick function
  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  # reset logic used when hotloading
  def reset args
    $game = nil
  end

  DR.reset

```
