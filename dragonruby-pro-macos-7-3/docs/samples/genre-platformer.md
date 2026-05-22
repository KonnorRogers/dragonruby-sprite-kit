### Clepto Frog - main.rb
```ruby
  # ./samples/99_genre_platformer/clepto_frog/app/main.rb
  class CleptoFrog
    attr_dr

    def tick
      defaults
      render
      input
      calc
    end

    def defaults
      state.level_editor_rect_w ||= 32
      state.level_editor_rect_h     ||= 32
      state.target_camera_scale ||= 0.5
      state.camera_scale        ||= 1
      state.tongue_length       ||= 100
      state.action              ||= :aiming
      state.tongue_angle        ||= 90
      state.tile_size           ||= 32
      state.gravity             ||= -0.1
      state.drag                ||= -0.005
      state.player ||= {
        x: 2400,
        y: 200,
        w: 60,
        h: 60,
        dx: 0,
        dy: 0,
      }
      state.camera_x     ||= state.player.x - 640
      state.camera_y     ||= 0
      load_if_needed
      state.map_saved_at ||= 0
    end

    def player
      state.player
    end

    def render
      render_world
      render_player
      render_level_editor
      render_mini_map
      render_instructions
    end

    def to_camera_space rect
      rect.merge(x: to_camera_space_x(rect.x),
                 y: to_camera_space_y(rect.y),
                 w: to_camera_space_w(rect.w),
                 h: to_camera_space_h(rect.h))
    end

    def to_camera_space_x x
      return nil if !x
       (x * state.camera_scale) - state.camera_x
    end

    def to_camera_space_y y
      return nil if !y
      (y * state.camera_scale) - state.camera_y
    end

    def to_camera_space_w w
      return nil if !w
      w * state.camera_scale
    end

    def to_camera_space_h h
      return nil if !h
      h * state.camera_scale
    end

    def render_world
      viewport = {
        x: player.x - 1280 / state.camera_scale,
        y: player.y - 720 / state.camera_scale,
        w: 2560 / state.camera_scale,
        h: 1440 / state.camera_scale
      }

      outputs.sprites << Geometry.find_all_intersect_rect(viewport, state.mugs).map do |rect|
        to_camera_space rect
      end

      outputs.sprites << Geometry.find_all_intersect_rect(viewport, state.walls).map do |rect|
        to_camera_space(rect).merge!(path: :pixel, r: 128, g: 128, b: 128, a: 128)
      end
    end

    def render_player
      start_of_tongue_render = to_camera_space start_of_tongue

      if state.anchor_point
        anchor_point_render = to_camera_space state.anchor_point
        outputs.sprites << { x: start_of_tongue_render.x - 2,
                             y: start_of_tongue_render.y - 2,
                             w: to_camera_space_w(4),
                             h: Geometry.distance(start_of_tongue_render, anchor_point_render),
                             path:  :pixel,
                             angle_anchor_y: 0,
                             r: 255, g: 128, b: 128,
                             angle: state.tongue_angle - 90 }
      else
        outputs.sprites << { x: to_camera_space_x(start_of_tongue.x) - 2,
                             y: to_camera_space_y(start_of_tongue.y) - 2,
                             w: to_camera_space_w(4),
                             h: to_camera_space_h(state.tongue_length),
                             path:  :pixel,
                             r: 255, g: 128, b: 128,
                             angle_anchor_y: 0,
                             angle: state.tongue_angle - 90 }
      end

      angle = 0
      if state.action == :aiming && !player.on_floor
        angle = state.tongue_angle - 90
      elsif state.action == :shooting && !player.on_floor
        angle = state.tongue_angle - 90
      elsif state.action == :anchored
        angle = state.tongue_angle - 90
      end

      outputs.sprites << to_camera_space(player).merge!(path: "sprites/square/green.png", angle: angle)
    end

    def render_mini_map
      x, y = 1170, 10
      outputs.primitives << { x: x,
                              y: y,
                              w: 100,
                              h: 58,
                              r: 0,
                              g: 0,
                              b: 0,
                              a: 200,
                              path: :pixel }

      outputs.primitives << { x: x + player.x.fdiv(100) - 1,
                              y: y + player.y.fdiv(100) - 1,
                              w: 2,
                              h: 2,
                              r: 0,
                              g: 255,
                              b: 0,
                              path: :pixel }

      t_start = start_of_tongue
      t_end = end_of_tongue

      outputs.primitives << {
        x: x + t_start.x.fdiv(100),
        y: y + t_start.y.fdiv(100),
        x2: x + t_end.x.fdiv(100),
        y2: y + t_end.y.fdiv(100),
        r: 255, g: 255, b: 255
      }

      outputs.primitives << state.mugs.map do |o|
        { x: x + o.x.fdiv(100) - 1,
          y: y + o.y.fdiv(100) - 1,
          w: 2,
          h: 2,
          r: 200,
          g: 200,
          b: 0,
          path: :pixel }
      end
    end

    def render_level_editor
      return if !state.level_editor_mode
      if state.map_saved_at > 0 && state.map_saved_at.elapsed_time < 120
        outputs.primitives << { x: 920, y: 670, text: 'Map has been exported!', size_enum: 1, r: 0, g: 50, b: 100, a: 50 }
      end

      outputs.primitives << { x: to_camera_space_x(((state.camera_x + inputs.mouse.x) / state.camera_scale).ifloor(state.tile_size)),
                              y: to_camera_space_y(((state.camera_y + inputs.mouse.y) / state.camera_scale).ifloor(state.tile_size)),
                              w: to_camera_space_w(state.level_editor_rect_w),
                              h: to_camera_space_h(state.level_editor_rect_h), path: :pixel, a: 200, r: 180, g: 80, b: 200 }
    end

    def render_instructions
      if state.level_editor_mode
        outputs.labels << { x: 640,
                            y: 10.from_top,
                            text: "Click to place wall. HJKL to change wall size. X + click to remove wall. M + click to place mug. Arrow keys to move around.",
                            size_enum: -1,
                            anchor_x: 0.5 }
        outputs.labels << { x: 640,
                            y: 35.from_top,
                            text: " - and + to zoom in and out. 0 to reset camera to default zoom. G to exit level editor mode.",
                            size_enum: -1,
                            anchor_x: 0.5 }
      else
        outputs.labels << { x: 640,
                            y: 10.from_top,
                            text: "Left and Right to aim tongue. Space to shoot or release tongue. G to enter level editor mode.",
                            size_enum: -1,
                            anchor_x: 0.5 }

        outputs.labels << { x: 640,
                            y: 35.from_top,
                            text: "Up and Down to change tongue length (when tongue is attached). Left and Right to swing (when tongue is attached).",
                            size_enum: -1,
                            anchor_x: 0.5 }
      end
    end

    def start_of_tongue
      {
        x: player.x + player.w / 2,
        y: player.y + player.h / 2
      }
    end

    def calc
      calc_camera
      calc_player
      calc_mug_collection
    end

    def calc_camera
      percentage = 0.2 * state.camera_scale
      target_scale = state.target_camera_scale
      distance_scale = target_scale - state.camera_scale
      state.camera_scale += distance_scale * percentage

      target_x = player.x * state.target_camera_scale
      target_y = player.y * state.target_camera_scale

      distance_x = target_x - (state.camera_x + 640)
      distance_y = target_y - (state.camera_y + 360)
      state.camera_x += distance_x * percentage if distance_x.abs > 1
      state.camera_y += distance_y * percentage if distance_y.abs > 1
      state.camera_x = 0 if state.camera_x < 0
      state.camera_y = 0 if state.camera_y < 0
    end

    def calc_player
      calc_shooting
      calc_swing
      calc_aabb_collision
      calc_tongue_angle
      calc_on_floor
    end

    def calc_shooting
      calc_shooting_step
      calc_shooting_step
      calc_shooting_step
      calc_shooting_step
      calc_shooting_step
      calc_shooting_step
    end

    def calc_shooting_step
      return unless state.action == :shooting
      state.tongue_length += 5
      potential_anchor = end_of_tongue
      anchor_rect = { x: potential_anchor.x - 5, y: potential_anchor.y - 5, w: 10, h: 10 }
      collision = state.walls.find_all do |v|
        v.intersect_rect?(anchor_rect)
      end.first
      if collision
        state.anchor_point = potential_anchor
        state.action = :anchored
      end
    end

    def calc_swing
      return if !state.anchor_point
      target_x = state.anchor_point.x - start_of_tongue.x
      target_y = state.anchor_point.y -
                 state.tongue_length - 5 - 20 - player.h

      diff_y = player.y - target_y

      distance = Geometry.distance(player, state.anchor_point)
      pull_strength = if distance < 100
                        0
                      else
                        (distance / 800)
                      end

      vector = state.tongue_angle.to_vector

      player.dx += vector.x * pull_strength**2
      player.dy += vector.y * pull_strength**2
    end

    def calc_aabb_collision
      return if !state.walls

      player.dx = player.dx.clamp(-30, 30)
      player.dy = player.dy.clamp(-30, 30)

      player.dx += player.dx * state.drag
      player.x += player.dx

      collision = Geometry.find_intersect_rect player, state.walls

      if collision
        if player.dx > 0
          player.x = collision.x - player.w
        elsif player.dx < 0
          player.x = collision.x + collision.w
        end
        player.dx *= -0.8
      end

      if !state.level_editor_mode
        player.dy += state.gravity  # Since acceleration is the change in velocity, the change in y (dy) increases every frame
        player.y += player.dy
      end

      collision = Geometry.find_intersect_rect player, state.walls

      if collision
        if player.dy > 0
          player.y = collision.y - 60
        elsif player.dy < 0
          player.y = collision.y + collision.h
        end

        player.dy *= -0.8
      end
    end

    def calc_tongue_angle
      return unless state.anchor_point
      state.tongue_angle = Geometry.angle_from state.anchor_point, start_of_tongue
      state.tongue_length = Geometry.distance(start_of_tongue, state.anchor_point)
      state.tongue_length = state.tongue_length.greater(100)
    end

    def calc_on_floor
      if state.action == :anchored
        player.on_floor = false
        player.on_floor_debounce = 30
      else
        player.on_floor_debounce ||= 30

        if player.dy.round != 0
          player.on_floor_debounce = 30
          player.on_floor = false
        else
          player.on_floor_debounce -= 1
        end

        if player.on_floor_debounce <= 0
          player.on_floor_debounce = 0
          player.on_floor = true
        end
      end
    end

    def calc_mug_collection
      collected = state.mugs.find_all { |s| s.intersect_rect? player }
      state.mugs.reject! { |s| collected.include? s }
    end

    def set_camera_scale v = nil
      return if v < 0.1
      state.target_camera_scale = v
    end

    def input
      input_game
      input_level_editor
    end

    def input_up?
      inputs.keyboard.w || inputs.keyboard.up
    end

    def input_down?
      inputs.keyboard.s || inputs.keyboard.down
    end

    def input_left?
      inputs.keyboard.a || inputs.keyboard.left
    end

    def input_right?
      inputs.keyboard.d || inputs.keyboard.right
    end

    def input_game
      if inputs.keyboard.key_down.g
        state.level_editor_mode = !state.level_editor_mode
      end

      if player.on_floor
        if inputs.keyboard.q
          player.dx = -5
        elsif inputs.keyboard.e
          player.dx = 5
        end
      end

      if inputs.keyboard.key_down.space && !state.anchor_point
        state.tongue_length = 0
        state.action = :shooting
      elsif inputs.keyboard.key_down.space
        state.action = :aiming
        state.anchor_point  = nil
        state.tongue_length = 100
      end

      if state.anchor_point
        vector = state.tongue_angle.to_vector

        if input_up?
          state.tongue_length -= 5
          player.dy += vector.y
          player.dx += vector.x
        elsif input_down?
          state.tongue_length += 5
          player.dy -= vector.y
          player.dx -= vector.x
        end

        if input_left?
          player.dx -= 0.5
        elsif input_right?
          player.dx += 0.5
        end
      else
        if input_left?
          state.tongue_angle += 1.5
          state.tongue_angle = state.tongue_angle
        elsif input_right?
          state.tongue_angle -= 1.5
          state.tongue_angle = state.tongue_angle
        end
      end
    end

    def input_level_editor
      return unless state.level_editor_mode

      if Kernel.tick_count.mod_zero?(5)
        # zoom
        if inputs.keyboard.equal_sign || inputs.keyboard.plus
          set_camera_scale state.camera_scale + 0.1
        elsif inputs.keyboard.hyphen
          set_camera_scale state.camera_scale - 0.1
        elsif inputs.keyboard.zero
          set_camera_scale 0.5
        end

        # change wall width
        if inputs.keyboard.h
          state.level_editor_rect_w -= state.tile_size
        elsif inputs.keyboard.l
          state.level_editor_rect_w += state.tile_size
        end

        state.level_editor_rect_w = state.tile_size if state.level_editor_rect_w < state.tile_size

        # change wall height
        if inputs.keyboard.j
          state.level_editor_rect_h -= state.tile_size
        elsif inputs.keyboard.k
          state.level_editor_rect_h += state.tile_size
        end

        state.level_editor_rect_h = state.tile_size if state.level_editor_rect_h < state.tile_size
      end

      if inputs.mouse.click
        x = ((state.camera_x + inputs.mouse.x) / state.camera_scale).ifloor(state.tile_size)
        y = ((state.camera_y + inputs.mouse.y) / state.camera_scale).ifloor(state.tile_size)
        # place mug
        if inputs.keyboard.m
          w = 32
          h = 32
          candidate_rect = { x: x, y: y, w: w, h: h }
          if inputs.keyboard.x
            mouse_rect = { x: (state.camera_x + inputs.mouse.x) / state.camera_scale,
                           y: (state.camera_y + inputs.mouse.y) / state.camera_scale,
                           w: 10,
                           h: 10 }
            to_remove = state.mugs.find do |r|
              r.intersect_rect? mouse_rect
            end
            if to_remove
              state.mugs.reject! { |r| r == to_remove }
            end
          else
            exists = state.mugs.find { |r| r == candidate_rect }
            if !exists
              state.mugs << candidate_rect.merge(path: "sprites/square/orange.png")
            end
          end
        else
          # place wall
          w = state.level_editor_rect_w
          h = state.level_editor_rect_h
          candidate_rect = { x: x, y: y, w: w, h: h }
          if inputs.keyboard.x
            mouse_rect = { x: (state.camera_x + inputs.mouse.x) / state.camera_scale,
                           y: (state.camera_y + inputs.mouse.y) / state.camera_scale,
                           w: 10,
                           h: 10 }
            to_remove = state.walls.find do |r|
              r.intersect_rect? mouse_rect
            end
            if to_remove
              state.walls.reject! { |r| r == to_remove }
            end
          else
            exists = state.walls.find { |r| r == candidate_rect }
            if !exists
              state.walls << candidate_rect
            end
          end
        end

        save
      end

      if input_up?
        player.y += 10
        player.dy = 0
      elsif input_down?
        player.y -= 10
        player.dy = 0
      end

      if input_left?
        player.x -= 10
        player.dx = 0
      elsif input_right?
        player.x += 10
        player.dx = 0
      end
    end

    def end_of_tongue
      p = state.tongue_angle.to_vector
      { x: start_of_tongue.x + p.x * state.tongue_length,
        y: start_of_tongue.y + p.y * state.tongue_length }
    end

    def save
      DR.write_file("data/mugs.txt", "")
      state.mugs.each do |o|
        DR.append_file "data/mugs.txt", "#{o.x},#{o.y},#{o.w},#{o.h}\n"
      end

      DR.write_file("data/walls.txt", "")
      state.walls.map do |o|
        DR.append_file "data/walls.txt", "#{o.x},#{o.y},#{o.w},#{o.h}\n"
      end
    end

    def load_if_needed
      return if state.walls
      state.walls = []
      state.mugs = []

      contents = DR.read_file "data/mugs.txt"
      if contents
        contents.each_line do |l|
          x, y, w, h = l.split(',').map(&:to_i)
          state.mugs << { x: x.ifloor(state.tile_size),
                          y: y.ifloor(state.tile_size),
                          w: w,
                          h: h,
                          path: "sprites/square/orange.png" }
        end
      end

      contents = DR.read_file "data/walls.txt"
      if contents
        contents.each_line do |l|
          x, y, w, h = l.split(',').map(&:to_i)
          state.walls << { x: x.ifloor(state.tile_size),
                           y: y.ifloor(state.tile_size),
                           w: w,
                           h: h,
                           path: :pixel,
                           r: 128,
                           g: 128,
                           b: 128,
                           a: 128 }
        end
      end
    end
  end

  $game = CleptoFrog.new

  def tick args
    $game.args = args
    $game.tick
  end

  # DR.reset

```

### Gorillas Basic - main.rb
```ruby
  # ./samples/99_genre_platformer/gorillas_basic/app/main.rb
  class YouSoBasicGorillas
    attr_dr

    def tick
      defaults
      render
      calc
      process_inputs
    end

    def defaults
      outputs.background_color = [33, 32, 87]
      state.building_spacing       = 1
      state.building_room_spacing  = 15
      state.building_room_width    = 10
      state.building_room_height   = 15
      state.building_heights       = [4, 4, 6, 8, 15, 20, 18]
      state.building_room_sizes    = [5, 4, 6, 7]
      state.gravity                = 0.25
      state.current_turn         ||= :player_1
      state.buildings            ||= []
      state.holes                ||= []
      state.player_1_score       ||= 0
      state.player_2_score       ||= 0
      state.wind                 ||= 0
    end

    def render
      render_stage
      render_value_insertion
      render_gorillas
      render_holes
      render_banana
      render_game_over
      render_score
      render_wind
    end

    def render_score
      outputs.primitives << { x: 0, y: 0, w: 1280, h: 31, path: :solid, **white_color }
      outputs.primitives << { x: 1, y: 1, w: 1279, h: 29, path: :solid, r: 0, g: 0, b: 0 }
      outputs.labels << { x: 10, y: 25, text: "Score: #{state.player_1_score}", **white_color }
      outputs.labels << { x: 1270, y: 25, text: "Score: #{state.player_2_score}", anchor_x: 1.0, **white_color }
    end

    def render_wind
      outputs.primitives << { x: 640, y: 12, w: state.wind * 500 + state.wind * 10 * rand, path: :solid, h: 4, r: 35, g: 136, b: 162 }
      outputs.lines     <<  { x: 640, y: 30, x2: 640, y2: 0, **white_color }
    end

    def render_game_over
      return unless state.game_over
      outputs.primitives << { **Grid.rect, path: :solid, r: 0, g: 0, b: 0, a: 200 }
      outputs.primitives << { x: 640, y: 370, text: "Game Over!!", size_px: 36, anchor_x: 0.5, **white_color }
      if state.winner == :player_1
        outputs.primitives << { x: 640, y: 340, text: "Player 1 Wins!!", size_px: 36, anchor_x: 0.5, **white_color }
      else
        outputs.primitives << { x: 640, y: 340, text: "Player 2 Wins!!", size_px: 36, anchor_x: 0.5, **white_color }
      end
    end

    def render_stage
      return if !state.stage_generated

      if !state.stage_rt_generated
        outputs[:stage].w = 1280
        outputs[:stage].h = 720
        outputs[:stage].solids << { **Grid.rect, r: 33, g: 32, b: 87 }
        outputs[:stage].solids << state.buildings.map(&:prefab)
        state.stage_rt_generated = true
      else
        outputs.primitives << { x: 0, y: 0, w: 1280, h: 720, path: :stage }
      end
    end

    def render_gorilla gorilla, player_id, id
      return unless gorilla
      if state.banana && state.banana.owner == player_id
        animation_index  = state.banana.created_at.frame_index(3, 5, false)
      end
      if !animation_index
        outputs.primitives << { **gorilla.hurt_box, path: "sprites/#{id}-idle.png" }
      else
        outputs.primitives << { **gorilla.hurt_box, path: "sprites/#{id}-#{animation_index}.png" }
      end
    end

    def render_gorillas
      render_gorilla state.player_1, :player_1, :left
      render_gorilla state.player_2, :player_2, :right
    end

    def render_value_insertion
      return if state.banana
      return if state.game_over

      turn = if state.current_turn_input == :player_1_angle || state.current_turn_input == :player_1_velocity
               "It's your turn Player 1!"
             else
               "It's your turn Player 2!"
             end

      outputs.labels << { x: 640, y: 720 - 22, text: turn, **white_color, anchor_x: 0.5, anchor_y: 0.5 }

      if    state.current_turn_input == :player_1_angle
        outputs.labels << { x: 10, y: 710, text: "Angle:    #{state.player_1_angle}_", **white_color }
      elsif state.current_turn_input == :player_1_velocity
        outputs.labels << { x: 10, y: 710, text: "Angle:    #{state.player_1_angle}",  **white_color }
        outputs.labels << { x: 10, y: 690, text: "Velocity: #{state.player_1_velocity}_", **white_color }
      elsif state.current_turn_input == :player_2_angle
        outputs.labels << { x: 1120, y: 710, text: "Angle:    #{state.player_2_angle}_", **white_color }
      elsif state.current_turn_input == :player_2_velocity
        outputs.labels << { x: 1120, y: 710, text: "Angle:    #{state.player_2_angle}",  **white_color }
        outputs.labels << { x: 1120, y: 690, text: "Velocity: #{state.player_2_velocity}_", **white_color }
      end
    end

    def render_banana
      return unless state.banana
      rotation = Kernel.tick_count.%(360) * 20
      rotation *= -1 if state.banana.dx > 0
      outputs.primitives << { x: state.banana.x, y: state.banana.y, w: 15, h: 15, path: "sprites/banana.png", angle: rotation }
    end

    def render_holes
      outputs.primitives << state.holes.map do |s|
        animation_index = s.created_at.frame_index(7, 3, false)
        if animation_index
          [s.prefab, { **s.prefab.rect, path: "sprites/explosion#{animation_index}.png" }]
        else
          s.prefab
        end
      end
    end

    def calc
      calc_generate_stage
      calc_current_turn
      calc_banana 0.5
      calc_banana 0.5
    end

    def calc_current_turn
      return if state.current_turn_input

      state.current_turn_input = :player_1_angle
      state.current_turn_input = :player_2_angle if state.current_turn == :player_2
    end

    def calc_generate_stage
      return if state.stage_generated

      state.buildings << building_prefab(state.building_spacing + -20, *random_building_size)
      8.numbers.inject(state.buildings) do |buildings, i|
        buildings <<
          building_prefab(state.building_spacing +
                          state.buildings.last.right,
                          *random_building_size)
      end

      building_two = state.buildings[1]
      state.player_1 = new_player(building_two.x + building_two.w.fdiv(2),
                                  building_two.h)

      building_nine = state.buildings[-3]
      state.player_2 = new_player(building_nine.x + building_nine.w.fdiv(2),
                                  building_nine.h)
      state.stage_generated = true
      state.wind = 1.randomize(:ratio, :sign)
    end

    def new_player x, y
      {
        x: (x - 25),
        y: y,
        hurt_box: { x: x - 25, y: y, w: 50, h: 50 }
      }
    end

    def calc_banana simulation_dt
      return unless state.banana

      state.banana.x  += state.banana.dx * simulation_dt
      state.banana.dx += state.wind.fdiv(50) * simulation_dt
      state.banana.y  += state.banana.dy * simulation_dt
      state.banana.dy -= state.gravity * simulation_dt
      banana_collision = { x: state.banana.x, y: state.banana.y, w: 10, h: 10 }

      if state.player_1 && banana_collision.intersect_rect?(state.player_1.hurt_box)
        state.game_over = true
        state.winner = :player_2
        state.player_2_score += 1
      elsif state.player_2 && banana_collision.intersect_rect?(state.player_2.hurt_box)
        state.game_over = true
        state.winner = :player_1
        state.player_1_score += 1
      end

      if state.game_over
        place_hole
        return
      end

      return if state.holes.any? do |h|
        h.prefab.intersect_rect?(x: state.banana.x, y: state.banana.y, w: 10, h: 10, anchor_x: 0.5, anchor_y: 0.5)
      end

      return unless state.banana.y < 0 || state.buildings.any? do |b|
        b.rect.intersect_rect? x: state.banana.x, y: state.banana.y, w: 1, h: 1
      end

      place_hole
    end

    def place_hole
      return unless state.banana

      state.holes << state.new_entity(:banana) do |b|
        b.prefab = { x: state.banana.x, y: state.banana.y, w: 40, h: 40, path: "sprites/hole.png", anchor_x: 0.5, anchor_y: 0.5 }
      end

      state.banana = nil
    end

    def process_inputs_main
      return if state.banana
      return if state.game_over

      if inputs.keyboard.key_down.enter
        input_execute_turn
      elsif inputs.keyboard.key_down.backspace
        state.as_hash[state.current_turn_input] ||= ""
        state.as_hash[state.current_turn_input]   = state.as_hash[state.current_turn_input][0..-2]
      elsif inputs.keyboard.key_down.char
        state.as_hash[state.current_turn_input] ||= ""
        state.as_hash[state.current_turn_input]  += inputs.keyboard.key_down.char
      end
    end

    def process_inputs_game_over
      return unless state.game_over
      return unless inputs.keyboard.key_down.truthy_keys.any?
      state.game_over = false
      outputs.static_solids.clear
      state.buildings.clear
      state.holes.clear
      state.stage_generated = false
      state.stage_rt_generated = false
      if state.current_turn == :player_1
        state.current_turn = :player_2
      else
        state.current_turn = :player_1
      end
    end

    def process_inputs
      process_inputs_main
      process_inputs_game_over
    end

    def input_execute_turn
      return if state.banana

      if state.current_turn_input == :player_1_angle && parse_or_clear!(:player_1_angle)
        state.current_turn_input = :player_1_velocity
      elsif state.current_turn_input == :player_1_velocity && parse_or_clear!(:player_1_velocity)
        state.current_turn_input = :player_2_angle
        state.banana =
          new_banana(:player_1,
                     state.player_1.x + 25,
                     state.player_1.y + 60,
                     state.player_1_angle,
                     state.player_1_velocity)
        state.current_turn = :player_2
      elsif state.current_turn_input == :player_2_angle && parse_or_clear!(:player_2_angle)
        state.current_turn_input = :player_2_velocity
      elsif state.current_turn_input == :player_2_velocity && parse_or_clear!(:player_2_velocity)
        state.current_turn_input = :player_1_angle
        state.banana =
          new_banana(:player_2,
                     state.player_2.x + 25,
                     state.player_2.y + 60,
                     180 - state.player_2_angle,
                           state.player_2_velocity)
        state.current_turn = :player_1
      end

      if state.banana
        state.player_1_angle = nil
        state.player_1_velocity = nil
        state.player_2_angle = nil
        state.player_2_velocity = nil
      end
    end

    def random_building_size
      [state.building_heights.sample, state.building_room_sizes.sample]
    end

    def int? v
      v.to_i.to_s == v.to_s
    end

    def random_building_color
      [{ r: 99, g:   0, b: 107 },
       { r: 35, g:  64, b: 124 },
       { r: 35, g: 136, b: 162 }].sample
    end

    def random_window_color
      [{ r: 88,  g: 62,  b: 104 },
       { r: 253, g: 224, b: 187 }].sample
    end

    def windows_for_building starting_x, floors, rooms
      floors.-(1).combinations(rooms - 1).map do |floor, room|
        { x: starting_x + (state.building_room_width * room) + (state.building_room_spacing * (room + 1)),
          y: (state.building_room_height * floor) +
          (state.building_room_spacing * (floor + 1)),
          w: state.building_room_width,
          h: state.building_room_height,
          **random_window_color }
      end
    end

    def building_prefab starting_x, floors, rooms
      b = {}
      b.x      = starting_x
      b.y      = 0
      b.w      = (state.building_room_width * rooms) + (state.building_room_spacing * (rooms + 1))
      b.h      = (state.building_room_height * floors) + (state.building_room_spacing * (floors + 1))
      b.right  = b.x + b.w
      b.rect   = { x: b.x, y: b.y, w: b.w, h: b.h }
      b.prefab = [{ x: b.x - 1, y: b.y, w: b.w + 2, h: b.h + 1, **white_color },
                  { x: b.x, y: b.y, w: b.w, h: b.h, **random_building_color },
                  windows_for_building(b.x, floors, rooms)]
      b
    end

    def parse_or_clear! game_prop
      if int? state.as_hash[game_prop]
        state.as_hash[game_prop] = state.as_hash[game_prop].to_i
        return true
      end

      state.as_hash[game_prop] = nil
      return false
    end

    def new_banana owner, x, y, angle, velocity
      {
        owner: owner,
        x: x,
        y: y,
        angle: angle % 360,
        velocity: velocity / 5,
        dx: angle.vector_x(velocity / 5),
        dy: angle.vector_y(velocity / 5),
        created_at: Kernel.tick_count
      }
    end

    def white_color
      { r: 253, g: 252, b: 253 }
    end
  end

  def boot args
    args.state = {}
  end

  def tick args
    $game ||= YouSoBasicGorillas.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
  end

```

### Map Editor - camera.rb
```ruby
  # ./samples/99_genre_platformer/map_editor/app/camera.rb
  class Camera
    class << self
      def viewport_w
        Grid.allscreen_w
      end

      def viewport_h
        Grid.allscreen_h
      end

      def viewport_w_half
        if Grid.origin_center?
          0
        else
          Grid.allscreen_w.fdiv(2).ceil
        end
      end

      def viewport_h_half
        if Grid.origin_center?
          0
        else
          Grid.allscreen_h.fdiv(2).ceil
        end
      end

      def viewport_offset_x
        if Grid.origin_center?
          0
        else
          Grid.allscreen_x
        end
      end

      def viewport_offset_y
        if Grid.origin_center?
          0
        else
          Grid.allscreen_y
        end
      end

      def __to_world_space__ camera, rect
        return nil if !rect

        x = (rect.x - viewport_w_half + camera.x * camera.scale - viewport_offset_x) / camera.scale
        y = (rect.y - viewport_h_half + camera.y * camera.scale - viewport_offset_y) / camera.scale

        if rect.w
          w = rect.w / camera.scale
          h = rect.h / camera.scale
          { **rect, x: x, y: y, w: w, h: h }
        else
          { **rect, x: x, y: y }
        end
      end

      def to_world_space camera, rect
        if rect.is_a? Array
          rect.map { |r| to_world_space camera, r }
        else
          __to_world_space__ camera, rect
        end
      end

      def __to_screen_space__ camera, rect
        return nil if !rect

        x = rect.x * camera.scale - camera.x * camera.scale + viewport_w_half
        y = rect.y * camera.scale - camera.y * camera.scale + viewport_h_half

        if rect.w
          w = rect.w * camera.scale
          h = rect.h * camera.scale
          { **rect, x: x, y: y, w: w, h: h }
        else
          { **rect, x: x, y: y }
        end
      end

      def to_screen_space camera, rect
        if rect.is_a? Array
          rect.map { |r| to_screen_space camera, r }
        else
          __to_screen_space__ camera, rect
        end
      end

      def viewport
        if Grid.origin_center?
          {
            x: viewport_offset_x,
            y: viewport_offset_y,
            w: viewport_w,
            h: viewport_h,
            anchor_x: 0.5,
            anchor_y: 0.5
          }
        else
          {
            x: viewport_offset_x,
            y: viewport_offset_y,
            w: viewport_w,
            h: viewport_h,
          }
        end
      end

      def viewport_world camera
        to_world_space camera, viewport
      end

      def find_all_intersect_viewport camera, os
        Geometry.find_all_intersect_rect viewport_world(camera), os
      end
    end
  end

```

### Map Editor - level_editor.rb
```ruby
  # ./samples/99_genre_platformer/map_editor/app/level_editor.rb
  class LevelEditor
    attr_dr
    attr :mode, :hovered_tile, :selected_tile, :tilesheet_rect

    def initialize
      @tilesheet_rect = { x: 0, y: 0, w: 320, h: 320 }
      @tilesheet_metadata_has_collision_button_rect = Geometry.rect_props(x: 160, y: 320 + 8, w: 256, h: 32, anchor_x: 0.5, anchor_y: 0)
      @tilesheet_metadata = {}
      @mode = :add
    end

    def tick
      generate_tilesheet
      calc
      render
    end

    def calc
      if inputs.keyboard.x
        @mode = :remove
      else
        @mode = :add
      end

      if !@selected_tile
        @mode = :remove
      elsif @selected_tile.x_ordinal == 0 && @selected_tile.y_ordinal == 0
        @mode = :remove
      end

      if mouse.click && @selected_tile && mouse.intersect_rect?(@tilesheet_metadata_has_collision_button_rect)
        tile_id = @selected_tile.id
        @tilesheet_metadata[tile_id] ||= { has_collision: true }
        @tilesheet_metadata[tile_id].has_collision = !@tilesheet_metadata[tile_id].has_collision
        @selected_tile.has_collision = @tilesheet_metadata[tile_id].has_collision
      end

      if mouse.intersect_rect? @tilesheet_rect
        x_ordinal = mouse.x.idiv(16)
        y_ordinal = mouse.y.idiv(16)
        tile_id = "#{x_ordinal},#{y_ordinal}"
        @tilesheet_metadata[tile_id] ||= { has_collision: true }
        @hovered_tile = { id: "#{x_ordinal},#{y_ordinal}",
                          x_ordinal: mouse.x.idiv(16),
                          x: mouse.x.idiv(16) * 16,
                          y_ordinal: mouse.x.idiv(16),
                          y: mouse.y.idiv(16) * 16,
                          row: 20 - y_ordinal - 1,
                          col: x_ordinal,
                          path: tile_path(20 - y_ordinal - 1, x_ordinal, 20),
                          has_collision: @tilesheet_metadata[tile_id].has_collision,
                          w: 16,
                          h: 16 }
      else
        @hovered_tile = nil
      end

      if mouse.click && @hovered_tile
        @selected_tile = @hovered_tile
      end

      world_mouse = Camera.to_world_space state.camera, inputs.mouse.rect
      ifloor_x = world_mouse.x.ifloor(16)
      ifloor_y = world_mouse.y.ifloor(16)

      @mouse_world_rect =  { x: ifloor_x,
                             y: ifloor_y,
                             w: 16,
                             h: 16 }

      if @selected_tile
        ifloor_x = world_mouse.x.ifloor(16)
        ifloor_y = world_mouse.y.ifloor(16)
        @selected_tile.x = @mouse_world_rect.x
        @selected_tile.y = @mouse_world_rect.y
      end

      if !Geometry.intersect_rect?(mouse.rect, @tilesheet_rect) && !Geometry.intersect_rect?(mouse.rect, @tilesheet_metadata_has_collision_button_rect)
        if @mode == :remove && (mouse.click || (mouse.held && mouse.moved))
          state.terrain.reject! { |t| t.intersect_rect? @mouse_world_rect }
          save_terrain args
        elsif @selected_tile && (mouse.click || (mouse.held && mouse.moved))
          if @mode == :add
            state.terrain.reject! { |t| t.intersect_rect? @selected_tile }
            state.terrain << @selected_tile.copy
          else
            state.terrain.reject! { |t| t.intersect_rect? @selected_tile }
          end
          save_terrain args
        end
      end
    end

    def render
      outputs.sprites << { **@tilesheet_rect, path: :tilesheet }

      if @hovered_tile
        outputs.sprites << { x: @hovered_tile.x,
                             y: @hovered_tile.y,
                             w: 16,
                             h: 16,
                             path: :pixel,
                             r: 255, g: 0, b: 0, a: 128 }
      end

      if @selected_tile
        if @mode == :remove
          outputs[:scene].sprites << (Camera.to_screen_space state.camera, @selected_tile).merge(path: :pixel, r: 255, g: 0, b: 0, a: 64)
        elsif @selected_tile
          outputs.primitives << tilesheet_metadata_has_collision_button_rect_prefab(@selected_tile)
          outputs[:scene].sprites << (Camera.to_screen_space state.camera, @selected_tile)
          outputs[:scene].sprites << (Camera.to_screen_space state.camera, @selected_tile).merge(path: :pixel, r: 0, g: 255, b: 255, a: 64)
        end
      end
    end

    def tilesheet_metadata_has_collision_button_rect_prefab tile
      has_collision = @tilesheet_metadata[tile.id]&.has_collision
      text = if has_collision
               "Collidable? Yes (click to toggle)"
             else
               "Collidable? No (click to toggle)"
             end
      [
        { **@tilesheet_metadata_has_collision_button_rect, path: :solid, r: 255, g: 255, b: 255 },
        { **@tilesheet_metadata_has_collision_button_rect.center, text: text, anchor_x: 0.5, anchor_y: 0.5, size_px: 16, r: 0, g: 0, b: 0 }
      ]
    end

    def generate_tilesheet
      return if Kernel.tick_count > 0
      results = []
      rows = 20
      cols = 20
      tile_size = 16
      height = rows * tile_size
      width = cols * tile_size
      rows.map_with_index do |row|
        cols.map_with_index do |col|
          results << {
            x: col * tile_size,
            y: height - row * tile_size - tile_size,
            w: tile_size,
            h: tile_size,
            path: tile_path(row, col, cols)
          }
        end
      end

      outputs[:tilesheet].w = width
      outputs[:tilesheet].h = height
      outputs[:tilesheet].sprites << { x: 0, y: 0, w: width, h: height, path: :pixel, r: 0, g: 0, b: 0 }
      outputs[:tilesheet].sprites << results
    end

    def mouse
      inputs.mouse
    end

    def tile_path row, col, cols
      file_name = (tile_index row, col, cols).to_s.rjust(4, "0")
      "sprites/1-bit-platformer/#{file_name}.png"
    end

    def tile_index row, col, cols
      row * cols + col
    end

    def save_terrain args
      contents = args.state.terrain.uniq.map do |terrain_element|
        "#{terrain_element.x.to_i},#{terrain_element.y.to_i},#{terrain_element.w.to_i},#{terrain_element.h.to_i},#{terrain_element.path},#{terrain_element.has_collision}"
      end
      File.write "data/terrain.txt", contents.join("\n")
    end

    def load_terrain args
      args.state.terrain = []
      contents = File.read("data/terrain.txt")
      return if !contents
      args.state.terrain = contents.lines.map do |line|
        l = line.strip
        if l.empty?
          nil
        else
          x, y, w, h, path, has_collision = l.split ","
          if has_collision.nil?
            has_collision = true
          else
            has_collision = has_collision == "true"
          end
          { x: x.to_f, y: y.to_f, w: w.to_f, h: h.to_f, path: path, has_collision: has_collision }
        end
      end.compact.to_a.uniq
    end
  end

```

### Map Editor - main.rb
```ruby
  # ./samples/99_genre_platformer/map_editor/app/main.rb
  require 'app/level_editor.rb'
  require 'app/root_scene.rb'
  require 'app/camera.rb'

  def tick args
    $root_scene ||= RootScene.new args
    $root_scene.args = args
    $root_scene.tick
  end

  def reset
    $root_scene = nil
  end

  DR.reset

```

### Map Editor - root_scene.rb
```ruby
  # ./samples/99_genre_platformer/map_editor/app/root_scene.rb
  class RootScene
    attr_dr

    attr :level_editor

    def initialize args
      @level_editor = LevelEditor.new
    end

    def tick
      args.outputs.background_color = [0, 0, 0]
      args.state.terrain ||= []
      @level_editor.load_terrain args if Kernel.tick_count == 0

      state.player ||= {
        x: 0,
        y: 750,
        w: 16,
        h: 16,
        dy: 0,
        dx: 0,
        on_ground: false,
        path: "sprites/1-bit-platformer/0280.png"
      }

      if inputs.keyboard.left
        player.dx = -3
      elsif inputs.keyboard.right
        player.dx = 3
      end

      if inputs.keyboard.key_down.space && player.on_ground
        player.dy = 10
        player.on_ground = false
      end

      if args.inputs.keyboard.key_down.equal_sign || args.inputs.keyboard.key_down.plus
        state.camera.target_scale += 0.25
      elsif args.inputs.keyboard.key_down.minus
        state.camera.target_scale -= 0.25
        state.camera.target_scale = 0.25 if state.camera.target_scale < 0.25
      elsif args.inputs.keyboard.zero
        state.camera.target_scale = 1
      end

      state.gravity ||= 0.25
      calc_camera
      calc_physics
      outputs[:scene].w = Camera.viewport_w
      outputs[:scene].h = Camera.viewport_h
      outputs[:scene].background_color = [0, 0, 0, 0]
      outputs[:scene].lines << { x: 0, y: 0, x2: Camera.viewport_w, y2: Camera.viewport_h, r: 255, g: 255, b: 255, a: 255 }
      outputs[:scene].lines << { x: 0, y: Camera.viewport_h, x2: Camera.viewport_w, y2: 0, r: 255, g: 255, b: 255, a: 255 }

      terrain_to_render = Camera.find_all_intersect_viewport(state.camera, state.terrain)
      outputs[:scene].sprites << terrain_to_render.map do |m|
        Camera.to_screen_space(state.camera, m)
      end

      outputs[:scene].sprites << player_prefab

      outputs.sprites << { **Camera.viewport, path: :scene }

      @level_editor.args = args
      @level_editor.tick

      outputs.labels << { x: 640,
                          y: 30.from_top,
                          anchor_x: 0.5,
                          text: "WASD: move around. SPACE: jump. +/-: Zoom in and out. MOUSE: select tile/edit map (hold X and CLICK to delete).",
                          r: 255,
                          g: 255,
                          b: 255 }
    end

    def calc_camera
      state.world_size ||= 1280

      if !state.camera
        state.camera = {
          x: 0,
          y: 0,
          target_x: 0,
          target_y: 0,
          target_scale: 2,
          scale: 1
        }
      end

      ease = 0.1
      state.camera.scale += (state.camera.target_scale - state.camera.scale) * ease
      state.camera.target_x = player.x
      state.camera.target_y = player.y

      state.camera.x += (state.camera.target_x - state.camera.x) * ease
      state.camera.y += (state.camera.target_y - state.camera.y) * ease
    end

    def calc_physics
      player.x += player.dx
      collision = state.terrain.find do |t|
        t.intersect_rect?(player) && t.has_collision
      end

      if collision
        if player.dx > 0
          player.x = collision.x - player.w
        else
          player.x = collision.x + collision.w
        end

        player.dx = 0
      end

      player.dx *= 0.8
      if player.dx.abs < 0.5
        player.dx = 0
      end

      player.y += player.dy
      player.on_ground = false

      collision = state.terrain.find do |t|
        t.intersect_rect?(player) && t.has_collision
      end

      if collision
        if player.dy > 0
          player.y = collision.y - player.h
        else
          player.y = collision.y + collision.h
          player.on_ground = true
        end
        player.dy = 0
      end

      player.dy -= state.gravity

      if (player.y + player.h) < -750
        player.y = 750
        player.dy = 0
      end
    end

    def player
      state.player
    end

    def player_prefab
      prefab = Camera.to_screen_space state.camera, (player.merge path: "sprites/1-bit-platformer/0280.png")

      if !player.on_ground
        prefab.merge! path: "sprites/1-bit-platformer/0284.png"
        if player.dx > 0
          prefab.merge! flip_horizontally: false
        elsif player.dx < 0
          prefab.merge! flip_horizontally: true
        end
      elsif player.dx > 0
        frame_index = 0.frame_index 3, 5, true
        prefab.merge! path: "sprites/1-bit-platformer/028#{frame_index + 1}.png"
      elsif player.dx < 0
        frame_index = 0.frame_index 3, 5, true
        prefab.merge! path: "sprites/1-bit-platformer/028#{frame_index + 1}.png", flip_horizontally: true
      end

      prefab
    end

    def camera
      state.camera
    end

    def should_update_matricies?
      player.dx != 0 || player.dy != 0
    end
  end

```

### Shadows - main.rb
```ruby
  # ./samples/99_genre_platformer/shadows/app/main.rb
  # demo gameplay here: https://youtu.be/wQknjYk_-dE
  # this is the core game class. the game is
  # pretty small so this is the only class that was created
  class Game
    # attr_dr is a ruby class macro (mixin) that
    # adds the .args, .inputs, .outputs, and .state
    # properties to a class
    attr_dr

    # this is the main tick method that
    # will be called every frame
    # the tick method is your standard game loop.
    # ie initialize game state, process input,
    #    perform simulation calculations, then render
    def tick
      defaults
      input
      calc
      render
    end

    # defaults method re-initializes the game to its
    # starting point if
    # 1. it hasn't already been initialized (state.clock is nil)
    # 2. or reinitializes the game if the player died (game_over)
    def defaults
      new_game if !state.clock || state.game_over == true
    end

    # this is where inputs are processed
    # we process inputs for the player via input_entity
    # and then process inputs for each enemy using the same
    # input_entity function
    def input
      input_entity player,
                   find_input_timeline(at: player.clock, key: :left_right),
                   find_input_timeline(at: player.clock, key: :space),
                   find_input_timeline(at: player.clock, key: :down)

      # an enemy could still be spawing
      shadows.find_all { |shadow| entity_active? shadow }
             .each do |shadow|
               input_entity shadow,
                            find_input_timeline(at: shadow.clock, key: :left_right),
                            find_input_timeline(at: shadow.clock, key: :space),
                            find_input_timeline(at: shadow.clock, key: :down)
               end
    end

    # this is the input_entity function that handles
    # the movement of the player (and the enemies)
    # it's essentially your state machine for player
    # movement
    def input_entity entity, left_right, jump, fall_through
      # guard clause that ignores input processing if
      # the entity is still spawning
      return if !entity_active? entity

      # increment the dx of the entity by the magnitude of
      # the left_right input value
      entity.dx += left_right

      # if the left_right input is zero...
      if left_right == 0
        # if the entity was originally running, then
        # set their "action" to standing
        # entity_set_action! updates the current action
        # of the entity and takes note of the frame that
        # the action occurred on
        if (entity.action == :running)
          entity_set_action! entity, :standing
        end
      elsif entity.left_right != left_right && (entity_on_platform? entity)
        # if the entity is on a platform, and their current
        # left right value is different, mark them as running
        # this is done because we want to reset the run animation
        # if they changed directions
        entity_set_action! entity, :running
      end

      # capture the left_right input so that it can be
      # consulted on the next frame
      entity.left_right = left_right

      # capture the direction the player is facing
      # (this is used to determine the horizontal flip of the
      # sprite
      entity.facing = if left_right == -1
                        :left
                      elsif left_right == 1
                        :right
                      else
                        entity.facing
                      end

      # if the fall_through (down) input was requested,
      # and if they are on a platform...
      if fall_through && (entity_on_platform? entity)
        entity.jumped_at      = 0
        # set their jump_down value (falling through a platform)
        entity.jumped_down_at = entity.clock
        # and increment the number of times they jumped
        # (entities get three jumps before needing to touch the ground again)
        entity.jump_count    += 1
      end

      # if the jump input was requested
      # and if they haven't reached their jump limit
      if jump && entity.jump_count < 3
        # update the player's current action to the
        # corresponding jump number (used for rendering
        # the different jump animations)
        if entity.jump_count == 0
          entity_set_action! entity, :first_jump
        elsif entity.jump_count == 1
          entity_set_action! entity, :midair_jump
        elsif entity.jump_count == 2
          entity_set_action! entity, :midair_jump
        end

        # set the entity's dy value and take note
        # of when jump occurred (also increment jump
        # count/eat one of their jumps)
        entity.dy             = entity.jump_power
        entity.jumped_at      = entity.clock
        entity.jumped_down_at = 0
        entity.jump_count    += 1
      end
    end

    # after inputs have been processed, we then
    # determine game over states, collision, win states
    # etc
    def calc
      # calculate the new values of the light meter
      # (if the light meter hits zero, it's game over)
      calc_light_meter

      # capture the actions that were taken this turn so
      # that they can be "replayed" for the enemies on future
      # ticks of the simulation
      calc_action_history

      # calculate collisions for the player
      calc_entity player

      # calculate collisions for the enemies
      calc_shadows

      # spawn a new light crystal
      calc_light_crystal

      # process "fire and forget" render queues
      # (eg particles and death animations)
      calc_render_queues

      # determine game over
      calc_game_over

      # increment the internal clocks for all entities
      # this internal clock is used to determine how
      # a player's past input is replayed. it's also
      # used to determine what animation frame the entity
      # should be performing when idle, running, and jumping
      calc_clock
    end

    # ease the light meters value up or down
    # every time the player captures a light crystal
    # the "target" light meter value is increased and
    # slowly spills over to the final light meter value
    # which is used to determine game over
    def calc_light_meter
      state.light_meter -= 1
      d = state.light_meter_queue * 0.1
      state.light_meter += d
      state.light_meter_queue -= d
    end

    def calc_action_history
      # keep track of the inputs the player has performed over time
      # as the inputs change for the player, mark the point in time
      # the specific input changed, and when the change occurred.
      # when enemies replay the player's actions, this history (along
      # with the enemy's interal clock) is consulted to determine
      # what action should be performed

      # the three possible input events are captured and marked
      # within the input timeline if/when the value changes

      # left right input events
      state.curr_left_right     = inputs.left_right
      if state.prev_left_right != state.curr_left_right
        state.input_timeline.unshift({ at: state.clock, k: :left_right, v: state.curr_left_right })
      end
      state.prev_left_right = state.curr_left_right

      # jump input events
      state.curr_space     = inputs.keyboard.key_down.space    ||
                             inputs.controller_one.key_down.a  ||
                             inputs.keyboard.key_down.up       ||
                             inputs.controller_one.key_down.b
      if state.prev_space != state.curr_space
        state.input_timeline.unshift({ at: state.clock, k: :space, v: state.curr_space })
      end
      state.prev_space = state.curr_space

      # jump down (fall through platform)
      state.curr_down     = inputs.keyboard.down || inputs.controller_one.down
      if state.prev_down != state.curr_down
        state.input_timeline.unshift({ at: state.clock, k: :down, v: state.curr_down })
      end
      state.prev_down = state.curr_down
    end

    def calc_entity entity
      # process entity collision/simulation
      calc_entity_rect entity

      # return if the entity is still spawning
      return if !entity_active? entity

      # calc collisions
      calc_entity_collision entity

      # update the state machine of the entity based on the
      # collision results
      calc_entity_action entity

      # calc actions the entity should take based on
      # input timeline
      calc_entity_movement entity
    end

    def calc_entity_rect entity
      # this function calculates the entity's new
      # collision rect, render rect, hurt box, etc
      entity.render_rect = { x: entity.x, y: entity.y, w: entity.w, h: entity.h }
      entity.rect = entity.render_rect.merge x: entity.render_rect.x + entity.render_rect.w * 0.33,
                                             w: entity.render_rect.w * 0.33
      entity.next_rect = entity.rect.merge x: entity.x + entity.dx,
                                           y: entity.y + entity.dy
      entity.prev_rect = entity.rect.merge x: entity.x - entity.dx,
                                           y: entity.y - entity.dy
      orientation_shift = 0

      if entity.facing == :right
        orientation_shift = entity.rect.w  / 2
      end

      entity.hurt_rect  = entity.rect.merge y: entity.rect.y + entity.h * 0.33,
                                            x: entity.rect.x - (entity.rect.w / 2) + orientation_shift,
                                            h: entity.rect.h * 0.33
    end

    def calc_entity_collision entity
      # run of the mill AABB collision
      calc_entity_below entity
      calc_entity_left entity
      calc_entity_right entity
    end

    def calc_entity_below entity
      # exit ground collision detection if they aren't falling
      return unless entity.dy < 0
      tiles_below = find_tiles { |t| t.rect.top <= entity.prev_rect.y }
      collision = find_collision tiles_below, (entity.rect.merge y: entity.next_rect.y)

      # exit ground collision detection if no ground was found
      return unless collision

      # determine if the entity is allowed to fall through the platform
      # (you can only fall through a platform if you've been standing on it for 8 frames)
      can_drop = true
      if entity.last_standing_at && (entity.clock - entity.last_standing_at) < 8
        can_drop = false
      end

      # if the entity is allowed to fall through the platform,
      # and the entity requested the action, then clip them through the platform
      if can_drop && entity.jumped_down_at.elapsed_time(entity.clock) < 10 && !collision.impassable
        if (entity_on_platform? entity) && can_drop
          entity.dy = -1
        end

        entity.jump_count = 1
      else
        entity.y  = collision.rect.y + collision.rect.h
        entity.dy = 0
        entity.jump_count = 0
      end
    end

    def calc_entity_left entity
      # collision detection left side of screen
      return unless entity.dx < 0
      return if entity.next_rect.x > 8 - 32
      entity.x  = 8 - 32
      entity.dx = 0
    end

    def calc_entity_right entity
      # collision detection right side of screen
      return unless entity.dx > 0
      return if (entity.next_rect.x + entity.rect.w) < (1280 - 8 - 32)
      entity.x  = (1280 - 8 - entity.rect.w - 32)
      entity.dx = 0
    end

    def calc_entity_action entity
      # update the state machine of the entity
      # based on where they ended up after physics calculations
      if entity.dy < 0
        # mark the entity as falling after the jump animation frames
        # have been processed
        if entity.action == :midair_jump
          if entity_action_complete? entity, state.midair_jump_duration
            entity_set_action! entity, :falling
          end
        else
          entity_set_action! entity, :falling
        end
      elsif entity.dy == 0 && !(entity_on_platform? entity)
        # if the entity's dy is zero, determine if they should
        # be marked as standing or running
        if entity.left_right == 0
          entity_set_action! entity, :standing
        else
          entity_set_action! entity, :running
        end
      end
    end

    def calc_entity_movement entity
      # increment x and y positions of the entity
      # based on dy and dx
      calc_entity_dy entity
      calc_entity_dx entity
    end

    def calc_entity_dx entity
      # horizontal movement application and friction
      entity.dx  = entity.dx.clamp(-5,  5)
      entity.dx *= 0.9
      entity.x  += entity.dx
    end

    def calc_entity_dy entity
      # vertical movement application and gravity
      entity.y  += entity.dy
      entity.dy += state.gravity
      entity.dy += entity.dy * state.drag ** 2 * -1
    end

    def calc_shadows
      # every 5 seconds, add a new shadow enemy/increase difficult
      add_shadow! if state.clock.zmod?(300)

      # for each shadow, perform a simulation calculation
      shadows.each do |shadow|
        calc_entity shadow

        # decrement the spawn countdown which is used to determine if
        # the enemy is finally active
        shadow.spawn_countdown -= 1 if shadow.spawn_countdown > 0
      end
    end

    def calc_light_crystal
      # determine if the player has intersected with a light crystal
      light_rect = state.light_crystal
      if player.hurt_rect.intersect_rect? light_rect
        # if they have then queue up the partical animation of the
        # light crystal being collected
        state.jitter_fade_out_render_queue << { x:    state.light_crystal.x,
                                                y:    state.light_crystal.y,
                                                w:    state.light_crystal.w,
                                                h:    state.light_crystal.h,
                                                a:    255,
                                                path: 'sprites/light.png' }

        # increment the light meter target value
        state.light_meter_queue += 600

        # spawn a new light cristal for the player to try to get
        state.light_crystal = new_light_crystal
      end
    end

    def calc_render_queues
      # render all the entries in the "fire and forget" render queues
      state.jitter_fade_out_render_queue.each do |s|
        new_w = s.w * 1.02 ** 5
        ds = new_w - s.w
        s.w = new_w
        s.h = new_w
        s.x -= ds / 2
        s.y -= ds / 2
        s.a = s.a * 0.97 ** 5
      end

      state.jitter_fade_out_render_queue.reject! { |s| s.a <= 1 }

      state.game_over_render_queue.each { |s| s.a = s.a * 0.95 }
      state.game_over_render_queue.reject! { |s| s.a <= 1 }
    end

    def calc_game_over
      # calcuate game over
      state.game_over = false

      # it's game over if the player intersects with any of the enemies
      state.game_over ||= shadows.find_all { |s| s.spawn_countdown <= 0 }
                                 .any? { |s| s.hurt_rect.intersect_rect? player.hurt_rect }

      # it's game over if the light_meter hits 0
      state.game_over ||= state.light_meter <= 1

      # debug to reset the game/prematurely
      if inputs.keyboard.key_down.r
        state.you_win = false
        state.game_over = true
      end

      # update game over states and win/loss
      if state.game_over
        state.you_win = false
        state.game_over = true
      end

      if state.light_meter >= 6000
        state.you_win = true
        state.game_over = true
      end

      # if it's a game over, fade out all current entities in play
      if state.game_over
        state.game_over_render_queue.concat shadows.map { |s| { **entity_prefab(s), a: 255 } }
        state.game_over_render_queue << { **entity_prefab(player), a: 255 }
        state.game_over_render_queue << state.light_crystal.merge(a: 255, path: 'sprites/light.png', b: 128)
      end
    end

    def calc_clock
      return if state.game_over
      state.clock += 1
      player.clock += 1
      shadows.each { |s| s.clock += 1 if entity_active? s }
    end

    def render
      # render the game
      render_stage
      render_light_meter
      render_instructions
      render_render_queues
      render_light_meter_warning
      render_light_crystal
      render_entities
    end

    def render_stage
      # the stage is a simple background
      outputs.background_color = [255, 255, 255]
      outputs.sprites << { x: 0,
                           y: 0,
                           w: 1280,
                           h: 720,
                           path: "sprites/stage.png",
                           a: 200 }
    end

    def render_light_meter
      # the light meter sprite is rendered across the top
      # how much of the light meter is light vs dark is based off
      # of what the current light meter value is (which increases
      # when a crystal is collected and decreses a little bit every
      # frame
      meter_perc = state.light_meter.fdiv(6000)
      light_w = (1280 * meter_perc)
      dark_w  = 1280 - light_w

      # once the light and dark partitions have been computed
      # render the meter sprite and clip its width (source_w)
      outputs.sprites << { x: 0,
                           y: 64.from_top,
                           w: light_w,
                           source_x: 0,
                           source_y: 0,
                           source_w: light_w,
                           source_h: 128,
                           h: 64,
                           path: 'sprites/meter-light.png' }

      outputs.sprites << { x: 1280 * meter_perc,
                           y: 64.from_top,
                           w: dark_w,
                           source_x: light_w,
                           source_y: 0,
                           source_w: dark_w,
                           source_h: 128,
                           h: 64,
                           path: 'sprites/meter-dark.png' }
    end

    def render_instructions
      outputs.labels << { x: 640,
                          y: 40,
                          text: '[left/right] to move, [up/space] to jump, [down] to drop through platform',
                          alignment_enum: 1 }

      if state.you_win
        outputs.labels << { x: 640,
                            y: 40.from_top,
                            text: 'You win!',
                            size_enum: -1,
                            alignment_enum: 1 }
      end
    end

    def render_render_queues
      outputs.sprites << state.jitter_fade_out_render_queue
      outputs.sprites << state.game_over_render_queue
    end

    def render_light_meter_warning
      return if state.light_meter >= 255

      # the screen starts to dim if they are close to having
      # a game over because of a depleated light meter
      outputs.primitives << { x: 0,
                              y: 0,
                              w: 1280,
                              h: 720,
                              a: 255 - state.light_meter,
                              path: :pixel,
                              r: 0,
                              g: 0,
                              b: 0 }

      outputs.primitives << { x: state.light_crystal.x - 32,
                              y: state.light_crystal.y - 32,
                              w: 128,
                              h: 128,
                              a: 255 - state.light_meter,
                              path: 'sprites/spotlight.png' }
    end

    def render_light_crystal
      jitter_sprite = { x: state.light_crystal.x + 5 * rand,
                        y: state.light_crystal.y + 5 * rand,
                        w: state.light_crystal.w + 5 * rand,
                        h: state.light_crystal.h + 5 * rand,
                        path: 'sprites/light.png' }
      outputs.primitives << jitter_sprite
    end

    def render_entities
      outputs.sprites << entity_prefab(player, r: 0, g: 0, b: 0)
      outputs.sprites << shadows.map { |shadow| entity_prefab shadow, g: 0, b: 0 }
    end

    def entity_prefab entity, r: 255, g: 255, b: 255;
      # this is essentially the entity "prefab"
      # the current action of the entity is consulted to
      # determine what sprite should be rendered
      # the action_at time is consulted to determine which frame
      # of the sprite animation should be presented
      a = 255

      if entity.activate_at
        activation_elapsed_time = entity.activate_at.elapsed_time(state.clock)
        if entity.activate_at > state.clock
          return { x: entity.initial_x + 5 * rand,
                   y: entity.initial_y + 5 * rand,
                   w: 64 + 5 * rand,
                   h: 64 + 5 * rand,
                   path: "sprites/light.png",
                   g: 0, b: 0,
                   a: 255 }
        elsif !entity.activated
          entity.activated = true
          state.jitter_fade_out_render_queue << { x: entity.initial_x + 5 * rand,
                                                  y: entity.initial_y + 5 * rand,
                                                  w: 86 + 5 * rand, h: 86 + 5 * rand,
                                                  path: "sprites/light.png",
                                                  g: 0, b: 0, a: 255 }
        end
      end

      # this is the render outputs for an entities action state machine
      if entity.action == :standing
        path = "sprites/player/stand.png"
      elsif entity.action == :running
        sprint_index = Numeric.frame_index start_at: entity.action_at,
                                           count: 4,
                                           hold_for: 8,
                                           repeat: true,
                                           tick_count: entity.clock
        path = "sprites/player/run-#{sprint_index}.png"
      elsif entity.action == :first_jump
        sprint_index = Numeric.frame_index start_at: entity.action_at,
                                           count: 2,
                                           hold_for: 8,
                                           repeat: false,
                                           tick_count: entity.clock
        path = "sprites/player/jump-#{sprint_index || 1}.png"
      elsif entity.action == :midair_jump
        sprint_index = Numeric.frame_index start_at: entity.action_at,
                                           count: state.midair_jump_frame_count,
                                           hold_for: state.midair_jump_hold_for,
                                           repeat: false,
                                           tick_count: entity.clock
        path = "sprites/player/midair-jump-#{sprint_index || 8}.png"
      elsif entity.action == :falling
        path = "sprites/player/falling.png"
      end

      entity.render_rect.merge path: path,
                               a: a,
                               r: r,
                               g: g,
                               b: b,
                               flip_horizontally: entity.facing == :left
    end

    def new_game
      state.clock                   = 0
      state.game_over               = false
      state.gravity                 = -0.4
      state.drag                    = 0.15

      state.activation_time         = 90
      state.light_meter             = 600
      state.light_meter_queue       = 0

      state.midair_jump_frame_count = 9
      state.midair_jump_hold_for    = 6
      state.midair_jump_duration    = state.midair_jump_frame_count * state.midair_jump_hold_for

      # hard coded collision tiles
      state.tiles                   = [
        { x: 0,                        y: 0,   w: 1280, h: 8,    path: :pixel, r: 0, g: 0, b: 0, impassable: true },
        { x: 0,                        y: 0,   w: 8,    h: 1500, path: :pixel, r: 0, g: 0, b: 0, impassable: true },
        { x: 1280 - 8,                 y: 0,   w: 8,    h: 1500, path: :pixel, r: 0, g: 0, b: 0, impassable: true },

        { x: 80 + 320 + 80,            y: 128, w: 320,  h: 8,    path: :pixel, r: 0, g: 0, b: 0 },
        { x: 80 + 320 + 80 + 320 + 80, y: 192, w: 320,  h: 8,    path: :pixel, r: 0, g: 0, b: 0 },

        { x: 160,                      y: 320, w: 400,  h: 8,    path: :pixel, r: 0, g: 0, b: 0 },
        { x: 160 + 400 + 160,          y: 400, w: 400,  h: 8,    path: :pixel, r: 0, g: 0, b: 0 },

        { x: 320,                      y: 600, w: 320,  h: 8,    path: :pixel, r: 0, g: 0, b: 0 },

        { x: 8,                        y: 500, w: 100,  h: 8,    path: :pixel, r: 0, g: 0, b: 0 },

        { x: 8,                        y: 60,  w: 100,  h: 8,    path: :pixel, r: 0, g: 0, b: 0 },
      ]

      state.player                = new_entity
      state.player.jump_count     = 1
      state.player.jumped_at      = state.player.clock
      state.player.jumped_down_at = 0

      state.shadows   = []

      state.input_timeline = [
        { at: 0, k: :left_right, v: inputs.left_right },
        { at: 0, k: :space,      v: false },
        { at: 0, k: :down,       v: false },
      ]

      state.jitter_fade_out_render_queue   = []
      state.game_over_render_queue       ||= []

      state.light_crystal = new_light_crystal
    end

    def new_light_crystal
      r = { x: 124 + rand(1000), y: 135 + rand(500), w: 64, h: 64 }
      return new_light_crystal if tiles.any? { |t| t.intersect_rect? r }
      return new_light_crystal if (player.x - r.x).abs < 200
      r
    end

    def entity_active? entity
      return true unless entity.activate_at
      return entity.activate_at <= state.clock
    end

    def add_shadow!
      s = new_entity(from_entity: player)
      s.activate_at = state.clock + state.activation_time * (shadows.length + 1)
      s.spawn_countdown = state.activation_time
      shadows << s
    end

    def find_input_timeline at:, key:;
      state.input_timeline.find { |t| t.at <= at && t.k == key }.v
    end

  def new_entity from_entity: nil
    # these are all the properties of an entity
    # an optional from_entity can be passed in
    # for "cloning" an entity/setting an entities
    # starting state
    pe = { type: :body,
           w: 96,
           h: 96,
           jump_power: 12,
           y: 500,
           x: 640 - 8,
           dy: 0,
           dx: 0,
           jumped_down_at: 0,
           jumped_at: 0,
           jump_count: 0,
           clock: state.clock,
           orientation: :right,
           action: :falling,
           action_at: state.clock,
           left_right: 0 }

      if from_entity
        pe.w              = from_entity.w
        pe.h              = from_entity.h
        pe.jump_power     = from_entity.jump_power
        pe.x              = from_entity.x
        pe.y              = from_entity.y
        pe.initial_x      = from_entity.x
        pe.initial_y      = from_entity.y
        pe.dy             = from_entity.dy
        pe.dx             = from_entity.dx
        pe.jumped_down_at = from_entity.jumped_down_at
        pe.jumped_at      = from_entity.jumped_at
        pe.orientation    = from_entity.orientation
        pe.action         = from_entity.action
        pe.action_at      = from_entity.action_at
        pe.jump_count     = from_entity.jump_count
        pe.left_right     = from_entity.left_right
      end
      pe
    end

    def entity_on_platform? entity
      entity.action == :standing || entity.action == :running
    end

    def entity_action_complete? entity, action_duration
      entity.action_at.elapsed_time(entity.clock) + 1 >= action_duration
    end

    def entity_set_action! entity, action
      entity.action = action
      entity.action_at = entity.clock
      entity.last_standing_at = entity.clock if action == :standing
    end

    def player
      state.player
    end

    def shadows
      state.shadows
    end

    def tiles
      state.tiles
    end

    def find_tiles &block
      tiles.find_all(&block)
    end

    def find_collision tiles, target
      tiles.find { |t| t.rect.intersect_rect? target }
    end
  end

  def boot args
    # initialize state to an empty Hash on boot
    args.state = {}
  end

  def tick args
    # tick the game class after setting .args
    # (which is provided by the engine)
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  # debug function for resetting the game if requested
  def reset args
    $game = nil
  end

  DR.reset_and_replay "replay.txt", speed: 1

```

### The Little Probe - main.rb
```ruby
  # ./samples/99_genre_platformer/the_little_probe/app/main.rb
  class FallingCircle
    attr_dr

    def tick
      fiddle
      defaults
      render
      input
      calc
    end

    def fiddle
      state.gravity     = -0.02
      circle.radius     = 15
      circle.elasticity = 0.4
      camera.follow_speed = 0.4 * 0.4
    end

    def render
      render_stage_editor
      render_debug
      render_game
    end

    def defaults
      # if Kernel.tick_count == 0
      #   args.audio[:bg] = { input: "sounds/bg.ogg", looping: true }
      # end

      state.storyline ||= [
        { text: "<- -> to aim, hold space to charge",                            distance_gate: 0 },
        { text: "the little probe - by @amirrajan, made with DragonRuby Game Toolkit", distance_gate: 0 },
        { text: "mission control, this is sasha. landing on europa successful.", distance_gate: 0 },
        { text: "operation \"find earth 2.0\", initiated at 8-29-2036 14:00.",   distance_gate: 0 },
        { text: "jupiter's sure is beautiful...",   distance_gate: 4000 },
        { text: "hmm, it seems there's some kind of anomoly in the sky",   distance_gate: 7000 },
        { text: "dancing lights, i'll call them whisps.",   distance_gate: 8000 },
        { text: "#todo... look i ran out of time -_-",   distance_gate: 9000 },
        { text: "there's never enough time",   distance_gate: 9000 },
        { text: "the game jam was fun though ^_^",   distance_gate: 10000 },
      ]

      load_level force: Kernel.tick_count == 0
      state.line_mode            ||= :terrain

      state.sound_index          ||= 1
      circle.potential_lift      ||= 0
      circle.angle               ||= 90
      circle.check_point_at      ||= -1000
      circle.game_over_at        ||= -1000
      circle.x                   ||= -485
      circle.y                   ||= 12226
      circle.check_point_x       ||= circle.x
      circle.check_point_y       ||= circle.y
      circle.dy                  ||= 0
      circle.dx                  ||= 0
      circle.previous_dy         ||= 0
      circle.previous_dx         ||= 0
      circle.angle               ||= 0
      circle.after_images        ||= []
      circle.terrains_to_monitor ||= {}
      circle.impact_history      ||= []

      camera.x                   ||= 0
      camera.y                   ||= 0
      camera.target_x            ||= 0
      camera.target_y            ||= 0
      state.snaps                ||= { }
      state.snap_number            = 10

      args.state.storyline_x ||= -1000
      args.state.storyline_y ||= -1000
    end

    def render_game
      outputs.background_color = [0, 0, 0]
      outputs.sprites << { x: -circle.x + 1100,
                           y: -circle.y - 100,
                           w: 2416 * 4,
                           h: 3574 * 4,
                           path: 'sprites/jupiter.png' }
      outputs.sprites << { x: -circle.x,
                           y: -circle.y,
                           w: 2416 * 4,
                           h: 3574 * 4,
                           path: 'sprites/level.png' }
      outputs.sprites << state.whisp_queue
      render_aiming_retical
      render_circle
      render_notification
    end

    def render_notification
      toast_length = 500
      if circle.game_over_at.elapsed_time < toast_length
        label_text = "..."
      elsif circle.check_point_at.elapsed_time > toast_length
        args.state.current_storyline = nil
        return
      end
      if circle.check_point_at &&
         circle.check_point_at.elapsed_time == 1 &&
         !args.state.current_storyline
         if args.state.storyline.length > 0 && args.state.distance_traveled > args.state.storyline[0][:distance_gate]
           args.state.current_storyline = args.state.storyline.shift[:text]
           args.state.distance_traveled ||= 0
           args.state.storyline_x = circle.x
           args.state.storyline_y = circle.y
         end
        return unless args.state.current_storyline
      end
      label_text = args.state.current_storyline
      return unless label_text
      x = circle.x + camera.x
      y = circle.y + camera.y - 40
      w = 900
      h = 30
      outputs.primitives << { x: x - w.idiv(2), y: y - h, w: w, h: h, r: 255, g: 255, b: 255, a: 255, primitive_marker: :solid }
      outputs.primitives << { x: x - w.idiv(2), y: y - h, w: w, h: h, r: 0, g: 0, b: 0, a: 255, primitive_marker: :border }
      outputs.labels << { x: x, y: y - 4, text: label_text, size_enum: 1, alignment_enum: 1, r: 0, g: 0, b: 0, a: 255 }
    end

    def render_aiming_retical
      outputs.sprites << { x: state.camera.x + circle.x + circle.angle.vector_x(circle.potential_lift * 10) - 5,
                           y: state.camera.y + circle.y + circle.angle.vector_y(circle.potential_lift * 10) - 5,
                           w: 10, h: 10, path: 'sprites/circle-orange.png' }
      outputs.sprites << { x: state.camera.x + circle.x + circle.angle.vector_x(circle.radius * 3) - 5,
                           y: state.camera.y + circle.y + circle.angle.vector_y(circle.radius * 3) - 5,
                           w: 10, h: 10, path: 'sprites/circle-orange.png', angle: 0, a: 128 }
      if rand > 0.9
        outputs.sprites << { x: state.camera.x + circle.x + circle.angle.vector_x(circle.radius * 3) - 5,
                             y: state.camera.y + circle.y + circle.angle.vector_y(circle.radius * 3) - 5,
                             w: 10, h: 10, path: 'sprites/circle-white.png', angle: 0, a: 128 }
      end
    end

    def render_circle
      outputs.sprites << circle.after_images.map do |ai|
        ai.merge(x: ai.x + state.camera.x - circle.radius,
                 y: ai.y + state.camera.y - circle.radius,
                 w: circle.radius * 2,
                 h: circle.radius * 2,
                 path: 'sprites/circle-white.png')
      end

      outputs.sprites << { x: (circle.x - circle.radius) + state.camera.x,
                           y: (circle.y - circle.radius) + state.camera.y,
                           w: circle.radius * 2,
                           h: circle.radius * 2,
                           path: 'sprites/probe.png' }
    end

    def render_debug
      return unless state.debug_mode

      outputs.labels << { x: 10, y: 30, text: state.line_mode, size_enum: 0, alignment_enum: 0, r: 0, g: 0, b: 0 }
      outputs.labels << { x: 12, y: 32, text: state.line_mode, size_enum: 0, alignment_enum: 0, r: 255, g: 255, b: 255 }

      args.outputs.lines << trajectory(circle).to_line.to_hash.tap do |h|
        h[:x] += state.camera.x
        h[:y] += state.camera.y
        h[:x2] += state.camera.x
        h[:y2] += state.camera.y
      end

      outputs.primitives << state.terrain.find_all do |t|
        circle.x.between?(t.x - 640, t.x2 + 640) || circle.y.between?(t.y - 360, t.y2 + 360)
      end.map do |t|
        [
          t.to_line.merge(r: 0, g: 255, b: 0).then do |h|
            h.x  += state.camera.x
            h.y  += state.camera.y
            h.x2 += state.camera.x
            h.y2 += state.camera.y
            if circle.rect.intersect_rect? t[:rect]
              h[:r] = 255
              h[:g] = 0
            end
            h
          end,
          t[:rect].to_border.merge(r: 255, g: 0, b: 0).then do |h|
            h.x += state.camera.x
            h.y += state.camera.y
            h.b = 255 if line_near_rect? circle.rect, t
            h
          end
        ]
      end

      outputs.primitives << state.lava.find_all do |t|
        circle.x.between?(t.x - 640, t.x2 + 640) || circle.y.between?(t.y - 360, t.y2 + 360)
      end.map do |t|
        [
          t.to_line.merge(r: 0, g: 0, b: 255).then do |h|
            h.x  += state.camera.x
            h.y  += state.camera.y
            h.x2 += state.camera.x
            h.y2 += state.camera.y
            if circle.rect.intersect_rect? t[:rect]
              h[:r] = 255
              h[:b] = 0
            end
            h
          end,
          t[:rect].to_border.merge(r: 255, g: 0, b: 0).then do |h|
            h.x += state.camera.x
            h.y += state.camera.y
            h.b = 255 if line_near_rect? circle.rect, t
            h
          end
        ]
      end

      if state.god_mode
        border = circle.rect.merge(x: circle.rect.x + state.camera.x,
                                   y: circle.rect.y + state.camera.y,
                                   g: 255)
      else
        border = circle.rect.merge(x: circle.rect.x + state.camera.x,
                                   y: circle.rect.y + state.camera.y,
                                   b: 255)
      end

      outputs.borders << border

      overlapping ||= {}

      circle.impact_history.each do |h|
        label_mod = 300
        x = (h[:body][:x].-(150).idiv(label_mod)) * label_mod + camera.x
        y = (h[:body][:y].+(150).idiv(label_mod)) * label_mod + camera.y
        10.times do
          if overlapping[x] && overlapping[x][y]
            y -= 52
          else
            break
          end
        end

        overlapping[x] ||= {}
        overlapping[x][y] ||= true
        outputs.primitives << [x, y - 25, 300, 50, 0, 0, 0, 128].solid
        outputs.labels << [x + 10, y + 24, "dy: %.2f" % h[:body][:new_dy], -2, 0, 255, 255, 255]
        outputs.labels << [x + 10, y +  9, "dx: %.2f" % h[:body][:new_dx], -2, 0, 255, 255, 255]
        outputs.labels << [x + 10, y -  5, " ?: #{h[:body][:new_reason]}", -2, 0, 255, 255, 255]

        outputs.labels << [x + 100, y + 24, "angle: %.2f" % h[:impact][:angle], -2, 0, 255, 255, 255]
        outputs.labels << [x + 100, y + 9, "m(l): %.2f" % h[:terrain][:slope], -2, 0, 255, 255, 255]
        outputs.labels << [x + 100, y - 5, "m(c): %.2f" % h[:body][:slope], -2, 0, 255, 255, 255]

        outputs.labels << [x + 200, y + 24, "ray: #{h[:impact][:ray]}", -2, 0, 255, 255, 255]
        outputs.labels << [x + 200, y +  9, "nxt: #{h[:impact][:ray_next]}", -2, 0, 255, 255, 255]
        outputs.labels << [x + 200, y -  5, "typ: #{h[:impact][:type]}", -2, 0, 255, 255, 255]
      end

      if circle.floor
        outputs.labels << [circle.x + camera.x + 30, circle.y + camera.y + 100, "point: #{circle.floor_point.slice(:x, :y).values}", -2, 0]
        outputs.labels << [circle.x + camera.x + 31, circle.y + camera.y + 101, "point: #{circle.floor_point.slice(:x, :y).values}", -2, 0, 255, 255, 255]
        outputs.labels << [circle.x + camera.x + 30, circle.y + camera.y +  85, "circle: #{circle.as_hash.slice(:x, :y).values}", -2, 0]
        outputs.labels << [circle.x + camera.x + 31, circle.y + camera.y +  86, "circle: #{circle.as_hash.slice(:x, :y).values}", -2, 0, 255, 255, 255]
        outputs.labels << [circle.x + camera.x + 30, circle.y + camera.y +  70, "rel: #{circle.floor_relative_x} #{circle.floor_relative_y}", -2, 0]
        outputs.labels << [circle.x + camera.x + 31, circle.y + camera.y +  71, "rel: #{circle.floor_relative_x} #{circle.floor_relative_y}", -2, 0, 255, 255, 255]
      end
    end

    def render_stage_editor
      return unless state.god_mode
      return unless state.point_one
      args.lines << [state.point_one, inputs.mouse.point, 0, 255, 255]
    end

    def trajectory body
      { x: body.x + body.dx,
        y: body.y + body.dy,
        x2: body.x + body.dx * 1000,
        y2: body.y + body.dy * 1000,
        r: 0, g: 255, b: 255 }
    end

    def rect_for_line line
      if line.x > line.x2
        x  = line.x2
        y  = line.y2
        x2 = line.x
        y2 = line.y
      else
        x  = line.x
        y  = line.y
        x2 = line.x2
        y2 = line.y2
      end

      w = x2 - x
      h = y2 - y

      if h < 0
        y += h
        h = h.abs
      end

      if w < circle.radius
        x -= circle.radius
        w = circle.radius * 2
      end

      if h < circle.radius
        y -= circle.radius
        h = circle.radius * 2
      end

      { x: x, y: y, w: w, h: h }
    end

    def snap_to_grid x, y, snaps
      snap_number = 10
      x = x.to_i
      y = y.to_i

      x_floor = x.idiv(snap_number) * snap_number
      x_mod   = x % snap_number
      x_ceil  = (x.idiv(snap_number) + 1) * snap_number

      y_floor = y.idiv(snap_number) * snap_number
      y_mod   = y % snap_number
      y_ceil  = (y.idiv(snap_number) + 1) * snap_number

      if snaps[x_floor]
        x_result = x_floor
      elsif snaps[x_ceil]
        x_result = x_ceil
      elsif x_mod < snap_number.idiv(2)
        x_result = x_floor
      else
        x_result = x_ceil
      end

      snaps[x_result] ||= {}

      if snaps[x_result][y_floor]
        y_result = y_floor
      elsif snaps[x_result][y_ceil]
        y_result = y_ceil
      elsif y_mod < snap_number.idiv(2)
        y_result = y_floor
      else
        y_result = y_ceil
      end

      snaps[x_result][y_result] = true
      return [x_result, y_result]

    end

    def snap_line line
      x, y, x2, y2 = line
    end

    def string_to_line s
      x, y, x2, y2 = s.split(',').map(&:to_f)

      if x > x2
        x2, x = x, x2
        y2, y = y, y2
      end

      x, y = snap_to_grid x, y, state.snaps
      x2, y2 = snap_to_grid x2, y2, state.snaps
      [x, y, x2, y2].line.to_hash
    end

    def load_lines file
      return unless state.snaps
      data = gtk.read_file(file) || ""
      data.each_line
          .reject { |l| l.strip.length == 0 }
          .map { |l| string_to_line l }
          .map { |h| h.merge(rect: rect_for_line(h))  }
    end

    def load_terrain
      load_lines 'data/level.txt'
    end

    def load_lava
      load_lines 'data/level_lava.txt'
    end

    def load_level force: false
      if force
        state.snaps = {}
        state.terrain = load_terrain
        state.lava = load_lava
      else
        state.terrain ||= load_terrain
        state.lava ||= load_lava
      end
    end

    def save_lines lines, file
      s = lines.map do |l|
        "#{l.x},#{l.y},#{l.x2},#{l.y2}"
      end.join("\n")
      gtk.write_file(file, s)
    end

    def save_level
      save_lines(state.terrain, 'level.txt')
      save_lines(state.lava, 'level_lava.txt')
      load_level force: true
    end

    def line_near_rect? rect, terrain
      Geometry.intersect_rect?(rect, terrain[:rect])
    end

    def point_within_line? point, line
      return false if !point
      return false if !line
      return true
    end

    def calc_impacts x, dx, y, dy, radius
      results = { }
      results[:x] = x
      results[:y] = y
      results[:dx] = x
      results[:dy] = y
      results[:point] = { x: x, y: y }
      results[:rect] = { x: x - radius, y: y - radius, w: radius * 2, h: radius * 2 }
      results[:trajectory] = trajectory(results)
      results[:impacts] = terrain.find_all { |t| t && (line_near_rect? results[:rect], t) }.map do |t|
        intersection = Geometry.ray_intersect(results[:trajectory], t)
        {
          terrain: t,
          point: Geometry.ray_intersect(results[:trajectory], t),
          type: :terrain
        }
      end

      results[:impacts] += lava.find_all { |t| line_near_rect? results[:rect], t }.map do |t|
        intersection = Geometry.ray_intersect(results[:trajectory], t)
        {
          terrain: t,
          point: Geometry.ray_intersect(results[:trajectory], t),
          type: :lava
        }
      end

      results
    end

    def calc_potential_impacts
      impact_results = calc_impacts circle.x, circle.dx, circle.y, circle.dy, circle.radius
      circle.rect = impact_results[:rect]
      circle.trajectory = impact_results[:trajectory]
      circle.impacts = impact_results[:impacts]
    end

    def calc_terrains_to_monitor
      return unless circle.impacts
      circle.impact = nil
      circle.impacts.each do |i|
        future_circle = { x: circle.x + circle.dx, y: circle.y + circle.dy }
        circle.terrains_to_monitor[i[:terrain]] ||= {
          ray_start: Geometry.ray_test(future_circle, i[:terrain]),
        }

        circle.terrains_to_monitor[i[:terrain]][:ray_current] = Geometry.ray_test(future_circle, i[:terrain])
        if circle.terrains_to_monitor[i[:terrain]][:ray_start] != circle.terrains_to_monitor[i[:terrain]][:ray_current]
          circle.impact = i
          circle.ray_current = circle.terrains_to_monitor[i[:terrain]][:ray_current]
        end
      end
    end

    def impact_result body, impact
      infinity_alias = 1000
      r = {
        body: {},
        terrain: {},
        impact: {}
      }

      r[:body][:line] = body.trajectory.dup
      r[:body][:slope] = Geometry.line_slope(body.trajectory, replace_infinity: infinity_alias)
      r[:body][:slope_sign] = r[:body][:slope].sign
      r[:body][:x] = body.x
      r[:body][:y] = body.y
      r[:body][:dy] = body.dy
      r[:body][:dx] = body.dx

      r[:terrain][:line] = impact[:terrain].dup
      r[:terrain][:slope] = Geometry.line_slope(impact[:terrain], replace_infinity: infinity_alias)
      r[:terrain][:slope_sign] = r[:terrain][:slope].sign

      r[:impact][:angle] = -Geometry.angle_between_lines(body.trajectory, impact[:terrain], replace_infinity: infinity_alias)
      r[:impact][:point] = { x: impact[:point].x, y: impact[:point].y }
      r[:impact][:same_slope_sign] = r[:body][:slope_sign] == r[:terrain][:slope_sign]
      r[:impact][:ray] = body.ray_current
      r[:body][:new_on_floor] = body.on_floor
      r[:body][:new_floor] = r[:terrain][:line]

      if r[:impact][:angle].abs < 90 && r[:terrain][:slope].abs < 3
        play_sound
        r[:body][:new_dy] = r[:body][:dy] * circle.elasticity * -1
        r[:body][:new_dx] = r[:body][:dx] * circle.elasticity
        r[:impact][:type] = :horizontal
        r[:body][:new_reason] = "-"
      elsif r[:impact][:angle].abs < 90 && r[:terrain][:slope].abs > 3
        play_sound
        r[:body][:new_dy] = r[:body][:dy] * 1.1
        r[:body][:new_dx] = r[:body][:dx] * -circle.elasticity
        r[:impact][:type] = :vertical
        r[:body][:new_reason] = "|"
      else
        play_sound
        r[:body][:new_dx] = r[:body][:dx] * -circle.elasticity
        r[:body][:new_dy] = r[:body][:dy] * -circle.elasticity
        r[:impact][:type] = :slanted
        r[:body][:new_reason] = "/"
      end

      r[:impact][:energy] = r[:body][:new_dx].abs + r[:body][:new_dy].abs

      if r[:impact][:energy] <= 0.3 && r[:terrain][:slope].abs < 4
        r[:body][:new_dx] = 0
        r[:body][:new_dy] = 0
        r[:impact][:energy] = 0
        r[:body][:new_on_floor] = true if r[:impact][:point].y < body.y
        r[:body][:new_floor] = r[:terrain][:line]
        r[:body][:new_reason] = "0"
      end

      r[:impact][:ray_next] = Geometry.ray_test({ x: r[:body][:x] - (r[:body][:dx] * 1.1) + r[:body][:new_dx],
                                                  y: r[:body][:y] - (r[:body][:dy] * 1.1) + r[:body][:new_dy] + state.gravity },
                                                r[:terrain][:line])

      if r[:impact][:ray_next] == r[:impact][:ray]
        r[:body][:new_dx] *= -1
        r[:body][:new_dy] *= -1
        r[:body][:new_reason] = "clip"
      end

      r
    end

    def game_over!
      circle.x = circle.check_point_x
      circle.y = circle.check_point_y
      circle.dx = 0
      circle.dy = 0
      circle.game_over_at = Kernel.tick_count
    end

    def not_game_over!
      impact_history_entry = impact_result circle, circle.impact
      circle.impact_history << impact_history_entry
      circle.x -= circle.dx * 1.1
      circle.y -= circle.dy * 1.1
      circle.dx = impact_history_entry[:body][:new_dx]
      circle.dy = impact_history_entry[:body][:new_dy]
      circle.on_floor = impact_history_entry[:body][:new_on_floor]

      if circle.on_floor
        circle.check_point_at = Kernel.tick_count
        circle.check_point_x = circle.x
        circle.check_point_y = circle.y
      end

      circle.previous_floor = circle.floor || {}
      circle.floor = impact_history_entry[:body][:new_floor] || {}
      circle.floor_point = impact_history_entry[:impact][:point]
      if circle.floor.slice(:x, :y, :x2, :y2) != circle.previous_floor.slice(:x, :y, :x2, :y2)
        new_relative_x = if circle.dx > 0
                           :right
                         elsif circle.dx < 0
                           :left
                         else
                           nil
                         end

        new_relative_y = if circle.dy > 0
                           :above
                         elsif circle.dy < 0
                           :below
                         else
                           nil
                         end

        circle.floor_relative_x = new_relative_x
        circle.floor_relative_y = new_relative_y
      end

      circle.impact = nil
      circle.terrains_to_monitor.clear
    end

    def calc_physics
      if args.state.god_mode
        calc_potential_impacts
        calc_terrains_to_monitor
        return
      end

      if circle.y < -700
        game_over
        return
      end

      return if state.game_over
      return if circle.on_floor
      circle.previous_dy = circle.dy
      circle.previous_dx = circle.dx
      circle.x  += circle.dx
      circle.y  += circle.dy
      args.state.distance_traveled ||= 0
      args.state.distance_traveled += circle.dx.abs + circle.dy.abs
      circle.dy += state.gravity
      calc_potential_impacts
      calc_terrains_to_monitor
      return unless circle.impact
      if circle.impact && circle.impact[:type] == :lava
        game_over!
      else
        not_game_over!
      end
    end

    def input_god_mode
      state.debug_mode = !state.debug_mode if inputs.keyboard.key_down.forward_slash

      # toggle god mode
      if inputs.keyboard.key_down.g
        state.god_mode = !state.god_mode
        state.potential_lift = 0
        circle.floor = nil
        circle.floor_point = nil
        circle.floor_relative_x = nil
        circle.floor_relative_y = nil
        circle.impact = nil
        circle.terrains_to_monitor.clear
        return
      end

      return unless state.god_mode

      circle.x = circle.x.to_i
      circle.y = circle.y.to_i

      # move god circle
      if inputs.keyboard.left || inputs.keyboard.a
        circle.x -= 20
      elsif inputs.keyboard.right || inputs.keyboard.d || inputs.keyboard.f
        circle.x += 20
      end

      if inputs.keyboard.up || inputs.keyboard.w
        circle.y += 20
      elsif inputs.keyboard.down || inputs.keyboard.s
        circle.y -= 20
      end

      # delete terrain
      if inputs.keyboard.key_down.x
        calc_terrains_to_monitor
        state.terrain = state.terrain.reject do |t|
          t[:rect].intersect_rect? circle.rect
        end

        state.lava = state.lava.reject do |t|
          t[:rect].intersect_rect? circle.rect
        end

        calc_potential_impacts
        save_level
      end

      # change terrain type
      if inputs.keyboard.key_down.l
        if state.line_mode == :terrain
          state.line_mode = :lava
        else
          state.line_mode = :terrain
        end
      end

      if inputs.mouse.click && !state.point_one
        state.point_one = inputs.mouse.click.point
      elsif inputs.mouse.click && state.point_one
        l = [*state.point_one, *inputs.mouse.click.point]
        l = [l.x  - state.camera.x,
             l.y  - state.camera.y,
             l.x2 - state.camera.x,
             l.y2 - state.camera.y].line.to_hash
        l[:rect] = rect_for_line l
        if state.line_mode == :terrain
          state.terrain << l
        else
          state.lava << l
        end
        save_level
        next_x = inputs.mouse.click.point.x - 640
        next_y = inputs.mouse.click.point.y - 360
        circle.x += next_x
        circle.y += next_y
        state.point_one = nil
      elsif inputs.keyboard.one
        state.point_one = [circle.x + camera.x, circle.y+ camera.y]
      end

      # cancel chain lines
      if inputs.keyboard.key_down.nine || inputs.keyboard.key_down.escape || inputs.keyboard.key_up.six || inputs.keyboard.key_up.one
        state.point_one = nil
      end
    end

    def play_sound
      return if state.sound_debounce > 0
      state.sound_debounce = 5
      # outputs.sounds << "sounds/03#{"%02d" % state.sound_index}.wav"
      state.sound_index += 1
      if state.sound_index > 21
        state.sound_index = 1
      end
    end

    def input_game
      if inputs.keyboard.down || inputs.keyboard.space
        circle.potential_lift += 0.03
        circle.potential_lift = circle.potential_lift.lesser(10)
      elsif inputs.keyboard.key_up.down || inputs.keyboard.key_up.space
        play_sound
        circle.dy += circle.angle.vector_y circle.potential_lift
        circle.dx += circle.angle.vector_x circle.potential_lift

        if circle.on_floor
          if circle.floor_relative_y == :above
            circle.y += circle.potential_lift.abs * 2
          elsif circle.floor_relative_y == :below
            circle.y -= circle.potential_lift.abs * 2
          end
        end

        circle.on_floor = false
        circle.potential_lift = 0
        circle.terrains_to_monitor.clear
        circle.impact_history.clear
        circle.impact = nil
        calc_physics
      end

      # aim probe
      if inputs.keyboard.right || inputs.keyboard.a
        circle.angle -= 2
      elsif inputs.keyboard.left || inputs.keyboard.d
        circle.angle += 2
      end
    end

    def input
      input_god_mode
      input_game
    end

    def calc_camera
      state.camera.target_x = 640 - circle.x
      state.camera.target_y = 360 - circle.y
      xdiff = state.camera.target_x - state.camera.x
      ydiff = state.camera.target_y - state.camera.y
      state.camera.x += xdiff * camera.follow_speed
      state.camera.y += ydiff * camera.follow_speed
    end

    def calc
      state.sound_debounce ||= 0
      state.sound_debounce -= 1
      state.sound_debounce = 0 if state.sound_debounce < 0
      if state.god_mode
        circle.dy *= 0.1
        circle.dx *= 0.1
      end
      calc_camera
      state.whisp_queue ||= []
      if Kernel.tick_count.mod_zero?(4)
        state.whisp_queue << {
          x: -300,
          y: 1400 * rand,
          speed: 2.randomize(:ratio) + 3,
          w: 20,
          h: 20, path: 'sprites/whisp.png',
          a: 0,
          created_at: Kernel.tick_count,
          angle: 0,
          r: 100,
          g: 128 + 128 * rand,
          b: 128 + 128 * rand
        }
      end

      state.whisp_queue.each do |w|
        w.x += w[:speed] * 2
        w.x -= circle.dx * 0.3
        w.y -= w[:speed]
        w.y -= circle.dy * 0.3
        w.angle += w[:speed]
        w.a = w[:created_at].ease(30) * 255
      end

      state.whisp_queue = state.whisp_queue.reject { |w| w[:x] > 1280 }

      if Kernel.tick_count.mod_zero?(2) && (circle.dx != 0 || circle.dy != 0)
        circle.after_images << {
          x: circle.x,
          y: circle.y,
          w: circle.radius,
          h: circle.radius,
          a: 255,
          created_at: Kernel.tick_count
        }
      end

      circle.after_images.each do |ai|
        ai.a = ai[:created_at].ease(10, :flip) * 255
      end

      circle.after_images = circle.after_images.reject { |ai| ai[:created_at].elapsed_time > 10 }
      calc_physics
    end

    def circle
      state.circle
    end

    def camera
      state.camera
    end

    def terrain
      state.terrain
    end

    def lava
      state.lava
    end
  end

  # DR.reset

  def tick args
    args.outputs.background_color = [0, 0, 0]
    if args.inputs.keyboard.r
      DR.reset
      return
    end
    # uncomment the line below to slow down the game so you
    # can see each tick as it passes
    # DR.slowmo! 30
    $game ||= FallingCircle.new
    $game.args = args
    $game.tick

    args.outputs.watch "native_scale: #{Grid.native_scale}"
    args.outputs.watch "render_scale: #{Grid.render_scale}"
    args.outputs.watch "texture_scale: #{Grid.texture_scale}"
    args.outputs.watch "texture_scale_enum: #{Grid.texture_scale_enum}"
  end

  def reset
    $game = nil
  end

```
