### A Star - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/08_a_star/app/main.rb
  # https://www.redblobgames.com/pathfinding/a-star/introduction.html
  # Contributors
  # - Sujay Vadlakonda: https://github.com/sujayvadlakonda
  class PriorityQueue
    attr :ary

    def initialize &has_priority_block
      @ary = []
      @has_priority_block = has_priority_block
    end

    def heapify n, i
      top_priority = i
      l = 2 * i + 1
      r = 2 * i + 2

      top_priority = l if l < n && @has_priority_block.call(@ary[l], @ary[top_priority])
      top_priority = r if r < n && @has_priority_block.call(@ary[r], @ary[top_priority])

      return if top_priority == i

      @ary[i], @ary[top_priority] = @ary[top_priority], @ary[i]
      heapify n, top_priority
    end

    def insert n
      @ary.push_back n
      current = @ary.length - 1
      while current > 0
        parent = (current - 1) >> 1
        if @has_priority_block.call(@ary[current], @ary[parent])
          @ary[current], @ary[parent] = @ary[parent], @ary[current]
          current = parent
        else
          break
        end
      end
    end

    def extract
      l = @ary.length
      @ary[0], @ary[l - 1] = @ary[l - 1], @ary[0]
      result = @ary.pop_back
      heapify @ary.length, 0 if 0 < @ary.length
      result
    end

    def empty? = @ary.empty?
  end

  class AStar
    attr :frontier, :came_from, :path, :cost, :status,
         :start_location, :end_location, :walls

    def initialize(start_location:, end_location:, walls:, grid_size:)
      @grid_size = grid_size
      @start_location = start_location.slice(:ordinal_x, :ordinal_y)
      @end_location = end_location.slice(:ordinal_x, :ordinal_y)
      @walls = walls.map do |w|
        [w.slice(:ordinal_x, :ordinal_y), true ]
      end.to_h

      @directions = [
        { ordinal_x:  1, ordinal_y:  0 },
        { ordinal_x: -1, ordinal_y:  0 },
        { ordinal_x:  0, ordinal_y:  1 },
        { ordinal_x:  0, ordinal_y: -1 }
      ]

      @came_from = {}
      @path = []
      @cost = {}
      @status = :ready
      @frontier = PriorityQueue.new do |a, b|
        a_result = [@cost[a] + greedy_heuristic(a), proximity_to_start_location(a)]
        b_result = [@cost[b] + greedy_heuristic(b), proximity_to_start_location(b)]
        (a_result <=> b_result) == -1
      end
    end

    def start!
      @status = :solving
      @came_from[@start_location] = nil
      @cost[@start_location] = 0
      @frontier.insert @start_location
    end

    def tick
      tick_solve
      tick_generate_path
    end

    def tick_solve
      return if @status != :solving

      current_frontier = @frontier.extract
      new_locations = adjacent_locations(current_frontier)

      new_locations.find_all do |loc|
        !@came_from[loc] && !@walls[loc]
      end.each do |loc|
        @came_from[loc] = current_frontier
        @cost[loc] = (@cost[current_frontier] || 0) + 1
        @frontier.insert loc
      end

      if @frontier.empty? || @came_from[@end_location]
        if @came_from[@end_location]
          @status = :calculating_path
          @current_path_location = @end_location
        else
          @status = :complete
        end
      end
    end

    def greedy_heuristic(loc)
      (@end_location.ordinal_x - loc.ordinal_x).abs +
      (@end_location.ordinal_y - loc.ordinal_y).abs
    end

    def proximity_to_start_location(loc)
      distance_x = (@start_location.ordinal_x - loc.ordinal_x).abs
      distance_y = (@start_location.ordinal_y - loc.ordinal_y).abs

      if distance_x > distance_y
        return distance_x
      else
        return distance_y
      end
    end

    def tick_generate_path
      return if @status != :calculating_path
      @path << @current_path_location
      @current_path_location = @came_from[@current_path_location]
      if @current_path_location == @start_location
        @path << @current_path_location
        @status = :complete
      elsif !@current_path_location
        @status = :complete
      end
    end

    def adjacent_locations(location)
      @directions.map do |dir|
        {
          ordinal_x: location.ordinal_x + dir.ordinal_x,
          ordinal_y: location.ordinal_y + dir.ordinal_y
        }
      end.find_all do |loc|
        loc.ordinal_x.between?(0, @grid_size - 1) &&
        loc.ordinal_y.between?(0, @grid_size - 1)
      end
    end

    def path_found?
      !@path.empty?
    end
  end

  class Game
    attr_dr

    def initialize
      @grid_size = 16
      @tile_size = 720 / @grid_size

      @walls = []
      @available_spots = @grid_size.flat_map do |ordinal_x|
        @grid_size.map do |ordinal_y|
          new_wall(ordinal_x: ordinal_x, ordinal_y: ordinal_y)
        end
      end

      @mode = :place_walls

      @buttons = [
        Layout.rect(row: 10, col: 14, w: 2, h: 2)
              .merge(mode: :place_walls, text: "place walls", m: :place_wall_clicked),
        Layout.rect(row: 10, col: 16, w: 2, h: 2)
              .merge(mode: :place_start_location, text: "set start location", m: :place_start_location_clicked),
        Layout.rect(row: 10, col: 18, w: 2, h: 2)
              .merge(mode: :place_end_location, text: "set end location", m: :place_end_location_clicked),
        Layout.rect(row: 10, col: 20, w: 2, h: 2)
              .merge(mode: :solving, text: "solve!", m: :solve_clicked),
        Layout.rect(row: 10, col: 22, w: 2, h: 2)
              .merge(mode: :reset, text: "reset!", m: :reset_clicked),
      ]
    end

    def new_wall(ordinal_x:, ordinal_y:)
      Geometry.rect_props(x: ordinal_x * @tile_size, y: ordinal_y * @tile_size, w: @tile_size, h: @tile_size)
              .merge(ordinal_x: ordinal_x, ordinal_y: ordinal_y)
    end

    def editing_disabled?
      return true if @mode == :solving
      return true if @mode == :complete
      return false
    end

    def place_wall_clicked
      return if editing_disabled?
      @mode = :place_walls
    end

    def place_start_location_clicked
      return if editing_disabled?
      @mode = :place_start_location
    end

    def place_end_location_clicked
      return if editing_disabled?
      @mode = :place_end_location
    end

    def solve_clicked
      return if editing_disabled?

      if !@start_location
        DR.notify "Please set a start location"
        return
      elsif !@end_location
        DR.notify "Please set an end location"
        return
      end

      @mode = :solving
      @astar ||= AStar.new(start_location: @start_location,
                            end_location: @end_location,
                            walls: @walls,
                            grid_size: @grid_size)

      @astar.start!
    end

    def reset_clicked
      return if @mode == :reset

      if @astar
        @astar = nil
      else
        @walls = []
        @start_location = nil
        @end_location = nil
      end

      @mode = :reset

      DR.on_tick_count Kernel.tick_count + 15 do
        @mode = :place_walls
      end
    end

    def tick_solve
      return if @mode != :solving

      if inputs.keyboard.key_repeat.j
        @astar.tick
      end

      if @astar.status == :complete
        @mode = :complete
      end
    end

    def tick
      tick_buttons
      tick_place_walls
      tick_place_start_location
      tick_place_end_location
      tick_solve
      render
    end

    def tick_buttons
      return if !inputs.mouse.key_down.left

      button = @buttons.find do |b|
        Geometry.inside_rect?(inputs.mouse.rect, b)
      end

      send button.m if button
    end

    def wall_under_mouse
      @walls.find do |wall|
        Geometry.inside_rect?(inputs.mouse.rect, wall)
      end
    end

    def spot_under_mouse
      @available_spots.find do |spot|
        Geometry.inside_rect?(inputs.mouse.rect, spot)
      end
    end

    def tick_place_start_location
      return if @mode != :place_start_location
      return if !inputs.mouse.key_down.left

      clicked_wall = wall_under_mouse
      clicked_spot = spot_under_mouse

      if clicked_wall
        @walls.delete(clicked_wall)
      elsif @end_location && Geometry.inside_rect?(inputs.mouse.rect, @end_location)
        @end_location = nil
      elsif clicked_spot
        @start_location = { **clicked_spot }
      end
    end

    def tick_place_end_location
      return if @mode != :place_end_location
      return if !inputs.mouse.key_down.left

      clicked_wall = wall_under_mouse
      clicked_spot = spot_under_mouse

      if clicked_wall
        @walls.delete(clicked_wall)
      elsif @start_location && Geometry.inside_rect?(inputs.mouse.rect, @start_location)
        @start_location = nil
      elsif clicked_spot
        @end_location = { **clicked_spot }
      end
    end

    def tick_place_walls
      return if @mode != :place_walls
      return if !inputs.mouse.key_down.left

      clicked_wall = wall_under_mouse
      clicked_spot = spot_under_mouse

      if clicked_wall
        @walls.delete(clicked_wall)
      elsif @start_location && Geometry.inside_rect?(inputs.mouse.rect, @start_location)
        @start_location = nil
      elsif @end_location && Geometry.inside_rect?(inputs.mouse.rect, @end_location)
        @end_location = nil
      elsif clicked_spot
        @walls << { **clicked_spot }
      end
    end

    def mode_label
      text = case @mode
             when :place_walls
               "place walls"
             when :place_start_location
               "set start location"
             when :place_end_location
               "set end location"
             when :solving
               "solving mode (hold the J key)"
             when :complete
               "complete! path found? #{@astar.path_found?}"
             when :reset
               "resetting..."
             else
               "unknown mode #{@mode}"
             end

      Layout.rect(row: [0, 1], col: [14, 23])
            .center
            .merge(text: text, anchor_x: 0.5, anchor_y: 0.5, size_px: 32, r: 255, g: 255, b: 255)
    end

    def button_prefab button
      selection_rect = if button.mode == @mode
                         {
                           **button.center,
                           w: button.w - 8,
                           h: button.h - 8,
                           anchor_x: 0.5,
                           anchor_y: 0.5,
                           path: :solid,
                           r: 0,
                           b: 0,
                           g: 200,
                           a: 128
                         }
                       else
                         nil
                       end

      lines = String.wrapped_lines button.text, 9

      labels = String.line_anchors(lines.length)
                     .map_with_index do |anchor_y, line_index|
                       {
                         **button.center,
                         text: lines[line_index],
                         anchor_x: 0.5,
                         anchor_y: anchor_y
                       }
                     end

      [
        {
          **button,
          path: :solid,
          r: 255,
          g: 255,
          b: 255,
          a: 255,
          primitive_marker: :sprite
        },
        selection_rect,
        labels
      ]
    end

    def cell_prefab(cell:, r:, g:, b:, a: 255, text: nil)
      {
        **cell.center,
        w: cell.w - 4,
        h: cell.h - 4,
        path: :solid,
        r: r,
        g: g,
        b: b,
        a: a,
        anchor_x: 0.5,
        anchor_y: 0.5,
      }
    end

    def render_map
      outputs.primitives << @available_spots.map do |spot|
        cell_prefab(cell: spot, r: 128, g: 128, b: 128, a: 128)
      end

      outputs.primitives << @walls.map do |wall|
        cell_prefab(cell: wall, r: 200, g: 96, b: 96, a: 255,)
      end

    end

    def render_ui
      outputs.primitives << mode_label

      outputs.primitives << @buttons.map do |button|
        button_prefab(button)
      end
    end

    def render_astar
      return if !@astar

      outputs.primitives << @astar.cost.map do |loc, cost|
        rect = Geometry.rect(x: loc.ordinal_x * @tile_size,
                             y: loc.ordinal_y * @tile_size,
                             w: @tile_size,
                             h: @tile_size)
        [
          { **rect.center, w: rect.w - 4, h: rect.h - 4,
            anchor_x: 0.5, anchor_y: 0.5,
            r: 232, g: 232, b: 232, path: :solid },
          { **rect.center, text: "#{cost.to_s}",
            anchor_x: 0.5, anchor_y: 0.5, size_px: 14 },
        ]
      end

      outputs.primitives << @astar.path.map do |loc|
        rect = Geometry.rect(x: loc.ordinal_x * @tile_size,
                             y: loc.ordinal_y * @tile_size,
                             w: @tile_size,
                             h: @tile_size)
        { **rect, r: 200, g: 200, b: 0, a: 128, path: :solid }
      end
    end

    def render
      outputs.background_color = [30, 30, 30]
      render_map
      render_ui
      render_astar
      render_start_and_end_locations
    end

    def render_start_and_end_locations
      if @start_location
        outputs.primitives << cell_prefab(cell: @start_location,
                                          r: 96, g: 96, b: 200, a: 255)
      end

      if @end_location
        outputs.primitives << cell_prefab(cell: @end_location,
                                          r: 96, g: 200, b: 96, a: 255)
      end
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

  # DR.reset

  DR.reset_and_replay "replay.txt", speed: 5

```

### A Star Advanced - astar.rb
```ruby
  # ./samples/13_path_finding_algorithms/08_a_star_advanced/app/astar.rb
  # https://www.redblobgames.com/pathfinding/a-star/introduction.html
  class PriorityQueue
    attr :ary

    def initialize &has_priority_block
      @ary = []
      @has_priority_block = has_priority_block
    end

    def heapify n, i
      top_priority = i
      l = 2 * i + 1
      r = 2 * i + 2

      top_priority = l if l < n && @has_priority_block.call(@ary[l], @ary[top_priority])
      top_priority = r if r < n && @has_priority_block.call(@ary[r], @ary[top_priority])

      return if top_priority == i

      @ary[i], @ary[top_priority] = @ary[top_priority], @ary[i]
      heapify n, top_priority
    end

    def insert n
      @ary.push_back n
      current = @ary.length - 1
      while current > 0
        parent = (current - 1) >> 1
        if @has_priority_block.call(@ary[current], @ary[parent])
          @ary[current], @ary[parent] = @ary[parent], @ary[current]
          current = parent
        else
          break
        end
      end
    end

    def extract
      l = @ary.length
      @ary[0], @ary[l - 1] = @ary[l - 1], @ary[0]
      result = @ary.pop_back
      heapify @ary.length, 0 if 0 < @ary.length
      result
    end

    def empty? = @ary.empty?
  end

  class AStar
    attr :frontier, :came_from, :path, :cost, :status,
         :start_location, :end_location, :walls, :estimated_iterations_to_solve

    def initialize(start_location:, end_location:, walls:, grid_w:, grid_h:)
      @grid_w = grid_w
      @grid_h = grid_h
      @estimated_iterations_to_solve = __estimated_iterations_to_solve__ @grid_w, @grid_h
      @start_location = start_location.slice(:ordinal_x, :ordinal_y)
      @end_location = end_location.slice(:ordinal_x, :ordinal_y)
      @walls = walls.map do |w|
        [w.slice(:ordinal_x, :ordinal_y), true ]
      end.to_h

      @directions = [
        { ordinal_x:  1, ordinal_y:  0 },
        { ordinal_x: -1, ordinal_y:  0 },
        { ordinal_x:  0, ordinal_y:  1 },
        { ordinal_x:  0, ordinal_y: -1 },
      ]

      @came_from = {}
      @path = []
      @cost = {}
      @status = :ready
      @frontier = PriorityQueue.new do |a, b|
        a_result = [@cost[a] + greedy_heuristic(a), proximity_to_start_location(a)]
        b_result = [@cost[b] + greedy_heuristic(b), proximity_to_start_location(b)]
        (a_result <=> b_result) == -1
      end
    end

    def start!
      @status = :solving
      @came_from[@start_location] = nil
      @cost[@start_location] = 0
      @frontier.insert @start_location
      if @start_location == @end_location
        @status = :complete
      end
    end

    def solve!
      start!
      tick while !complete?
    end

    def tick
      tick_solve
      tick_generate_path
    end

    def __estimated_iterations_to_solve__ w, h
      total_nodes = w * h
      avg_explored = total_nodes * 0.45  # ~45% of nodes explored on average
      neighbors    = 4                    # 4-directional movement
      (avg_explored * neighbors).round
    end

    def tick_solve
      return if @status != :solving

      current_frontier = @frontier.extract
      new_locations = adjacent_locations(current_frontier)

      new_locations.find_all do |loc|
        !@came_from[loc] && !@walls[loc]
      end.each do |loc|
        @came_from[loc] = current_frontier
        @cost[loc] = (@cost[current_frontier] || 0) + 1
        @frontier.insert loc
      end

      if @frontier.empty? || @came_from[@end_location]
        if @came_from[@end_location]
          @status = :calculating_path
          @current_path_location = @end_location
        else
          @status = :complete
        end
      end
    end

    def greedy_heuristic(loc)
      (@end_location.ordinal_x - loc.ordinal_x).abs +
      (@end_location.ordinal_y - loc.ordinal_y).abs
    end

    def proximity_to_start_location(loc)
      distance_x = (@start_location.ordinal_x - loc.ordinal_x).abs
      distance_y = (@start_location.ordinal_y - loc.ordinal_y).abs

      if distance_x > distance_y
        return distance_x
      else
        return distance_y
      end
    end

    def tick_generate_path
      return if @status != :calculating_path
      @path << @current_path_location
      @current_path_location = @came_from[@current_path_location]
      if @current_path_location == @start_location
        @path << @current_path_location
        @path.reverse!
        @status = :complete
      elsif !@current_path_location
        @status = :complete
      end
    end

    def adjacent_locations(location)
      @directions.map do |dir|
        {
          ordinal_x: location.ordinal_x + dir.ordinal_x,
          ordinal_y: location.ordinal_y + dir.ordinal_y
        }
      end.find_all do |loc|
        loc.ordinal_x.between?(0, @grid_w - 1) &&
        loc.ordinal_y.between?(0, @grid_h - 1)
      end
    end

    def complete?
      @status == :complete
    end

    def path_found?
      !@path.empty?
    end
  end

```

### A Star Advanced - enemy.rb
```ruby
  # ./samples/13_path_finding_algorithms/08_a_star_advanced/app/enemy.rb
  class Enemy
    attr :game, :x, :y, :w, :h, :ordinal_x, :ordinal_y, :action, :action_at

    def initialize(game:, x:, y:, w:, h:, ordinal_x:, ordinal_y:)
      @home_x = @x
      @home_y = @y
      @ordinal_x = ordinal_x
      @ordinal_y = ordinal_y
      @home_ordinal_x = @ordinal_x
      @home_ordinal_y = @ordinal_y
      @game = game
      @x = x
      @y = y
      @w = w
      @h = h
      @action = :idle
      @action_at = Kernel.tick_count
    end

    def tick
      case @action
      when :move_to_player
        tick_action_move_to_player
      when :finding_player
        tick_action_finding_player
      when :moving_to_player
        tick_action_moving_to_player
      when :move_to_home
        tick_action_move_to_home
      when :finding_home
        tick_action_finding_home
      when :moving_to_home
        tick_action_moving_to_home
      end
    end

    def primitives
      [
        {
          x: @x,
          y: @y,
          w: @w,
          h: @h,
          path: :solid,
          r: 255,
          g: 128,
          b: 128
        },
        Geometry.zoom_rect(rect: { x: @x, y: @y, w: @w, h: @h },
                           px: -4)
                .merge(path: :solid, r: 0, g: 0, b: 0, a: 128),
        {
          x: @x + @w / 2,
          y: @y + @h / 2,
          text: "#{@action}",
          anchor_x: 0.5,
          anchor_y: 0.5 - 0.5,
          r: 200,
          g: 200,
          b: 200,
          size_px: 12,
        },
        {
          x: @x + @w / 2,
          y: @y + @h / 2,
          text: "(#{@ordinal_x},#{@ordinal_y})",
          anchor_x: 0.5,
          anchor_y: 0.5 + 0.5,
          r: 200,
          g: 200,
          b: 200,
          size_px: 12,
        }
      ]
    end

    def action!(value)
      return if @action == value
      @action = value
      @action_at = @game.args.tick_count
    end

    def move_to_player!
      action!(:move_to_player)
    end

    def move_to_home!
      action!(:move_to_home)
    end

    def tick_action_move_to_home
      home_location = { ordinal_x: @ordinal_x, ordinal_y: @ordinal_y }
      end_location = { ordinal_x: @home_ordinal_x, ordinal_y: @home_ordinal_y }
      walls = @game.walls.map { |w| { ordinal_x: w.ordinal_x, ordinal_y: w.ordinal_y } }
      grid_w = 32
      grid_h = 18

      @astar = AStar.new(start_location: home_location,
                         end_location: end_location,
                         walls: walls,
                         grid_w: grid_w,
                         grid_h: grid_h)

      action!(:finding_home)

      @astar.start!
    end

    def tick_action_finding_home
      @astar.estimated_iterations_to_solve
            .fdiv(60)
            .ceil
            .times do
        if !@astar.complete?
          @astar.tick
        end
      end

      if @astar.complete?
        if @astar.path_found?
          @move_queue = @astar.path.dup
          action!(:moving_to_home)
        else
          action!(:idle)
        end
      end
    end

    def __move__ x, y
      @x = x
      @y = y
      @ordinal_x = @x.idiv(40)
      @ordinal_y = @y.idiv(40)
    end

    def tick_action_moving_to_home
      current_target = @move_queue.first
      current_target_rect = { x: current_target.ordinal_x * 40,
                              y: current_target.ordinal_y * 40,
                              w: 40,
                              h: 40 }
      angle = Geometry.angle(self, current_target_rect)
      distance = Geometry.distance(self, current_target_rect)
      speed = 4
      __move__(@x + angle.to_vector.x * speed, @y + angle.to_vector.y * speed)
      if distance <= speed
        @move_queue.pop_front
      end

      if @move_queue.empty?
        __move__(current_target.ordinal_x * 40, current_target.ordinal_y * 40)
        action!(:idle)
      end
    end

    def tick_action_move_to_player
      home_location = { ordinal_x: @ordinal_x, ordinal_y: @ordinal_y }
      end_location = { ordinal_x: @game.player.ordinal_x, ordinal_y: @game.player.ordinal_y }
      walls = @game.walls.map { |w| { ordinal_x: w.ordinal_x, ordinal_y: w.ordinal_y } }
      grid_w = 32
      grid_h = 18

      @astar = AStar.new(start_location: home_location,
                         end_location: end_location,
                         walls: walls,
                         grid_w: grid_w,
                         grid_h: grid_h)

      action!(:finding_player)

      @astar.start!
    end

    def tick_action_finding_player
      @astar.estimated_iterations_to_solve
            .fdiv(60)
            .ceil
            .times do
        if !@astar.complete?
          @astar.tick
        end
      end

      if @astar.complete?
        if @astar.path_found?
          @move_queue = @astar.path.dup
          action!(:moving_to_player)
        else
          action!(:idle)
        end
      end
    end

    def tick_action_moving_to_player
      current_target = @move_queue.first
      current_target_rect = { x: current_target.ordinal_x * 40,
                              y: current_target.ordinal_y * 40,
                              w: 40,
                              h: 40 }
      angle = Geometry.angle(self, current_target_rect)
      distance = Geometry.distance(self, current_target_rect)
      speed = 4
      __move__(@x + angle.to_vector.x * speed, @y + angle.to_vector.y * speed)

      if distance <= speed
        @move_queue.pop_front
      end

      if @move_queue.empty?
        __move__(current_target.ordinal_x * 40, current_target.ordinal_y * 40)
        action!(:idle)
      end
    end
  end

```

### A Star Advanced - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/08_a_star_advanced/app/main.rb
  require 'app/astar.rb'
  require 'app/enemy.rb'
  require 'app/player.rb'

  class Game
    attr_dr

    attr :walls, :player, :enemies

    def initialize
      @enemies = [
        Enemy.new(game: self, **ordinal_rect(ordinal_x: 0, ordinal_y: 17)),
        Enemy.new(game: self, **ordinal_rect(ordinal_x: 8, ordinal_y: 17)),
        Enemy.new(game: self, **ordinal_rect(ordinal_x: 7, ordinal_y: 8)),
        Enemy.new(game: self, **ordinal_rect(ordinal_x: 12, ordinal_y: 14)),
      ]

      @player = Player.new(game: self, **ordinal_rect(ordinal_x: 31, ordinal_y: 0))

      @walls = [
        ordinal_rect(ordinal_x: 1, ordinal_y: 1),
        ordinal_rect(ordinal_x: 2, ordinal_y: 2),
        ordinal_rect(ordinal_x: 3, ordinal_y: 3),
        ordinal_rect(ordinal_x: 4, ordinal_y: 4),
        ordinal_rect(ordinal_x: 5, ordinal_y: 5),
        ordinal_rect(ordinal_x: 6, ordinal_y: 6),
        ordinal_rect(ordinal_x: 7, ordinal_y: 7),
        ordinal_rect(ordinal_x: 8, ordinal_y: 8),
        ordinal_rect(ordinal_x: 9, ordinal_y: 9),
        ordinal_rect(ordinal_x: 10, ordinal_y: 10),
        ordinal_rect(ordinal_x: 11, ordinal_y: 11),
        ordinal_rect(ordinal_x: 12, ordinal_y: 12),
        ordinal_rect(ordinal_x: 13, ordinal_y: 13),
        ordinal_rect(ordinal_x: 14, ordinal_y: 14),
        ordinal_rect(ordinal_x: 15, ordinal_y: 15),
        ordinal_rect(ordinal_x: 16, ordinal_y: 16),
      ]
    end

    def ordinal_rect(ordinal_x:, ordinal_y:)
      {
        x: ordinal_x * 40,
        y: ordinal_y * 40,
        w: 40,
        h: 40,
        ordinal_x: ordinal_x,
        ordinal_y: ordinal_y,
      }
    end

    def tick
      if inputs.keyboard.key_down.j
        @enemies.each(&:move_to_player!)
      elsif inputs.keyboard.key_down.k
        @enemies.each(&:move_to_home!)
      end
      @enemies.each(&:tick)
      render
    end

    def render
      outputs.background_color = [30, 30, 30]
      outputs.primitives << @walls.map do |w|
        w.merge(path: :solid, r: 128, g: 128, b: 128)
      end

      outputs.primitives << @player.primitives
      outputs.primitives << @enemies.map(&:primitives)
      outputs.primitives << {
        x: 640,
        y: 60,
        text: "press J to move enemies to player, press K to move back to start position",
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: 255,
        g: 255,
        b: 255
      }
    end
  end

  module Main
    attr :game

    def boot args
      args.state = {}
    end

    def tick args
      @game ||= Game.new
      @game.args = args
      @game.tick
    end

    def did_reset args
      @game = nil
    end
  end

  DR.reset

```

### A Star Advanced - player.rb
```ruby
  # ./samples/13_path_finding_algorithms/08_a_star_advanced/app/player.rb
  class Player
    attr :game, :x, :y, :w, :h, :ordinal_x, :ordinal_y

    def initialize(game:, x:, y:, w:, h:, ordinal_x:, ordinal_y:)
      @game = game
      @x = x
      @y = y
      @w = w
      @h = h
      @ordinal_x = ordinal_x
      @ordinal_y = ordinal_y
    end

    def primitives
      [
        {
          x: @x,
          y: @y,
          w: @w,
          h: @h,
          path: :solid,
          r: 128,
          g: 255,
          b: 128
        },
      ]
    end
  end

```

### A Star Advanced - repl.rb
```ruby
  # ./samples/13_path_finding_algorithms/08_a_star_advanced/app/repl.rb
  db = FFI::DuckDB.new
  # db.raw("create table integers(i integer, j integer);")
  # db.raw("insert into integers values (1, 2) (3, 4) (5, 6);")
  # rows = db.query("select * from integers")
  # rows.each do |row|
  #   puts row[:i]
  #   puts row[:j]
  # end

```

### Tower Defense - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/09_tower_defense/app/main.rb
  # Contributors outside of DragonRuby who also hold Copyright:
  # - Sujay Vadlakonda: https://github.com/sujayvadlakonda

  # An example of some major components in a tower defence game
  # The pathing of the tanks is determined by A* algorithm -- try editing the walls

  # The turrets shoot bullets at the closest tank. The bullets are heat-seeking

  def tick args
    DR.reset if args.inputs.keyboard.key_down.r
    defaults args
    render args
    calc args
  end

  def defaults args
    args.outputs.background_color = wall_color
    args.state.grid_size = 5
    args.state.tile_size = 50
    args.state.grid_start ||= [0, 0]
    args.state.grid_goal  ||= [4, 4]

    # Try editing these walls to see the path change!
    args.state.walls ||= {
      [0, 4] => true,
      [1, 3] => true,
      [3, 1] => true,
      # [4, 0] => true,
    }

    args.state.a_star.frontier ||= []
    args.state.a_star.came_from ||= {}
    args.state.a_star.path ||= []

    args.state.tanks ||= []
    args.state.tank_spawn_period ||= 60
    args.state.tank_sprite_path ||= 'sprites/circle/white.png'
    args.state.tank_speed ||= 1

    args.state.turret_shoot_period = 10
    # Turrets can be entered as [x, y] but are immediately mapped to hashes
    # Walls are also added where the turrets are to prevent tanks from pathing over them
    args.state.turrets ||= [
      [2, 2]
    ].each { |turret| args.state.walls[turret] = true}.map do |x, y|
      {
        x: x * args.state.tile_size,
        y: y * args.state.tile_size,
        w: args.state.tile_size,
        h: args.state.tile_size,
        path: 'sprites/circle/gray.png',
        range: 100
      }
    end

    args.state.bullet_size ||= 25
    args.state.bullets ||= []
    args.state.bullet_path ||= 'sprites/circle/orange.png'
  end

  def render args
    render_grid args
    render_a_star args
    args.outputs.sprites << args.state.tanks
    args.outputs.sprites << args.state.turrets
    args.outputs.sprites << args.state.bullets
  end

  def render_grid args
    # Draw a square the size and color of the grid
    args.outputs.solids << {
      x: 0,
      y: 0,
      w: args.state.grid_size * args.state.tile_size,
      h: args.state.grid_size * args.state.tile_size,
    }.merge(grid_color)

    # Draw lines across the grid to show tiles
    (args.state.grid_size + 1).times do | value |
      render_horizontal_line(args, value)
      render_vertical_line(args, value)
    end

    # Render special tiles
    render_tile(args, args.state.grid_start, start_color)
    render_tile(args, args.state.grid_goal, goal_color)
    args.state.walls.keys.each { |wall| render_tile(args, wall, wall_color) }
  end

  def render_vertical_line args, x
    args.outputs.lines << {
      x: x * args.state.tile_size,
      y: 0,
      w: 0,
      h: args.state.grid_size * args.state.tile_size
    }
  end

  def render_horizontal_line args, y
    args.outputs.lines << {
      x: 0,
      y: y * args.state.tile_size,
      w: args.state.grid_size * args.state.tile_size,
      h: 0
    }
  end

  def render_tile args, tile, color
    args.outputs.solids << {
      x: tile.x * args.state.tile_size,
      y: tile.y * args.state.tile_size,
      w: args.state.tile_size,
      h: args.state.tile_size,
      r: color[0],
      g: color[1],
      b: color[2]
    }
  end

  def calc args
    calc_a_star args
    calc_tanks args
    calc_turrets args
    calc_bullets args
  end

  def calc_a_star args
    # Only does this one time
    return unless args.state.a_star.path.empty?

    # Start the search from the grid start
    args.state.a_star.frontier << args.state.grid_start
    args.state.a_star.came_from[args.state.grid_start] = nil

    # Until a path to the goal has been found or there are no more tiles to explore
    until (args.state.a_star.came_from.key?(args.state.grid_goal) || args.state.a_star.frontier.empty?)
      # For the first tile in the frontier
      tile_to_expand_from = args.state.a_star.frontier.shift
      # Add each of its neighbors to the frontier
      neighbors(args, tile_to_expand_from).each do |tile|
        args.state.a_star.frontier << tile
        args.state.a_star.came_from[tile] = tile_to_expand_from
      end
    end

    # Stop calculating a path if the goal was never reached
    return unless args.state.a_star.came_from.key? args.state.grid_goal

    # Fill path by tracing back from the goal
    current_cell = args.state.grid_goal
    while current_cell
      args.state.a_star.path.unshift current_cell
      current_cell = args.state.a_star.came_from[current_cell]
    end

    puts "The path has been calculated"
    puts args.state.a_star.path
  end

  def calc_tanks args
    spawn_tank args
    move_tanks args
  end

  def move_tanks args
    # Remove tanks that have reached the end of their path
    args.state.tanks.reject! { |tank| tank[:a_star].empty? }

    # Tanks have an array that has each tile it has to go to in order from a* path
    args.state.tanks.each do | tank |
      destination = tank[:a_star][0]
      # Move the tank towards the destination
      tank[:x] += copy_sign(args.state.tank_speed, ((destination.x * args.state.tile_size) - tank[:x]))
      tank[:y] += copy_sign(args.state.tank_speed, ((destination.y * args.state.tile_size) - tank[:y]))
      # If the tank has reached its destination
      if (destination.x * args.state.tile_size) == tank[:x] &&
          (destination.y * args.state.tile_size) == tank[:y]
        # Set the destination to the next point in the path
        tank[:a_star].shift
      end
    end
  end

  def calc_turrets args
    return unless Kernel.tick_count.mod_zero? args.state.turret_shoot_period
    args.state.turrets.each do | turret |
      # Finds the closest tank
      target = nil
      shortest_distance = turret[:range] + 1
      args.state.tanks.each do | tank |
        distance = distance_between(turret[:x], turret[:y], tank[:x], tank[:y])
        if distance < shortest_distance
          target = tank
          shortest_distance = distance
        end
      end
      # If there is a tank in range, fires a bullet
      if target
        args.state.bullets << {
          x: turret[:x],
          y: turret[:y],
          w: args.state.bullet_size,
          h: args.state.bullet_size,
          path: args.state.bullet_path,
          # Note that this makes it heat-seeking, because target is passed by reference
          # Could do target.clone to make the bullet go to where the tank initially was
          target: target
        }
      end
    end
  end

  def calc_bullets args
    # Bullets aim for the center of their targets
    args.state.bullets.each { |bullet| move bullet, center_of(bullet[:target])}
    args.state.bullets.reject! { |b| b.intersect_rect? b[:target] }
  end

  def center_of object
    object = object.clone
    object[:x] += 0.5
    object[:y] += 0.5
    object
  end

  def render_a_star args
    args.state.a_star.path.map do |tile|
      # Map each x, y coordinate to the center of the tile and scale up
      [(tile.x + 0.5) * args.state.tile_size, (tile.y + 0.5) * args.state.tile_size]
    end.inject do | point_a,  point_b |
      # Render the line between each point
      args.outputs.lines << [point_a.x, point_a.y, point_b.x, point_b.y, a_star_color]
      point_b
    end
  end

  # Moves object to target at speed
  def move object, target, speed = 1
    if target.is_a? Hash
      object[:x] += copy_sign(speed, target[:x] - object[:x])
      object[:y] += copy_sign(speed, target[:y] - object[:y])
    else
      object[:x] += copy_sign(speed, target.x - object[:x])
      object[:y] += copy_sign(speed, target.y - object[:y])
    end
  end


  def distance_between a_x, a_y, b_x, b_y
    (((b_x - a_x) ** 2) + ((b_y - a_y) ** 2)) ** 0.5
  end

  def copy_sign value, sign
    return 0 if sign == 0
    return value if sign > 0
    -value
  end

  def spawn_tank args
    return unless Kernel.tick_count.mod_zero? args.state.tank_spawn_period
    args.state.tanks << {
      x: args.state.grid_start.x,
      y: args.state.grid_start.y,
      w: args.state.tile_size,
      h: args.state.tile_size,
      path: args.state.tank_sprite_path,
      a_star: args.state.a_star.path.clone
    }
  end

  def neighbors args, tile
    [[tile.x, tile.y - 1],
     [tile.x, tile.y + 1],
     [tile.x + 1, tile.y],
     [tile.x - 1, tile.y]].reject do |neighbor|
      args.state.a_star.came_from.key?(neighbor) || tile_out_of_bounds?(args, neighbor) ||
        args.state.walls.key?(neighbor)
    end
  end

  def tile_out_of_bounds? args, tile
    tile.x < 0 || tile.y < 0 || tile.x >= args.state.grid_size || tile.y >= args.state.grid_size
  end

  def grid_color
    { r: 133, g: 226, b: 144 }
  end

  def start_color
    [226, 144, 133]
  end

  def goal_color
    [226, 133, 144]
  end

  def wall_color
    [133, 144, 226]
  end

  def a_star_color
    [0, 0, 255]
  end

```

### Moveable Squares - main.rb
```ruby
  # ./samples/13_path_finding_algorithms/10_moveable_squares/app/main.rb
  class Game
    attr_dr

    def tick
      defaults
      calc
      render
    end

    def defaults
      state.square_size ||= 16
      if !state.world
        state.world = {
          w: 80,
          h: 45,
          player: {
            x: 15,
            y: 15,
            speed: 6
          },
          walls: [
            { x: 16, y: 16 },
            { x: 15, y: 16 },
            { x: 14, y: 17 },
            { x: 14, y: 13 },
            { x: 15, y: 13 },
            { x: 16, y: 13 },
            { x: 17, y: 13 }
          ]
        }
      end
    end

    def calc
      player = world.player
      player.rect = { x: player.x * state.square_size, y: player.y * state.square_size, w: state.square_size, h: state.square_size }
      player.moveable_squares = entity_moveable_squares world.player
      if inputs.keyboard.key_down.plus
        state.world.player.speed += 1
      elsif inputs.keyboard.key_down.minus
        state.world.player.speed -= 1
        state.world.player.speed = 1 if state.world.player.speed < 1
      end

      mouse_ordinal_x = inputs.mouse.x.idiv state.square_size
      mouse_ordinal_y = inputs.mouse.y.idiv state.square_size

      if inputs.mouse.click
        if world.walls.any? { |enemy| enemy.x == mouse_ordinal_x && enemy.y == mouse_ordinal_y }
          world.walls.reject! { |enemy| enemy.x == mouse_ordinal_x && enemy.y == mouse_ordinal_y }
        else
          world.walls << { x: mouse_ordinal_x, y: mouse_ordinal_y, speed: 3 }
        end
      end

      state.hovered_square = world.player.moveable_squares.find do |square|
        mouse_ordinal_x == square.x && mouse_ordinal_y == square.y
      end
    end

    def render
      outputs.primitives << { x: 30, y: 30.from_top, text: "+/- to increase decrease movement radius." }
      outputs.primitives << { x: 30, y: 60.from_top, text: "click to add/remove wall." }
      outputs.primitives << { x: 30, y: 90.from_top, text: "FPS: #{DR.current_framerate.to_sf}" }
      if Kernel.tick_count <= 1
        outputs[:world_grid].w = 1280
        outputs[:world_grid].h = 720
        outputs[:world_grid].primitives << state.world.w.flat_map do |x|
          state.world.h.map do |y|
            {
              x: x * state.square_size,
              y: y * state.square_size,
              w: state.square_size,
              h: state.square_size,
              r: 0,
              g: 0,
              b: 0,
              a: 128
            }.border!
          end
        end
      end

      outputs[:world_overlay].w = 1280
      outputs[:world_overlay].h = 720

      if state.hovered_square
        outputs[:world_overlay].primitives << path_to_square_prefab(state.hovered_square)
      end

      outputs[:world_overlay].primitives << world.player.moveable_squares.map do |square|
        square_prefab square, { r: 0, g: 0, b: 128, a: 128 }
      end

      outputs[:world_overlay].primitives << world.walls.map do |enemy|
        square_prefab enemy, { r: 128, g: 0, b: 0, a: 200 }
      end

      outputs[:world_overlay].primitives << square_prefab(world.player, { r: 0, g: 128, b: 0, a: 200 })

      outputs[:world].w = 1280
      outputs[:world].h = 720
      outputs[:world].primitives << { x: 0, y: 0, w: 1280, h: 720, path: :world_grid }
      outputs[:world].primitives << { x: 0, y: 0, w: 1280, h: 720, path: :world_overlay }
      outputs.primitives << { x: 0, y: 0, w: 1280, h: 720, path: :world }
    end

    def square_prefab square, color
      {
        x: square.x * state.square_size,
        y: square.y * state.square_size,
        w: state.square_size,
        h: state.square_size,
        **color,
        path: :solid
      }
    end

    def path_to_square_prefab moveable_square
      prefab = []
      color = { r: 0, g: 0, b: 128, a: 80 }
      if moveable_square
        prefab << square_prefab(moveable_square, color)
        prefab << path_to_square_prefab(moveable_square.source)
      end
      prefab
    end

    def world
      state.world
    end

    def entity_moveable_squares entity
      results = {}
      queue = {}
      queue[entity.x] ||= {}
      queue[entity.x][entity.y] = entity
      entity_moveable_squares_recur queue, results while !queue.empty?
      results.flat_map do |x, ys|
        ys.map do |y, value|
          value
        end
      end
    end

    def entity_moveable_squares_recur queue, results
      x, ys = queue.first
      return if !x
      return if !ys
      y, to_process = ys.first
      return if !to_process
      queue[to_process.x].delete y
      queue.delete x if queue[x].empty?
      return if results[to_process.x] && results[to_process.x] && results[to_process.x][to_process.y]

      neighbors = MoveableLocations.neighbors world, to_process
      neighbors.each do |neighbor|
        if !queue[neighbor.x] || !queue[neighbor.x][neighbor.y]
          queue[neighbor.x] ||= {}
          queue[neighbor.x][neighbor.y] = neighbor
        end
      end

      results[to_process.x] ||= {}
      results[to_process.x][to_process.y] = to_process
    end
  end

  class MoveableLocations
    class << self
      def neighbors world, square
        return [] if !square
        return [] if square.speed <= 0
        north_square = { x: square.x, y: square.y + 1, speed: square.speed - 1, source: square }
        south_square = { x: square.x, y: square.y - 1, speed: square.speed - 1, source: square }
        east_square  = { x: square.x + 1, y: square.y, speed: square.speed - 1, source: square }
        west_square  = { x: square.x - 1, y: square.y, speed: square.speed - 1, source: square }
        north_east_square = { x: square.x + 1, y: square.y + 1, speed: square.speed - 2, source: square }
        north_west_square = { x: square.x - 1, y: square.y + 1, speed: square.speed - 2, source: square }
        south_east_square = { x: square.x + 1, y: square.y - 1, speed: square.speed - 2, source: square }
        south_west_square = { x: square.x - 1, y: square.y - 1, speed: square.speed - 2, source: square }
        result = []
        north_available = valid? world, north_square
        south_available = valid? world, south_square
        east_available  = valid? world, east_square
        west_available  = valid? world, west_square
        north_east_available = valid? world, north_east_square
        north_west_available = valid? world, north_west_square
        south_east_available = valid? world, south_east_square
        south_west_available = valid? world, south_west_square
        result << north_square if north_available
        result << south_square if south_available
        result << east_square  if east_available
        result << west_square  if west_available
        result << north_east_square if north_available && east_available && north_east_available
        result << north_west_square if north_available && west_available && north_west_available
        result << south_east_square if south_available && east_available && south_east_available
        result << south_west_square if south_available && west_available && south_west_available
        result
      end

      def valid? world, square
        return false if !square
        return false if square.speed < 0
        return false if square.x < 0 || square.x >= world.w || square.y < 0 || square.y >= world.h
        return false if world.walls.any? { |enemy| enemy.x == square.x && enemy.y == square.y }
        return false if world.player.x == square.x && world.player.y == square.y
        return true
      end
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  DR.reset

```
