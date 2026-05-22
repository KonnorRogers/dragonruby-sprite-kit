### Bullet Heaven - main.rb
```ruby
  # ./samples/99_genre_arcade/bullet_heaven/app/main.rb
  class Game
    attr_dr

    def initialize
      @level_scene = LevelScene.new
      @shop_scene = ShopScene.new
    end

    def tick
      defaults
      current_scene.args = args
      current_scene.tick
      if state.next_scene
        state.scene = state.next_scene
        state.scene_at = Kernel.tick_count
        state.next_scene = nil
      end
    end

    def current_scene
      if state.scene == :level
        @level_scene
      elsif state.scene == :shop
        @shop_scene
      end
    end

    def defaults
      state.shield ||= 10
      state.assembly_points ||= 4
      state.scene ||= :level
      state.bullets ||= []
      state.enemies ||= []
      state.bullet_speed ||= 5
      state.turret_position ||= { x: 640, y: 0 }
      state.blaster_spread ||= 1
      state.blaster_rate ||= 60
      state.level ||= 1
      state.bullet_damage ||= 1
      state.enemy_spawn_rate ||= 120
      state.enemy_min_health ||= 1
      state.enemy_health_range ||= 2
      state.enemies_to_spawn ||= 5
      state.enemies_spawned ||= 0
      state.enemy_dy ||= -0.2
    end
  end

  class ShopScene
    attr_dr

    def activate
      state.module_selected = nil
      state.available_module_1 = :blaster_spread
      state.available_module_2 = :bullet_damage
      state.available_module_3 = if state.blaster_rate > 3
                                   :blaster_rate
                                 else
                                   nil
                                 end
    end

    def tick
      if state.scene_at == Kernel.tick_count - 1
        activate
      end

      state.next_wave_button ||= layout.rect(row: 0, col: 20, w: 4, h: 2)
      state.module_1_button  ||= layout.rect(row: 10, col: 0, w: 8, h: 2)
      state.module_2_button  ||= layout.rect(row: 10, col: 8, w: 8, h: 2)
      state.module_3_button  ||= layout.rect(row: 10, col: 16, w: 8, h: 2)

      calc
      render
    end

    def increase_difficulty_and_start_level
      state.next_scene = :level
      state.enemies_spawned = 0
      state.enemies = []
      state.level += 1
      state.enemy_spawn_rate = (state.enemy_spawn_rate * 0.95).to_i
      state.enemy_min_health = (state.enemy_min_health * 1.1).to_i + 1
      state.enemy_health_range = state.enemy_min_health * 2
      state.enemies_to_spawn = (state.enemies_to_spawn * 1.1).to_i + 2
      state.enemy_dy *= 1.05
    end

    def calc
      if state.module_selected
        if inputs.mouse.click && inputs.mouse.click.point.inside_rect?(state.next_wave_button)
          increase_difficulty_and_start_level
        end
      else
        if inputs.mouse.click && inputs.mouse.click.point.inside_rect?(state.module_1_button)
          perform_upgrade state.available_module_1
          state.available_module_1 = nil
          state.module_selected = true
        elsif inputs.mouse.click && inputs.mouse.click.point.inside_rect?(state.module_2_button)
          perform_upgrade state.available_module_2
          state.available_module_2 = nil
          state.module_selected = true
        elsif inputs.mouse.click && inputs.mouse.click.point.inside_rect?(state.module_3_button)
          perform_upgrade state.available_module_3
          state.available_module_3 = nil
          state.module_selected = true
        end
      end
    end

    def perform_upgrade module_name
      return if state.module_selected
      if module_name == :bullet_damage
        state.bullet_damage += 1
      elsif module_name == :blaster_rate
        state.blaster_rate = (state.blaster_rate * 0.85).to_i
        state.blaster_rate = 3 if state.blaster_rate < 3
      elsif module_name == :blaster_spread
        state.blaster_spread += 2
      else
        raise "perform_upgade: Unknown module: #{module_name}"
      end
    end

    def render
      outputs.background_color = [0, 0, 0]
      # outputs.primitives << layout.debug_primitives.map { |p| p.merge a: 80 }

      outputs.labels << layout.rect(row: 0, col: 11, w: 2, h: 1)
                              .center
                              .merge(text: "Select Upgrade", anchor_x: 0.5, anchor_y: 0.5, size_px: 50, r: 255, g: 255, b: 255)

      if state.module_selected
        outputs.primitives << button_prefab(state.next_wave_button, "Next Wave", a: 255)
      end

      a = if state.module_selected
            80
          else
            255
          end

      outputs.primitives << button_prefab(state.module_1_button, state.available_module_1, a: a)
      outputs.primitives << button_prefab(state.module_2_button, state.available_module_2, a: a)
      outputs.primitives << button_prefab(state.module_3_button, state.available_module_3, a: a)
    end

    def button_prefab rect, text, a: 255
      return nil if !text
      [
        rect.merge(path: :solid, r: 255, g: 255, b: 255, a: a),
        Geometry.center(rect).merge(text: text.gsub("_", " "), anchor_x: 0.5, anchor_y: 0.5, r: 0, g: 0, b: 0, size_px: rect.h.idiv(4))
      ]
    end
  end

  class LevelScene
    attr_dr

    def tick
      if inputs.keyboard.key_down.g
        state.enemies_spawned = state.enemies_to_spawn
        state.enemies = []
      elsif inputs.keyboard.key_down.forward_slash
        roll = rand
        if roll < 0.33
          state.bullet_damage += 1
          DR.notify_extended! message: "bullet damage increased: #{state.bullet_damage}", env: :prod
        elsif roll < 0.66
          if state.blaster_rate > 3
            state.blaster_rate = (state.blaster_rate * 0.85).to_i
            state.blaster_rate = 3 if state.blaster_rate < 3
            DR.notify_extended! message: "blaster rate upgraded: #{state.blaster_rate}", env: :prod
          else
            DR.notify_extended! message: "blaster rate already at fastest.", env: :prod
          end
        else
          state.blaster_spread += 2
          DR.notify_extended! message: "blaster spread increased: #{state.blaster_spread}", env: :prod
        end
      end

      calc
      render
    end

    def calc
      calc_bullets
      calc_enemies
      calc_bullet_hits
      calc_enemy_push_back
      calc_deaths
    end

    def calc_deaths
      state.enemies.reject! { |e| e.hp <= 0 }
      state.bullets.reject! { |b| b.dead_at }
    end

    def enemy_prefab enemy
      b = (enemy.hp / (state.enemy_min_health + state.enemy_health_range)) * 255
      [
        enemy.merge(path: :solid, r: 128, g: 0, b: b),
        Geometry.center(enemy).merge(text: enemy.hp, anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255, size_px: enemy.h * 0.5)
      ]
    end

    def render
      outputs.background_color = [0, 0, 0]
      level_completion_perc = (state.enemies_spawned - state.enemies.length).fdiv(state.enemies_to_spawn)
      outputs.primitives << { x: 30, y: 30.from_top, text: "Wave: #{state.level} (#{(level_completion_perc * 100).to_i}% complete)", r: 255, g: 255, b: 255 }
      outputs.primitives << { x: 30, y: 60.from_top, text: "Press G to skip to end of the current wave.", r: 255, g: 255, b: 255 }
      outputs.primitives << { x: 30, y: 90.from_top, text: "Press / to get a random upgrade immediately.", r: 255, g: 255, b: 255 }

      outputs.sprites << state.bullets.map do |b|
        b.merge w: 10, h: 10, path: :solid, r: 0, g: 255, b: 255
      end

      outputs.primitives << state.enemies.map { |e| enemy_prefab e }
    end

    def calc_bullets
      if Kernel.tick_count.zmod? state.blaster_rate
        bullet_count = state.blaster_spread
        min_degrees = state.blaster_spread.idiv(2) * -2
        bullet_count.times do |i|
          degree_offset = min_degrees + (i * 2)
          state.bullets << { x: 640,
                             y: 0,
                             dy: (attack_angle + degree_offset).vector_y * state.bullet_speed,
                             dx: (attack_angle + degree_offset).vector_x * state.bullet_speed }
        end
      end

      state.bullets.each do |b|
        b.x += b.dx
        b.y += b.dy
      end

      state.bullets.reject! { |b| b.y < 0 || b.y > 720 || b.x > 1280 || b.x < 0 }
    end

    def calc_enemies
      if Kernel.tick_count.zmod?(state.enemy_spawn_rate) && state.enemies_spawned < state.enemies_to_spawn
        state.enemies_spawned += 1
        x = rand(1280 - 96) + 48
        y = 720
        hp = state.enemy_min_health + rand(state.enemy_health_range)
        state.enemies << { x: x,
                           y: y,
                           w: 48,
                           h: 48,
                           push_back_x: 0,
                           push_back_y: 0,
                           spawn_at: Kernel.tick_count,
                           dy: state.enemy_dy,
                           start_hp: hp,
                           hp: hp }
      end

      state.enemies.each do |e|
        if e.y + e.h > 720
          e.y -= (((e.y + e.h) - 720) / e.h) * 10
        end

        e.y += e.dy

        if e.x < 0 && e.push_back_x < 0
          e.push_back_x = e.push_back_x.abs
        elsif (e.x + e.w) > 1280 && e.push_back_x > 0
          e.push_back_x = e.push_back_x.abs * -1
        end

        e.x += e.push_back_x
        e.y += e.push_back_y

        e.push_back_x *= 0.9
        e.push_back_y *= 0.9
      end

      state.enemies.reject! { |e| e.y < 0 }

      if state.enemies.empty? && state.enemies_spawned >= state.enemies_to_spawn
        state.next_scene = :shop
        state.bullets.clear
      end
    end

    def calc_bullet_hits
      state.bullets.each do |b|
        state.enemies.each do |e|
          if Geometry.intersect_rect? b.merge(w: 4, h: 4, anchor_x: 0.5, anchor_x: 0.5), e
            e.hp -= state.bullet_damage
            push_back_angle = Geometry.angle b, geometry.center(e)
            push_back_x = push_back_angle.vector_x * state.bullet_damage * 0.1
            push_back_y = push_back_angle.vector_y * state.bullet_damage * 0.1
            e.push_back_x += push_back_x
            e.push_back_y += push_back_y
            e.hit_at = Kernel.tick_count
            b.dead_at = Kernel.tick_count
          end
        end
      end
    end

    def calc_enemy_push_back
      state.enemies.sort_by { |e| -e.y }.each do |e|
        has_pushed_back = false
        other_enemies = Geometry.find_all_intersect_rect e, state.enemies
        other_enemies.each do |e2|
          next if e == e2
          push_back_angle = Geometry.angle geometry.center(e), geometry.center(e2)
          e2.push_back_x += (e.push_back_x).fdiv(other_enemies.length) * 0.7
          e2.push_back_y += (e.push_back_y).fdiv(other_enemies.length) * 0.7
          has_pushed_back = true
        end

        if has_pushed_back
          e.push_back_x *= 0.2
          e.push_back_y *= 0.2
        end
      end
    end

    def attack_angle
      Geometry.angle state.turret_position, inputs.mouse
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset
    $game = nil
  end

  DR.reset

```

### Bullet Hell - main.rb
```ruby
  # ./samples/99_genre_arcade/bullet_hell/app/main.rb
  def tick args
    args.state.base_columns   ||= 10.map { |n| 50 * n + 1280 / 2 - 5 * 50 + 5 }
    args.state.base_rows      ||= 5.map { |n| 50 * n + 720 - 5 * 50 }
    args.state.offset_columns = 10.map { |n| (n - 4.5) * Math.sin(Kernel.tick_count.to_radians) * 12 }
    args.state.offset_rows    = 5.map { 0 }
    args.state.columns        = 10.map { |i| args.state.base_columns[i] + args.state.offset_columns[i] }
    args.state.rows           = 5.map { |i| args.state.base_rows[i] + args.state.offset_rows[i] }
    args.state.explosions     ||= []
    args.state.enemies        ||= []
    args.state.score          ||= 0
    args.state.wave           ||= 0
    if args.state.enemies.empty?
      args.state.wave      += 1
      args.state.wave_root = Math.sqrt(args.state.wave)
      args.state.enemies   = make_enemies
    end
    args.state.player         ||= {x: 620, y: 80, w: 40, h: 40, path: 'sprites/circle-gray.png', angle: 90, cooldown: 0, alive: true}
    args.state.enemy_bullets  ||= []
    args.state.player_bullets ||= []
    args.state.lives          ||= 3
    args.state.missed_shots   ||= 0
    args.state.fired_shots    ||= 0

    update_explosions args
    update_enemy_positions args

    if args.inputs.left && args.state.player[:x] > (300 + 5)
      args.state.player[:x] -= 5
    end
    if args.inputs.right && args.state.player[:x] < (1280 - args.state.player[:w] - 300 - 5)
      args.state.player[:x] += 5
    end

    args.state.enemy_bullets.each do |bullet|
      bullet[:x] += bullet[:dx]
      bullet[:y] += bullet[:dy]
    end
    args.state.player_bullets.each do |bullet|
      bullet[:x] += bullet[:dx]
      bullet[:y] += bullet[:dy]
    end

    args.state.enemy_bullets  = args.state.enemy_bullets.find_all { |bullet| bullet[:y].between?(-16, 736) }
    args.state.player_bullets = args.state.player_bullets.find_all do |bullet|
      if bullet[:y].between?(-16, 736)
        true
      else
        args.state.missed_shots += 1
        false
      end
    end

    args.state.enemies = args.state.enemies.reject do |enemy|
      if args.state.player[:alive] && 1500 > (args.state.player[:x] - enemy[:x]) ** 2 + (args.state.player[:y] - enemy[:y]) ** 2
        args.state.explosions << {x: enemy[:x] + 4, y: enemy[:y] + 4, w: 32, h: 32, path: 'sprites/explosion-0.png', age: 0}
        args.state.explosions << {x: args.state.player[:x] + 4, y: args.state.player[:y] + 4, w: 32, h: 32, path: 'sprites/explosion-0.png', age: 0}
        args.state.player[:alive] = false
        true
      else
        false
      end
    end
    args.state.enemy_bullets.each do |bullet|
      if args.state.player[:alive] && 400 > (args.state.player[:x] - bullet[:x] + 12) ** 2 + (args.state.player[:y] - bullet[:y] + 12) ** 2
        args.state.explosions << {x: args.state.player[:x] + 4, y: args.state.player[:y] + 4, w: 32, h: 32, path: 'sprites/explosion-0.png', age: 0}
        args.state.player[:alive] = false
        bullet[:despawn]          = true
      end
    end
    args.state.enemies = args.state.enemies.reject do |enemy|
      args.state.player_bullets.any? do |bullet|
        if 400 > (enemy[:x] - bullet[:x] + 12) ** 2 + (enemy[:y] - bullet[:y] + 12) ** 2
          args.state.explosions << {x: enemy[:x] + 4, y: enemy[:y] + 4, w: 32, h: 32, path: 'sprites/explosion-0.png', age: 0}
          bullet[:despawn] = true
          args.state.score += 1000 * args.state.wave
          true
        else
          false
        end
      end
    end

    args.state.player_bullets = args.state.player_bullets.reject { |bullet| bullet[:despawn] }
    args.state.enemy_bullets  = args.state.enemy_bullets.reject { |bullet| bullet[:despawn] }

    args.state.player[:cooldown] -= 1
    if args.inputs.keyboard.key_held.space && args.state.player[:cooldown] <= 0 && args.state.player[:alive]
      args.state.player_bullets << {x: args.state.player[:x] + 12, y: args.state.player[:y] + 28, w: 16, h: 16, path: 'sprites/star.png', dx: 0, dy: 8}.sprite
      args.state.fired_shots       += 1
      args.state.player[:cooldown] = 10 + 20 / args.state.wave
    end
    args.state.enemies.each do |enemy|
      if Math.rand < 0.0005 + 0.0005 * args.state.wave && args.state.player[:alive] && enemy[:move_state] == :normal
        args.state.enemy_bullets << {x: enemy[:x] + 12, y: enemy[:y] - 8, w: 16, h: 16, path: 'sprites/star.png', dx: 0, dy: -3 - args.state.wave_root}.sprite
      end
    end

    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << args.state.enemies.map do |enemy|
      [enemy[:x], enemy[:y], 40, 40, enemy[:path], -90].sprite
    end
    args.outputs.primitives << args.state.player if args.state.player[:alive]
    args.outputs.primitives << args.state.explosions
    args.outputs.primitives << args.state.player_bullets
    args.outputs.primitives << args.state.enemy_bullets
    accuracy = args.state.fired_shots.zero? ? 1 : (args.state.fired_shots - args.state.missed_shots) / args.state.fired_shots
    args.outputs.primitives << [
      [0, 0, 300, 720, 96, 0, 0].solid,
      [1280 - 300, 0, 300, 720, 96, 0, 0].solid,
      [1280 - 290, 60, "Wave     #{args.state.wave}", 255, 255, 255].label,
      [1280 - 290, 40, "Accuracy #{(accuracy * 100).floor}%", 255, 255, 255].label,
      [1280 - 290, 20, "Score    #{(args.state.score * accuracy).floor}", 255, 255, 255].label,
    ]
    args.outputs.primitives << args.state.lives.map do |n|
      [1280 - 290 + 50 * n, 80, 40, 40, 'sprites/circle-gray.png', 90].sprite
    end
    #args.outputs.debug << DR.framerate_diagnostics_primitives

    if (!args.state.player[:alive]) && args.state.enemy_bullets.empty? && args.state.explosions.empty? && args.state.enemies.all? { |enemy| enemy[:move_state] == :normal }
      args.state.player[:alive] = true
      args.state.player[:x]     = 624
      args.state.player[:y]     = 80
      args.state.lives          -= 1
      if args.state.lives == -1
        args.state.clear!
      end
    end
  end

  def make_enemies
    enemies = []
    enemies += 10.map { |n| {x: Math.rand * 1280 * 2 - 640, y: Math.rand * 720 * 2 + 720, row: 0, col: n, path: 'sprites/circle-orange.png', move_state: :retreat} }
    enemies += 10.map { |n| {x: Math.rand * 1280 * 2 - 640, y: Math.rand * 720 * 2 + 720, row: 1, col: n, path: 'sprites/circle-orange.png', move_state: :retreat} }
    enemies += 8.map { |n| {x: Math.rand * 1280 * 2 - 640, y: Math.rand * 720 * 2 + 720, row: 2, col: n + 1, path: 'sprites/circle-blue.png', move_state: :retreat} }
    enemies += 8.map { |n| {x: Math.rand * 1280 * 2 - 640, y: Math.rand * 720 * 2 + 720, row: 3, col: n + 1, path: 'sprites/circle-blue.png', move_state: :retreat} }
    enemies += 4.map { |n| {x: Math.rand * 1280 * 2 - 640, y: Math.rand * 720 * 2 + 720, row: 4, col: n + 3, path: 'sprites/circle-green.png', move_state: :retreat} }
    enemies
  end

  def update_explosions args
    args.state.explosions.each do |explosion|
      explosion[:age]  += 0.5
      explosion[:path] = "sprites/explosion-#{explosion[:age].floor}.png"
    end
    args.state.explosions = args.state.explosions.reject { |explosion| explosion[:age] >= 7 }
  end

  def update_enemy_positions args
    args.state.enemies.each do |enemy|
      if enemy[:move_state] == :normal
        enemy[:x]          = args.state.columns[enemy[:col]]
        enemy[:y]          = args.state.rows[enemy[:row]]
        enemy[:move_state] = :dive if Math.rand < 0.0002 + 0.00005 * args.state.wave && args.state.player[:alive]
      elsif enemy[:move_state] == :dive
        enemy[:target_x] ||= args.state.player[:x]
        enemy[:target_y] ||= args.state.player[:y]
        dx               = enemy[:target_x] - enemy[:x]
        dy               = enemy[:target_y] - enemy[:y]
        vel              = Math.sqrt(dx * dx + dy * dy)
        speed_limit      = 2 + args.state.wave_root
        if vel > speed_limit
          dx /= vel / speed_limit
          dy /= vel / speed_limit
        end
        if vel < 1 || !args.state.player[:alive]
          enemy[:move_state] = :retreat
        end
        enemy[:x] += dx
        enemy[:y] += dy
      elsif enemy[:move_state] == :retreat
        enemy[:target_x] = args.state.columns[enemy[:col]]
        enemy[:target_y] = args.state.rows[enemy[:row]]
        dx               = enemy[:target_x] - enemy[:x]
        dy               = enemy[:target_y] - enemy[:y]
        vel              = Math.sqrt(dx * dx + dy * dy)
        speed_limit      = 2 + args.state.wave_root
        if vel > speed_limit
          dx /= vel / speed_limit
          dy /= vel / speed_limit
        elsif vel < 1
          enemy[:move_state] = :normal
          enemy[:target_x]   = nil
          enemy[:target_y]   = nil
        end
        enemy[:x] += dx
        enemy[:y] += dy
      end
    end
  end

```

### Bust-a-move - main.rb
```ruby
  # ./samples/99_genre_arcade/bust-a-move/app/main.rb
  class Game
    attr_dr

    attr :shooting_ball, :launch_angle

    def initialize
      @launch_angle = 90
      @aim_retical = new_ball
      @aim_retical.dx = @launch_angle.vector_x
      @aim_retical.dy = @launch_angle.vector_y
      @current_shot = new_ball
      @balls = []
      @snap_locations = 20.flat_map do |x|
        10.map do |y|
          offset = 32
          offset -= 32 if y.even?
          next if x * 64 + offset + 64 > 1280
          { x: x * 64 + offset, y: 720 - (y * 64), w: 64, h: 64 }
        end
      end.compact
    end

    def new_ball
      { x: 640 - 32, y: 0, w: 64, h: 64, dx: 0, dy: 0, speed: 15 }
    end

    def tick_ball ball
      ball.x += ball.dx * ball.speed

      if ball.x > 1280 - ball.w
        diff = ball.x - (1280 - ball.w)
        ball.dx *= -1
        ball.x = 1280 - ball.w
        ball.x += diff.abs * ball.dx.sign
      elsif ball.x < 0
        diff = ball.x
        ball.dx *= -1
        ball.x = 0
        ball.x += diff.abs * ball.dx.sign
      end

      ball.y += ball.dy * ball.speed
      if ball.y > 720 - ball.h
        ball.dy = 0
        ball.dx = 0
        ball.y = 720 - ball.h
      end
    end

    def find_ball_collision ball
      collision = @balls.find do |b|
        Geometry.intersect_rect?(ball, b) && Geometry.distance(ball, b) < 64
      end

      if collision
        find_snap_location ball
      else
        nil
      end
    end

    def find_snap_location ball
      @snap_locations.find_all do |loc|
        Geometry.intersect_rect?(ball, loc)
      end.sort_by do |loc|
        [Geometry.distance(ball, loc), loc[:y], -loc[:x]]
      end.first
    end

    def find_ceiling_collision ball
      if ball.y + ball.h >= 720
        find_snap_location ball
      else
        nil
      end
    end

    def find_collision ball
      find_ball_collision(ball) || find_ceiling_collision(ball)
    end

    def tick_current_shot
      tick_ball @current_shot
      collision = find_collision @current_shot

      if collision
        @current_shot.dx = 0
        @current_shot.dy = 0
        @current_shot.target_x = collision.x
        @current_shot.target_y = collision.y
        @balls << @current_shot
        @current_shot = new_ball
      end
    end

    def tick_aim_retical
      tick_ball @aim_retical

      collision_aim = find_collision @aim_retical

      if collision_aim
        @aim_retical = new_ball
        @aim_retical.dx = @launch_angle.cos
        @aim_retical.dy = @launch_angle.sin
      end
    end

    def tick
      if inputs.keyboard.key_down.j || inputs.keyboard.key_down.space
        vec = Geometry.angle_vector @launch_angle
        @current_shot.dx = vec.x
        @current_shot.dy = vec.y
      end

      if inputs.keyboard.l || inputs.keyboard.right
        @launch_angle -= 1
      elsif inputs.keyboard.h || inputs.keyboard.left
        @launch_angle += 1
      end

      @launch_angle = @launch_angle.clamp(10, 170)

      tick_current_shot
      tick_aim_retical

      @balls.each do |b|
        b.target_x ||= b.x
        b.target_y ||= b.y
        b.x = b.x.lerp(b.target_x, 0.8, tolerance: 1)
        b.y = b.y.lerp(b.target_y, 0.8, tolerance: 1)
      end

      outputs.sprites << {
        x: 640,
        y: 0,
        w: 128,
        h: 64,
        path: "sprites/square/blue.png",
        angle_anchor_x: 0,
        angle_anchor_y: 0.5,
        angle: @launch_angle
      }

      outputs.sprites << ball_prefab(@aim_retical).merge(a: 50)
      outputs.sprites << ball_prefab(@current_shot)
      outputs.sprites << @balls.map do |b|
        ball_prefab b
      end

      outputs.sprites << @snap_locations.map do |loc|
        {
          **loc,
          path: "sprites/square/white.png",
          a: 50
        }
      end

      trajectory = { x: 640, y: 32, x2: 640 + @launch_angle.cos * 1280, y2: 0 + @launch_angle.sin * 1280 }
      outputs.lines << trajectory
    end

    def ball_prefab ball
      {
        **ball,
        path: "sprites/circle/blue.png"
      }
    end
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

### Dueling Starships - main.rb
```ruby
  # ./samples/99_genre_arcade/dueling_starships/app/main.rb
  class DuelingSpaceships
    attr_dr

    def tick
      defaults
      render
      calc
      input
    end

    def defaults
      outputs.background_color = [0, 0, 0]
      state.ship_blue       ||= new_blue_ship
      state.ship_red        ||= new_red_ship
      state.flames          ||= []
      state.bullets         ||= []
      state.ship_blue_score ||= 0
      state.ship_red_score  ||= 0
      state.stars           ||= 100.map do
        (rand + 2).yield_self do |size|
          { x: grid.w_half.randomize(:sign, :ratio),
            y: grid.h_half.randomize(:sign, :ratio),
            w: size,
            h: size,
            r: 128 + 128 * rand,
            g: 255,
            b: 255,
            path: :solid }
        end
      end
    end

    def new_ship x:, y:, angle:, path:, bullet_path:, color:;
      { x: x, y: y, w: 66, h: 66,
        dy: 0, dx: 0,
        anchor_x: 0.5, anchor_y: 0.5,
        damage: 0,
        dead: false,
        angle: angle,
        a: 255,
        path: path,
        bullet_sprite_path: bullet_path,
        color: color,
        created_at: Kernel.tick_count,
        last_bullet_at: 0,
        fire_rate: 10 }
    end

    def new_red_ship
      new_ship x: 400,
               y: 250.randomize(:sign, :ratio),
               angle: 180, path: 'sprites/ship_red.png',
               bullet_path: 'sprites/red_bullet.png',
               color: { r: 255, g: 90, b: 90 }
    end

    def new_blue_ship
      new_ship x: -400,
               y: 250.randomize(:sign, :ratio),
               angle: 0,
               path: 'sprites/ship_blue.png',
               bullet_path: 'sprites/blue_bullet.png',
               color: { r: 110, g: 140, b: 255 }
    end

    def render
      render_instructions
      render_score
      render_universe
      render_flames
      render_ships
      render_bullets
    end

    def render_ships
      outputs.primitives << ship_prefab(state.ship_blue)
      outputs.primitives << ship_prefab(state.ship_red)
    end

    def render_instructions
      return if state.ship_blue.dx  > 0  || state.ship_blue.dy > 0  ||
                state.ship_red.dx   > 0  || state.ship_red.dy  > 0  ||
                state.flames.length > 0

      outputs.labels << { x: grid.left.shift_right(30),
                          y: grid.bottom.shift_up(30),
                          text: "Two gamepads needed to play. R1 to accelerate. Left and right on D-PAD to turn ship. Hold A to shoot. Press B to drop mines.",
                          r: 255, g: 255, b: 255 }
    end

    def calc
      calc_flames
      calc_ships
      calc_bullets
      calc_winner
    end

    def input
      input_accelerate
      input_turn
      input_bullets_and_mines
    end

    def render_score
      outputs.labels << { x: grid.left.shift_right(80),
                          y: grid.top.shift_down(40),
                          text: state.ship_blue_score,
                          size_enum: 30,
                          alignment_enum: 1, **state.ship_blue.color }

      outputs.labels << { x: grid.right.shift_left(80),
                          y: grid.top.shift_down(40),
                          text: state.ship_red_score,
                          size_enum: 30,
                          alignment_enum: 1, **state.ship_red.color }
    end

    def render_universe
      args.outputs.background_color = [0, 0, 0]
      outputs.sprites << state.stars
    end

    def apply_round_finished_alpha entity
      return entity unless state.round_finished_at
      entity.merge(a: (entity.a || 0) * state.round_finished_at.ease(2.seconds, :flip))
    end

    def ship_prefab ship
      [
        apply_round_finished_alpha(**ship,
                                   a: ship.dead ? 0 : 255 * ship.created_at.ease(2.seconds)),

        apply_round_finished_alpha(x: ship.x,
                                   y: ship.y + 100,
                                   text: "." * (5 - ship.damage.clamp(0, 5)),
                                   size_enum: 20,
                                   alignment_enum: 1,
                                   **ship.color)
      ]
    end

    def render_flames
      outputs.sprites << state.flames.map do |flame|
        apply_round_finished_alpha(flame.merge(a: 255 * flame.created_at.ease(flame.lifetime, :flip)))
      end
    end

    def render_bullets
      outputs.sprites << state.bullets.map do |b|
        apply_round_finished_alpha(b.merge(a: 255 * b.owner.created_at.ease(2.seconds)))
      end
    end

    def wrap_location! location
      location.merge! x: location.x.clamp_wrap(grid.left, grid.right),
                      y: location.y.clamp_wrap(grid.bottom, grid.top)
    end

    def calc_flames
      state.flames =
        state.flames
             .reject { |p| p.created_at.elapsed_time > p.lifetime }
             .map do |p|
               p.speed *= 0.9
               p.y += p.angle.vector_y(p.speed)
               p.x += p.angle.vector_x(p.speed)
               wrap_location! p
             end
    end

    def all_ships
      [state.ship_blue, state.ship_red]
    end

    def alive_ships
      all_ships.reject { |s| s.dead }
    end

    def calc_bullet bullet
      bullet.y += bullet.angle.vector_y(bullet.speed)
      bullet.x += bullet.angle.vector_x(bullet.speed)
      wrap_location! bullet
      explode_bullet! bullet, particle_count: 5 if bullet.created_at.elapsed_time > bullet.lifetime
      return if bullet.exploded
      return if state.round_finished
      alive_ships.each do |s|
        if s != bullet.owner && s.intersect_rect?(bullet)
          explode_bullet! bullet, particle_count: 10
          s.damage += 1
        end
      end
    end

    def calc_bullets
      state.bullets.each    { |b| calc_bullet b }
      state.bullets.reject! { |b| b.exploded }
    end

    def new_flame x:, y:, angle:, a:, lifetime:, speed:;
      { angle: angle,
        speed: speed,
        lifetime: lifetime,
        path: 'sprites/flame.png',
        x: x,
        y: y,
        w: 6,
        h: 6,
        anchor_x: 0.5,
        anchor_y: 0.5,
        created_at: Kernel.tick_count,
        a: a }
    end

    def create_explosion! source:, particle_count:, max_speed:, lifetime:;
      state.flames.concat(particle_count.map do
                            new_flame x: source.x,
                                      y: source.y,
                                      speed: max_speed * rand,
                                      angle: 360 * rand,
                                      lifetime: lifetime,
                                      a: source.a
                          end)
    end

    def explode_bullet! bullet, particle_count: 5
      bullet.exploded = true
      create_explosion! source: bullet,
                        particle_count: particle_count,
                        max_speed: 5,
                        lifetime: 10
    end

    def calc_ship ship
      ship.x += ship.dx
      ship.y += ship.dy
      wrap_location! ship
    end

    def calc_ships
      all_ships.each { |s| calc_ship s }
      return if all_ships.any? { |s| s.dead }
      return if state.round_finished
      return unless state.ship_blue.intersect_rect?(state.ship_red)
      state.ship_blue.damage = 5
      state.ship_red.damage  = 5
    end

    def create_thruster_flames! ship
      state.flames << new_flame(x: ship.x - ship.angle.vector_x(40) + 5.randomize(:sign, :ratio),
                                y: ship.y - ship.angle.vector_y(40) + 5.randomize(:sign, :ratio),
                                angle: ship.angle + 180 + 60.randomize(:sign, :ratio),
                                speed: 5.randomize(:ratio),
                                a: 255 * ship.created_at.elapsed_time.ease(2.seconds),
                                lifetime: 30)
    end

    def input_accelerate_ship should_move_ship, ship
      return if ship.dead

      should_move_ship &&= (ship.dx + ship.dy).abs < 5

      if should_move_ship
        create_thruster_flames! ship
        ship.dx += ship.angle.vector_x 0.050
        ship.dy += ship.angle.vector_y 0.050
      else
        ship.dx *= 0.99
        ship.dy *= 0.99
      end
    end

    def input_accelerate
      input_accelerate_ship inputs.controller_one.key_held.r1 || inputs.keyboard.up, state.ship_blue
      input_accelerate_ship inputs.controller_two.key_held.r1, state.ship_red
    end

    def input_turn_ship direction, ship
      ship.angle -= 3 * direction
    end

    def input_turn
      input_turn_ship inputs.controller_one.left_right + inputs.keyboard.left_right, state.ship_blue
      input_turn_ship inputs.controller_two.left_right, state.ship_red
    end

    def new_bullet x:, y:, ship:, angle:, speed:, lifetime:;
      { owner: ship,
        angle: angle,
        speed: speed,
        lifetime: lifetime,
        created_at: Kernel.tick_count,
        path: ship.bullet_sprite_path,
        anchor_x: 0.5,
        anchor_y: 0.5,
        w: 10,
        h: 10,
        x: x,
        y: y }
    end

    def input_bullet create_bullet, ship
      return unless create_bullet
      return if ship.dead
      return if ship.last_bullet_at.elapsed_time < ship.fire_rate

      ship.last_bullet_at = Kernel.tick_count

      state.bullets << new_bullet(x: ship.x + ship.angle.vector_x * 32,
                                  y: ship.y + ship.angle.vector_y * 32,
                                  ship: ship,
                                  angle: ship.angle,
                                  speed: 5 + ship.dx * ship.angle.vector_x + ship.dy * ship.angle.vector_y,
                                  lifetime: 120)
    end

    def input_mine create_mine, ship
      return unless create_mine
      return if ship.dead

      state.bullets << new_bullet(x: ship.x + ship.angle.vector_x * -50,
                                  y: ship.y + ship.angle.vector_y * -50,
                                  ship: ship,
                                  angle: 360.randomize(:sign, :ratio),
                                  speed: 0.02,
                                  lifetime: 600)
    end

    def input_bullets_and_mines
      return if state.bullets.length > 100

      input_bullet(inputs.controller_one.key_held.a || inputs.keyboard.key_held.space,
                   state.ship_blue)

      input_mine(inputs.controller_one.key_down.b || inputs.keyboard.key_down.down,
                 state.ship_blue)

      input_bullet(inputs.controller_two.key_held.a, state.ship_red)

      input_mine(inputs.controller_two.key_down.b, state.ship_red)
    end

    def calc_kill_ships
      alive_ships.find_all { |s| s.damage >= 5 }
                 .each do |s|
                   s.dead = true
                   create_explosion! source: s,
                                     particle_count: 20,
                                     max_speed: 20,
                                     lifetime: 30
                 end
    end

    def calc_score
      return if state.round_finished
      return if alive_ships.length > 1

      if alive_ships.first == state.ship_red
        state.ship_red_score += 1
      elsif alive_ships.first == state.ship_blue
        state.ship_blue_score += 1
      end

      state.round_finished = true
    end

    def calc_reset_ships
      return unless state.round_finished
      state.round_finished_at ||= Kernel.tick_count
      return if state.round_finished_at.elapsed_time <= 2.seconds
      start_new_round!
    end

    def start_new_round!
      state.ship_blue = new_blue_ship
      state.ship_red  = new_red_ship
      state.round_finished = false
      state.round_finished_at = nil
      state.flames.clear
      state.bullets.clear
    end

    def calc_winner
      calc_kill_ships
      calc_score
      calc_reset_ships
    end
  end

  $dueling_spaceship = DuelingSpaceships.new

  def tick args
    args.grid.origin_center!
    $dueling_spaceship.args = args
    $dueling_spaceship.tick
  end

```

### arcade/flappy dragon/main.rb
```ruby
  # ./samples/99_genre_arcade/flappy_dragon/app/main.rb
  class FlappyDragon
    attr_accessor :grid, :inputs, :state, :outputs

    def tick
      defaults
      render
      calc
      process_inputs
    end

    def defaults
      state.flap_power              = 11
      state.gravity                 = 0.9
      state.ceiling                 = 600
      state.ceiling_flap_power      = 6
      state.wall_countdown_length   = 100
      state.wall_gap_size           = 100
      state.wall_countdown        ||= 0
      state.hi_score              ||= 0
      state.score                 ||= 0
      state.walls                 ||= []
      state.x                     ||= 50
      state.y                     ||= 500
      state.dy                    ||= 0
      state.scene                 ||= :menu
      state.scene_at              ||= 0
      state.difficulty            ||= :normal
      state.new_difficulty        ||= :normal
      state.countdown             ||= 4.seconds
      state.flash_at              ||= 0
    end

    def render
      outputs.sounds << "sounds/flappy-song.ogg" if Kernel.tick_count == 1
      render_score
      render_menu
      render_game
    end

    def render_score
      outputs.primitives << { x: 10, y: 710, text: "HI SCORE: #{state.hi_score}", **large_white_typeset }
      outputs.primitives << { x: 10, y: 680, text: "SCORE: #{state.score}", **large_white_typeset }
      outputs.primitives << { x: 10, y: 650, text: "DIFFICULTY: #{state.difficulty.upcase}", **large_white_typeset }
    end

    def render_menu
      return unless state.scene == :menu
      render_overlay

      outputs.labels << { x: 640, y: 700, text: "Flappy Dragon", size_enum: 50, alignment_enum: 1, **white }
      outputs.labels << { x: 640, y: 500, text: "Instructions: Press Spacebar to flap. Don't die.", size_enum: 4, alignment_enum: 1, **white }
      outputs.labels << { x: 430, y: 430, text: "[Tab]    Change difficulty", size_enum: 4, alignment_enum: 0, **white }
      outputs.labels << { x: 430, y: 400, text: "[Enter]  Start at New Difficulty ", size_enum: 4, alignment_enum: 0, **white }
      outputs.labels << { x: 430, y: 370, text: "[Escape] Cancel/Resume ", size_enum: 4, alignment_enum: 0, **white }
      outputs.labels << { x: 640, y: 300, text: "(mouse, touch, and game controllers work, too!) ", size_enum: 4, alignment_enum: 1, **white }
      outputs.labels << { x: 640, y: 200, text: "Difficulty: #{state.new_difficulty.capitalize}", size_enum: 4, alignment_enum: 1, **white }

      outputs.labels << { x: 10, y: 100, text: "Code:   @amirrajan",     **white }
      outputs.labels << { x: 10, y:  80, text: "Art:    @mobypixel",     **white }
      outputs.labels << { x: 10, y:  60, text: "Music:  @mobypixel",     **white }
      outputs.labels << { x: 10, y:  40, text: "Engine: DragonRuby DR", **white }
    end

    def render_overlay
      overlay_rect = grid.rect.scale_rect(1.1, 0, 0)
      outputs.primitives << { x: overlay_rect.x,
                              y: overlay_rect.y,
                              w: overlay_rect.w,
                              h: overlay_rect.h,
                              r: 0, g: 0, b: 0, a: 230 }.solid!
    end

    def render_game
      render_game_over
      render_background
      render_walls
      render_dragon
      render_flash
    end

    def render_game_over
      return unless state.scene == :game
      outputs.labels << { x: 638, y: 358, text: score_text,     size_enum: 20, alignment_enum: 1 }
      outputs.labels << { x: 635, y: 360, text: score_text,     size_enum: 20, alignment_enum: 1, r: 255, g: 255, b: 255 }
      outputs.labels << { x: 638, y: 428, text: countdown_text, size_enum: 20, alignment_enum: 1 }
      outputs.labels << { x: 635, y: 430, text: countdown_text, size_enum: 20, alignment_enum: 1, r: 255, g: 255, b: 255 }
    end

    def render_background
      outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: 'sprites/background.png' }

      scroll_point_at   = Kernel.tick_count
      scroll_point_at   = state.scene_at if state.scene == :menu
      scroll_point_at   = state.death_at if state.countdown > 0
      scroll_point_at ||= 0

      outputs.sprites << scrolling_background(scroll_point_at, 'sprites/parallax_back.png',   0.25)
      outputs.sprites << scrolling_background(scroll_point_at, 'sprites/parallax_middle.png', 0.50)
      outputs.sprites << scrolling_background(scroll_point_at, 'sprites/parallax_front.png',  1.00, -80)
    end

    def scrolling_background at, path, rate, y = 0
      [
        { x:    0 - at.*(rate) % 1440, y: y, w: 1440, h: 720, path: path },
        { x: 1440 - at.*(rate) % 1440, y: y, w: 1440, h: 720, path: path }
      ]
    end

    def render_walls
      state.walls.each do |w|
        w.sprites = [
          { x: w.x, y: w.bottom_height - 720, w: 100, h: 720, path: 'sprites/wall.png',       angle: 180 },
          { x: w.x, y: w.top_y,               w: 100, h: 720, path: 'sprites/wallbottom.png', angle: 0 }
        ]
      end
      outputs.sprites << state.walls.map(&:sprites)
    end

    def render_dragon
      state.show_death = true if state.countdown == 3.seconds

      if state.show_death == false || !state.death_at
        animation_index = state.flapped_at.frame_index 6, 2, false if state.flapped_at
        sprite_name = "sprites/dragon_fly#{(animation_index || 0) + 1}.png"
        state.dragon_sprite = { x: state.x, y: state.y, w: 100, h: 80, path: sprite_name, angle: state.dy * 1.2 }
      else
        sprite_name = "sprites/dragon_die.png"
        state.dragon_sprite = { x: state.x, y: state.y, w: 100, h: 80, path: sprite_name, angle: state.dy * 1.2 }
        sprite_changed_elapsed    = state.death_at.elapsed_time - 1.seconds
        state.dragon_sprite.angle += (sprite_changed_elapsed ** 1.3) * state.death_fall_direction * -1
        state.dragon_sprite.x     += (sprite_changed_elapsed ** 1.2) * state.death_fall_direction
        state.dragon_sprite.y     += (sprite_changed_elapsed * 14 - sprite_changed_elapsed ** 1.6)
      end

      outputs.sprites << state.dragon_sprite
    end

    def render_flash
      return unless state.flash_at

      outputs.primitives << { **grid.rect.to_hash,
                              **white,
                              a: 255 * state.flash_at.ease(20, :flip) }.solid!

      state.flash_at = 0 if state.flash_at.elapsed_time > 20
    end

    def calc
      return unless state.scene == :game
      reset_game if state.countdown == 1
      state.countdown -= 1 and return if state.countdown > 0
      calc_walls
      calc_flap
      calc_game_over
    end

    def calc_walls
      state.walls.each { |w| w.x -= 8 }

      walls_count_before_removal = state.walls.length

      state.walls.reject! { |w| w.x < -100 }

      state.score += 1 if state.walls.count < walls_count_before_removal

      state.wall_countdown -= 1 and return if state.wall_countdown > 0

      state.walls << state.new_entity(:wall) do |w|
        w.x             = grid.right
        w.opening       = grid.top
                              .randomize(:ratio)
                              .greater(200)
                              .lesser(520)
        w.bottom_height = w.opening - state.wall_gap_size
        w.top_y         = w.opening + state.wall_gap_size
      end

      state.wall_countdown = state.wall_countdown_length
    end

    def calc_flap
      state.y += state.dy
      state.dy = state.dy.lesser state.flap_power
      state.dy -= state.gravity
      return if state.y < state.ceiling
      state.y  = state.ceiling
      state.dy = state.dy.lesser state.ceiling_flap_power
    end

    def calc_game_over
      return unless game_over?

      state.death_at = Kernel.tick_count
      state.death_from = state.walls.first
      state.death_fall_direction = -1
      state.death_fall_direction =  1 if state.x > state.death_from.x
      outputs.sounds << "sounds/hit-sound.wav"
      begin_countdown
    end

    def process_inputs
      process_inputs_menu
      process_inputs_game
    end

    def process_inputs_menu
      return unless state.scene == :menu

      changediff = inputs.keyboard.key_down.tab || inputs.controller_one.key_down.select
      if inputs.mouse.click
        p = inputs.mouse.click.point
        if (p.y >= 165) && (p.y < 200) && (p.x >= 500) && (p.x < 800)
          changediff = true
        end
      end

      if changediff
        case state.new_difficulty
        when :easy
          state.new_difficulty = :normal
        when :normal
          state.new_difficulty = :hard
        when :hard
          state.new_difficulty = :flappy
        when :flappy
          state.new_difficulty = :easy
        end
      end

      if inputs.keyboard.key_down.enter || inputs.controller_one.key_down.start || inputs.controller_one.key_down.a
        state.difficulty = state.new_difficulty
        change_to_scene :game
        reset_game false
        state.hi_score = 0
        begin_countdown
      end

      if inputs.keyboard.key_down.escape || (inputs.mouse.click && !changediff) || inputs.controller_one.key_down.b
        state.new_difficulty = state.difficulty
        change_to_scene :game
      end
    end

    def process_inputs_game
      return unless state.scene == :game

      clicked_menu = false
      if inputs.mouse.click
        p = inputs.mouse.click.point
        clicked_menu = (p.y >= 620) && (p.x < 275)
      end

      if clicked_menu || inputs.keyboard.key_down.escape || inputs.keyboard.key_down.enter || inputs.controller_one.key_down.start
        change_to_scene :menu
      elsif (inputs.mouse.down || inputs.mouse.click || inputs.keyboard.key_down.space || inputs.controller_one.key_down.a) && state.countdown == 0
        state.dy = 0
        state.dy += state.flap_power
        state.flapped_at = Kernel.tick_count
        outputs.sounds << "sounds/fly-sound.wav"
      end
    end

    def white
      { r: 255, g: 255, b: 255 }
    end

    def large_white_typeset
      { size_enum: 5, alignment_enum: 0, r: 255, g: 255, b: 255 }
    end

    def at_beginning?
      state.walls.count == 0
    end

    def dragon_collision_box
      state.dragon_sprite
           .scale_rect(1.0 - collision_forgiveness, 0.5, 0.5)
           .rect_shift_right(10)
           .rect_shift_up(state.dy * 2)
    end

    def game_over?
      return true if state.y <= 0.-(500 * collision_forgiveness) && !at_beginning?

      state.walls
          .flat_map { |w| w.sprites }
          .any? do |s|
            s && s.intersect_rect?(dragon_collision_box)
          end
    end

    def collision_forgiveness
      case state.difficulty
      when :easy
        0.9
      when :normal
        0.7
      when :hard
        0.5
      when :flappy
        0.3
      else
        0.9
      end
    end

    def countdown_text
      state.countdown ||= -1
      return ""          if state.countdown == 0
      return "GO!"       if state.countdown.idiv(60) == 0
      return "GAME OVER" if state.death_at
      return "READY?"
    end

    def begin_countdown
      state.countdown = 4.seconds
    end

    def score_text
      return ""                        unless state.countdown > 1.seconds
      return ""                        unless state.death_at
      return "SCORE: 0 (LOL)"          if state.score == 0
      return "HI SCORE: #{state.score}" if state.score == state.hi_score
      return "SCORE: #{state.score}"
    end

    def reset_game set_flash = true
      state.flash_at = Kernel.tick_count if set_flash
      state.walls = []
      state.y = 500
      state.dy = 0
      state.hi_score = state.hi_score.greater(state.score)
      state.score = 0
      state.wall_countdown = state.wall_countdown_length.fdiv(2)
      state.show_death = false
      state.death_at = nil
    end

    def change_to_scene scene
      state.scene = scene
      state.scene_at = Kernel.tick_count
      inputs.keyboard.clear
      inputs.controller_one.clear
    end
  end

  $flappy_dragon = FlappyDragon.new

  def tick args
    $flappy_dragon.grid = args.grid
    $flappy_dragon.inputs = args.inputs
    $flappy_dragon.state = args.state
    $flappy_dragon.outputs = args.outputs
    $flappy_dragon.tick
  end

```

### Pong - main.rb
```ruby
  # ./samples/99_genre_arcade/pong/app/main.rb
  def tick args
    defaults args
    render args
    calc args
    input args
  end

  def defaults args
    args.state.ball ||= {
      debounce: 3 * 60,
      size: 10,
      size_half: 5,
      x: 640,
      y: 360,
      dx: 5.randomize(:sign),
      dy: 5.randomize(:sign)
    }

    args.state.paddle ||= {
      w: 10,
      h: 120
    }

    args.state.left_paddle  ||= { y: 360, score: 0 }
    args.state.right_paddle ||= { y: 360, score: 0 }
  end

  def render args
    render_center_line args
    render_scores args
    render_countdown args
    render_ball args
    render_paddles args
    render_instructions args
  end

  begin :render_methods
    def render_center_line args
      args.outputs.lines  << [640, 0, 640, 720]
    end

    def render_scores args
      args.outputs.labels << [
        { x: 320,
          y: 650,
          text: args.state.left_paddle.score,
          size_px: 40,
          anchor_x: 0.5,
          anchor_y: 0.5 },
        { x: 960,
          y: 650,
          text: args.state.right_paddle.score,
          size_px: 40,
          anchor_x: 0.5,
          anchor_y: 0.5 }
      ]
    end

    def render_countdown args
      return unless args.state.ball.debounce > 0
      args.outputs.labels << { x: 640,
                               y: 360,
                               text: "%.2f" % args.state.ball.debounce.fdiv(60),
                               size_px: 40,
                               anchor_x: 0.5,
                               anchor_y: 0.5 }
    end

    def render_ball args
      args.outputs.solids << solid_ball(args)
    end

    def render_paddles args
      args.outputs.solids << solid_left_paddle(args)
      args.outputs.solids << solid_right_paddle(args)
    end

    def render_instructions args
      args.outputs.labels << { x: 320,
                               y: 30,
                               text: "W and S keys to move left paddle.",
                               anchor_x: 0.5,
                               anchor_y: 0.5 }
      args.outputs.labels << { x: 920,
                               y: 30,
                               text: "O and L keys to move right paddle.",
                               anchor_x: 0.5,
                               anchor_y: 0.5 }
    end
  end

  def calc args
    args.state.ball.debounce -= 1 and return if args.state.ball.debounce > 0
    calc_move_ball args
    calc_collision_with_left_paddle args
    calc_collision_with_right_paddle args
    calc_collision_with_walls args
  end

  begin :calc_methods
    def calc_move_ball args
      args.state.ball.x += args.state.ball.dx
      args.state.ball.y += args.state.ball.dy
    end

    def calc_collision_with_left_paddle args
      if solid_left_paddle(args).intersect_rect? solid_ball(args)
        args.state.ball.dx *= -1
      elsif args.state.ball.x < 0
        args.state.right_paddle.score += 1
        calc_reset_round args
      end
    end

    def calc_collision_with_right_paddle args
      if solid_right_paddle(args).intersect_rect? solid_ball(args)
        args.state.ball.dx *= -1
      elsif args.state.ball.x > 1280
        args.state.left_paddle.score += 1
        calc_reset_round args
      end
    end

    def calc_collision_with_walls args
      if args.state.ball.y + args.state.ball.size_half > 720
        args.state.ball.y = 720 - args.state.ball.size_half
        args.state.ball.dy *= -1
      elsif args.state.ball.y - args.state.ball.size_half < 0
        args.state.ball.y = args.state.ball.size_half
        args.state.ball.dy *= -1
      end
    end

    def calc_reset_round args
      args.state.ball.x = 640
      args.state.ball.y = 360
      args.state.ball.dx = 5.randomize(:sign)
      args.state.ball.dy = 5.randomize(:sign)
      args.state.ball.debounce = 3 * 60
    end
  end

  def input args
    input_left_paddle args
    input_right_paddle args
  end

  def input_left_paddle args
    if args.inputs.controller_one.key_down.down  || args.inputs.keyboard.key_down.s
      args.state.left_paddle.y -= 40
    elsif args.inputs.controller_one.key_down.up || args.inputs.keyboard.key_down.w
      args.state.left_paddle.y += 40
    end
  end

  def input_right_paddle args
    if args.inputs.controller_two.key_down.down  || args.inputs.keyboard.key_down.l
      args.state.right_paddle.y -= 40
    elsif args.inputs.controller_two.key_down.up || args.inputs.keyboard.key_down.o
      args.state.right_paddle.y += 40
    end
  end

  def solid_ball args
    { x: args.state.ball.x,
      y: args.state.ball.y,
      w: args.state.ball.size,
      h: args.state.ball.size,
      anchor_x: 0.5,
      anchor_y: 0.5 }
  end

  def solid_left_paddle args
    { x: 0,
      y: args.state.left_paddle.y,
      w: args.state.paddle.w,
      h: args.state.paddle.h,
      anchor_y: 0.5 }
  end

  def solid_right_paddle args
    { x: 1280 - args.state.paddle.w,
      y: args.state.right_paddle.y,
      w: args.state.paddle.w,
      h: args.state.paddle.h,
      anchor_y: 0.5 }
  end

```

### Solar System - main.rb
```ruby
  # ./samples/99_genre_arcade/solar_system/app/main.rb
  # Focused tutorial video: https://s3.amazonaws.com/s3.dragonruby.org/dragonruby-nddnug-workshop.mp4
  # Workshop/Presentation which provides motivation for creating a game engine: https://www.youtube.com/watch?v=S3CFce1arC8

  def defaults args
    args.outputs.background_color = [0, 0, 0]
    args.state.x ||= 640
    args.state.y ||= 360
    args.state.stars ||= 100.map do
      [1280 * rand, 720 * rand, rand.fdiv(10), 255 * rand, 255 * rand, 255 * rand]
    end

    args.state.sun ||= args.state.new_entity(:sun) do |s|
      s.s = 100
      s.path = 'sprites/sun.png'
    end

    args.state.planets = [
      [:mercury,   65,  5,          88],
      [:venus,    100, 10,         225],
      [:earth,    120, 10,         365],
      [:mars,     140,  8,         687],
      [:jupiter,  280, 30, 365 *  11.8],
      [:saturn,   350, 20, 365 *  29.5],
      [:uranus,   400, 15, 365 *    84],
      [:neptune,  440, 15, 365 * 164.8],
      [:pluto,    480,  5, 365 * 247.8],
    ].map do |name, distance, size, year_in_days|
      args.state.new_entity(name) do |p|
        p.path = "sprites/#{name}.png"
        p.distance = distance * 0.7
        p.s = size * 0.7
        p.year_in_days = year_in_days
      end
    end

    args.state.ship ||= args.state.new_entity(:ship) do |s|
      s.x = 1280 * rand
      s.y = 720 * rand
      s.angle = 0
    end
  end

  def to_sprite args, entity
    x = 0
    y = 0

    if entity.year_in_days
      day = Kernel.tick_count
      day_in_year = day % entity.year_in_days
      entity.random_start_day ||= day_in_year * rand
      percentage_of_year = day_in_year.fdiv(entity.year_in_days)
      angle = 365 * percentage_of_year
      x = angle.vector_x(entity.distance)
      y = angle.vector_y(entity.distance)
    end

    [640 + x - entity.s.half, 360 + y - entity.s.half, entity.s, entity.s, entity.path]
  end

  def render args
    args.outputs.solids << [0, 0, 1280, 720]

    args.outputs.sprites << args.state.stars.map do |x, y, _, r, g, b|
      [x, y, 10, 10, 'sprites/star.png', 0, 100, r, g, b]
    end

    args.outputs.sprites << to_sprite(args, args.state.sun)
    args.outputs.sprites << args.state.planets.map { |p| to_sprite args, p }
    args.outputs.sprites << [args.state.ship.x, args.state.ship.y, 20, 20, 'sprites/ship.png', args.state.ship.angle]
  end

  def calc args
    args.state.stars = args.state.stars.map do |x, y, speed, r, g, b|
      x += speed
      y += speed
      x = 0 if x > 1280
      y = 0 if y > 720
      [x, y, speed, r, g, b]
    end

    if Kernel.tick_count == 0
      args.audio[:bg_music] = {
        input: 'sounds/bg.ogg',
        looping: true
      }
    end
  end

  def process_inputs args
    if args.inputs.keyboard.left || args.inputs.controller_one.key_held.left
      args.state.ship.angle += 1
    elsif args.inputs.keyboard.right || args.inputs.controller_one.key_held.right
      args.state.ship.angle -= 1
    end

    if args.inputs.keyboard.up || args.inputs.controller_one.key_held.a
      args.state.ship.x += args.state.ship.angle.x_vector
      args.state.ship.y += args.state.ship.angle.y_vector
    end
  end

  def tick args
    defaults args
    render args
    calc args
    process_inputs args
  end

  def r
    DR.reset
  end

```

### Sound Golf - main.rb
```ruby
  # ./samples/99_genre_arcade/sound_golf/app/main.rb
  # class that encapsulates all game logic and state
  class Game
    # attr_dr is a helper class macro that adds `args` attribuets to the class so you don't have to pass `args` around to every method
    attr_dr

    # this is the constructor
    def initialize
      # list of available notes
      @available_notes = [:C3, :D3, :E3, :F3, :G3, :A3, :B3, :C4]

      # queue of click effects to render
      @click_fx_queue = []

      # location of play again and play note buttons
      @play_again_button = Layout.rect(row: 2, col: 10, w: 4, h: 2)
      @play_note_button = Layout.rect(row: 2, col: 10, w: 4, h: 2)

      # location of guess note buttons, generated based on available notes
      @guess_note_buttons = @available_notes.map_with_index do |note, index|
        Layout.rect(row: 6, col: 4 + index * 2, w: 2, h: 2).merge(note: note)
      end

      # start a new game
      new_game!
    end

    def new_game!
      # current level is set to 1 and time stamp is captured so that items can fade in based on how long the player has been on the current level
      @current_level = 1
      @current_level_at = Kernel.tick_count

      # pre-generate the solutions for each level
      @level_notes = {}
      9.times do |i|
        # exclude notes that have been recently played in the previous 2 levels
        previous_level_notes = [@level_notes[i], @level_notes[i - 1]].compact

        # take a random note from the available notes that isn't in the previous level notes and assign it to the current level
        @level_notes[i + 1] = @available_notes.reject do |note|
          previous_level_notes.include?(note)
        end.sample
      end

      # keeps track of how many times the player has guessed wrong for scoring purposes
      @times_wrong = 0

      # markes the game as over so that they get the option to play again
      @game_over = false
    end

    def tick
      calc
      render
    end

    def calc
      # process the click fx queue by lerping the width, height, and alpha of each
      # effect towards their final values and removing them from the queue once they are fully faded out
      @click_fx_queue.each do |fx|
        fx.w_final ||= fx.w * 2
        fx.h_final ||= fx.h * 2
        fx.w = fx.w.lerp(fx.w_final, 0.2, tolerance: 1)
        fx.h = fx.h.lerp(fx.h_final, 0.2, tolerance: 1)
        fx.a = fx.a.lerp(0, 0.2, tolerance: 1)
      end

      @click_fx_queue.reject! { |fx| fx.a <= 0 }

      # automatically play the current level note after 60 frames (1 second)
      if @current_level_at.elapsed_time == 60
        play_current_level_note!
      end

      # if the mouse is clicked...
      if inputs.mouse.click
        # if the game is over, check if they clicked the play again button
        if @game_over
          if Geometry.intersect_rect?(inputs.mouse.rect, @play_again_button)
            queue_click_fx!(rect: @play_again_button, r: 0, g: 160, b: 160)
            new_game!
          end
        else
          # if the game isn't over, check if they clicked the play note button or one of the guess note buttons
          if Geometry.intersect_rect?(inputs.mouse.rect, @play_note_button)
            play_current_level_note!
          else
            # see if they clicked any of the guess note buttons by finding the first button that intersects with the mouse click
            clicked_button = @guess_note_buttons.find do |button|
              Geometry.intersect_rect?(inputs.mouse.rect, button)
            end

            check_guess clicked_button
          end
        end
      end
    end

    def play_current_level_note!
      queue_click_fx!(rect: @play_note_button, r: 0, g: 160, b: 160)
      outputs.sounds << "sounds/#{@level_notes[@current_level].to_s.downcase}.ogg"
    end

    # check guess function compares the note they clicked to the note of the current level
    def check_guess button
      # ignore if they button is nil
      return if !button

      # if the button's note matches the level's note...
      if button.note == @level_notes[@current_level]
        queue_click_fx!(rect: button, r: 0, g: 160, b: 0)

        # mark the game as over if it's the last level
        if @current_level == 9
          @game_over = true
        else
          # otherwise, move on to the next level by incrementing the current level and capturing a new time stamp for the fade in effect
          @current_level += 1
          @current_level_at = Kernel.tick_count
        end
      else
        # if they guessed wrong then queue a red click effect and increment the times wrong for scoring purposes
        queue_click_fx!(rect: button, r: 160, g: 0, b: 0)
        @times_wrong += 1
      end

      # play the note of the button they clicked as feedback for what they clicked on
      outputs.sounds << "sounds/#{button.note.to_s.downcase}.ogg"
    end

    def render
      outputs.background_color = [30, 30, 30]

      # render current hole and current score
      outputs.primitives << hole_prefab
      outputs.primitives << score_prefab

      if @game_over
        # only render the play again button if the game is over
        outputs.primitives << play_again_button_prefab
      else
        # otherwise, render the play note button and the guess note buttons
        outputs.primitives << play_note_button_prefab
        outputs.primitives << instructions_prefab
        outputs.primitives << @guess_note_buttons.map { |button| button_prefab(button, button.note.to_s) }
      end

      # render click effects
      outputs.primitives << @click_fx_queue

      # this helper method was used to position controls
      # outputs.debug << Layout.debug_primitives(invert_colors: true, a: 128)
    end

    def queue_click_fx!(rect:, r:, g:, b:)
      # function for adding a click effect
      center = Geometry.center rect
      @click_fx_queue << { x: center.x,
                           y: center.y,
                           w: rect.w,
                           h: rect.h,
                           r: r,
                           g: g,
                           b: b,
                           a: 255,
                           anchor_x: 0.5,
                           anchor_y: 0.5,
                           path: :solid }
    end

    def hole_prefab
      # label representing the current level
      Layout.rect(row: 0, col: 11, w: 2, h: 1)
            .center
            .merge text: "Hole #{@current_level} of 9",
                   anchor_x: 0.5,
                   anchor_y: 0.5,
                   r: 255,
                   g: 255,
                   b: 255,
                   a: round_fade_in_alpha,
                   size_px: 32
    end

    def score_prefab
      # label representing the current score
      text = if @times_wrong == 0
               "Score: PAR"
             else
               "Score: +#{@times_wrong}"
             end

      Layout.rect(row: 0, col: 11, w: 2, h: 1)
            .center
            .merge(text: text,
                   anchor_x: 0.5,
                   anchor_y: 0.5,
                   anchor_y: 2.0,
                   size_px: 32,
                   a: round_fade_in_alpha,
                   r: 255,
                   g: 255,
                   b: 255)
    end

    def instructions_prefab
      # label providing instructions
      Layout.rect(row: 3, col: 11, w: 2, h: 2)
            .center
            .merge(text: "Click one of the notes below to guess the note being played",
                   anchor_x: 0.5,
                   anchor_y: 0.5,
                   anchor_y: 2.0,
                   size_px: 32,
                   a: round_fade_in_alpha,
                   r: 255,
                   g: 255,
                   b: 255)
    end

    def play_again_button_prefab
      button_prefab(@play_again_button, "Play Again")
    end

    def play_note_button_prefab
      button_prefab(@play_note_button, "Play Note")
    end

    def round_fade_in_alpha
      (@current_level_at.elapsed_time.fdiv(30) ** 2) * 255
    end

    def button_prefab rect, text
      # the button prefab is a composition of a solid rectangle with the text centered within the rect.
      [
        rect.merge(path: :solid,
                   r: 0,
                   g: 60,
                   b: 60,
                   a: 255),
        rect.center.merge(text: text,
                          anchor_x: 0.5,
                          anchor_y: 0.5,
                          a: 255,
                          r: 255,
                          g: 255,
                          b: 255,
                          size_px: 32)
      ]
    end
  end

  def boot args
    args.state = {}
  end

  def tick args
    # entry point of the game
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    # set the game to nil if DR.reset is invoked so that it gets re-initialized on the next tick
    $game = nil
  end

  DR.reset

```

### Squares - main.rb
```ruby
  # ./samples/99_genre_arcade/squares/app/main.rb
  # game concept from: https://youtu.be/Tz-AinJGDIM

  # Color pallete for game
  RED         = { r: 222, g:  63, b:  66 }
  GRAY        = { r: 128, g: 128, b: 128 }
  BLACK       = { r:   0, g:   0, b:   0 }
  LIGHT_GRAY  = { r: 237, g: 237, b: 237 }

  # initialize state to an empty hash
  def boot args
    args.state = {}
  end

  # on tick, initialize the root_scene if it's nil
  # delegate tick to the root scene container
  def tick args
    $root_scene ||= RootScene.new
    $root_scene.args = args
    $root_scene.tick

    if args.inputs.keyboard.key_down.forward_slash
      @show_fps = !@show_fps
    end

    if @show_fps
      args.outputs.primitives << DR.current_framerate_primitives
    end
  end

  # for hotloading, reset $root_scene to nil so that it's
  # reinitialized
  def reset args
    $root_scene = nil
  end

  class RootScene
    attr_dr

    def initialize
      @args = args
      @start_scene = StartScene.new
      @game_scene = GameScene.new
      @game_over_scene = GameOverScene.new
      @all_scenes = [@start_scene, @game_scene, @game_over_scene]
    end

    def tick
      defaults

      # scene management is simply based off of a value
      # on state. we only want to swap scenes at the very end
      # of tick, so we capture its current value and then
      # after all scenes run, we perform the scene swap
      state.scene_before_tick = state.current_scene

      tick_scenes
      render

      # throw an error if state.current_scene changed
      if state.scene_before_tick != state.current_scene
        raise "state.current_scene was changed during the tick. Use state.next_scene to set the scene to transfer to."
      end

      if state.next_scene
        state.current_scene = state.next_scene
        state.next_scene = nil
      end
    end

    # state has properties that are shared across scenes,
    # these are view specific concerns so it doesn't make sense
    # to put it on the core Game class
    def defaults
      state.current_scene ||= :start

      state.events ||= {
        game_over_at: nil,
        game_started_at: nil,
        game_retried_at: nil
      }

      state.current_score ||= 0
      state.best_score ||= 0
    end

    # all the scenes are enumerated, args is set on each scene,
    # then tick is invoked
    def tick_scenes
      @all_scenes.each do |scene|
        scene.args = args
        scene.tick
      end
    end

    # this function renders the scenes with a transition effect
    # based off of timestamps stored in state.events
    def render
      outputs.background_color = LIGHT_GRAY

      # because of the fancy animation transition,
      # up to two scenes will be rendered.
      # the scenes_to_render function gives those two scenes,
      # and specifies which scene is being moved in vs which
      # is being moved out
      results = scenes_to_render

      # compute the y offset for each scene based on the
      # point in time the transition should start
      in_y = transition_in_y results.event_at
      out_y = transition_out_y results.event_at
      in_scene = results.in_scene
      out_scene = results.out_scene

      # render each scene taking into consideration the animation y offsets
      outputs.primitives << Grid.rect.merge(y: in_y, path: in_scene) if in_scene
      outputs.primitives << Grid.rect.merge(y: out_y, path: out_scene) if out_scene
    end

    def scenes_to_render
      if state.events.game_over_at
        # if game over was the last event,
        # then we want to move the game over scene in,
        # and move out the game scene
        {
          event_at: state.events.game_over_at,
          in_scene: :game_over_scene,
          out_scene: :game_scene
        }
      elsif state.events.game_retried_at
        # if game retried was the last event,
        # then we want to move in the game scene,
        # and move out the game over scene
        {
          event_at: state.events.game_retried_at,
          in_scene: :game_scene,
          out_scene: :game_over_scene
        }
      elsif state.events.game_started_at
        # if game started was the last event,
        # then we want to move in the game scene,
        # and move out the start scene
        {
          event_at: state.events.game_started_at,
          in_scene: :game_scene,
          out_scene: :start_scene
        }
      else
        # on game start, immediately present the starts scene
        {
          event_at: 0,
          in_scene: :start_scene,
          out_scene: nil
        }
      end
    end

    def transition_in_y start_at
      Easing.smooth_stop(start_at: start_at,
                         duration: 30,
                         tick_count: Kernel.tick_count,
                         power: 4,
                         flip: true) * -720
    end

    def transition_out_y start_at
      Easing.smooth_stop(start_at: start_at,
                         duration: 30,
                         tick_count: Kernel.tick_count,
                         power: 4) * 720
    end
  end

  # the start scene is loaded when the game is started
  # it contains a PulseButton that starts the game by setting the next_scene to :game and
  # setting the started_at time
  class StartScene
    attr_dr

    def initialize
      @play_button = PulseButton.new Layout.rect(row: 6, col: 11, w: 2, h: 2), "play" do
        state.next_scene = :game
        state.events.game_started_at = Kernel.tick_count
        state.events.game_over_at = nil
      end
    end

    def title_prefab
      Layout.rect(row: 0, col: 11, w: 2, h: 2)
            .center
            .merge(text: "Squares", anchor_x: 0.5, anchor_y: 0.5, size_px: 64)
    end

    def tick
      return if state.current_scene != :start
      @play_button.tick inputs.mouse
      outputs[:start_scene].primitives << title_prefab
      outputs[:start_scene].primitives << @play_button.prefab
    end
  end

  # the game over scene is displayed when the game is over
  # it contains a PulseButton that restarts the game by setting the next_scene to :game and
  # setting the game_retried_at time
  class GameOverScene
    attr_dr

    def initialize
      @replay_button = PulseButton.new Layout.rect(row: 6, col: 11, w: 2, h: 2), "replay" do
        state.next_scene = :game
        state.events.game_retried_at = Kernel.tick_count
        state.events.game_over_at = nil
      end
    end

    def title_prefab
      Layout.rect(row: 0, col: 11, w: 2, h: 2)
            .center
            .merge(text: "Game Over", anchor_x: 0.5, anchor_y: 0.5, size_px: 64)
    end

    def current_score_prefab
      Layout.rect(row: 2, col: 11, w: 2, h: 2)
            .center
            .merge(text: state.current_score, anchor_x: 0.5, anchor_y: 0.5, size_px: 128, **RED)
    end

    def best_score_prefab
      Layout.rect(row: 4, col: 10, w: 4, h: 2)
            .center
            .merge(text: "BEST #{state.best_score}", anchor_x: 0.5, anchor_y: 0.5, size_px: 64, **GRAY)
    end

    def tick
      return if state.current_scene != :game_over
      @replay_button.tick inputs.mouse
      outputs[:game_over_scene].primitives << title_prefab
      outputs[:game_over_scene].primitives << @replay_button.prefab
      outputs[:game_over_scene].primitives << current_score_prefab
      outputs[:game_over_scene].primitives << best_score_prefab
    end
  end

  # this is the core game (separate from it's rendering)
  class Game
    attr :score, :square_number, :squares, :square_spawn_rate,
         :movement_outer_rect, :movement_inner_rect, :player, :death_at, :score_at

    def initialize
      # initialization of the game
      @score = 0
      @square_number = 1
      @squares = []
      @square_spawn_rate = 60

      # area the player is restricted to
      @movement_outer_rect = Layout.rect(row: 11, col: 7, w: 10, h: 1)
                                   .merge(path: :solid, **GRAY)

      # player's starting location
      @player = {
        x: @movement_outer_rect.center.x,
        y: @movement_outer_rect.y,
        w: @movement_outer_rect.h,
        h: @movement_outer_rect.h,
        movement_direction: 1,
        movement_speed: 8
      }

      # a smaller/more forgiving area that's used
      # so that input/square movement feels a little nicer
      @movement_inner_rect = {
        x: @movement_outer_rect.x + @player.w * 1,
        y: @movement_outer_rect.y,
        w: @movement_outer_rect.w - @player.w * 2,
        h: @movement_outer_rect.h
      }
    end

    def tick(change_direction_requested:)
      # tick of the game, the request to change the player's direction
      # is forwarded to tick_play
      tick_player change_direction_requested: change_direction_requested
      tick_squares
      tick_collision
    end

    def tick_player(change_direction_requested:)
      # increment the player's x and change it's diretion if it's out of the
      # outer rect
      @player.x += @player.movement_speed * @player.movement_direction
      @player.movement_direction *= -1 if !Geometry.inside_rect? @player, @movement_outer_rect

      # if a direction change was requested, then perform the update if
      # they aren't right at the edge of the movement area
      return if !change_direction_requested
      return if !Geometry.inside_rect? @player, @movement_inner_rect
      @player.movement_direction = -@player.movement_direction
    end

    def tick_squares
      # this function controls the spawning of squares and
      # movement of squares down the screen
      @squares << new_square if Kernel.tick_count.zmod? @square_spawn_rate

      @squares.each do |square|
        square.angle += 1
        square.x += square.dx
        square.y += square.dy
      end

      # delete squares that are off the screen
      @squares.reject! { |square| (square.y + square.h) < 0 }
    end

    def tick_collision
      # collision check returns a hash back to the view so
      # that the tick result can be acted on
      # we return whether death occured, whether a score occured,
      # and return the scoring square + the rest of the squares
      # which is used by the view to generate animations
      collision = Geometry.find_intersect_rect @player, @squares

      # the default collision result is "nothing happened"
      collision_result = {
        death_occurred: false,
        score_occurred: false,
        scored_square: nil,
        all_squares: Array.new(@squares)
      }

      if !collision
        # do nothing, collision result remains unchanged
      elsif collision.type == :good
        # if they collided with a "good" square, then
        # increment the score and update the collision result
        # with the square that was collided with
        @score += 1
        @score_at = Kernel.tick_count
        @squares.delete collision
        collision_result.merge! score_occurred: true,
                                scored_square: collision

      else
        # if they collided with a "bad" square, then it's a game over
        # clear all the current squares and set when death occurred
        @squares.clear
        @score = 0
        @square_number = 1
        @death_at = Kernel.tick_count
        collision_result.merge! death_occurred: true
      end

      # return the collision result
      collision_result
    end

    # this function returns a new square
    # every 5th square is a good square (increases the score)
    def new_square
      x = movement_inner_rect.x + rand * movement_inner_rect.w

      dx = if x > Geometry.rect_center_point(movement_inner_rect).x
             -0.9
           else
             0.9
           end

      if @square_number.zmod? 5
        type = :good
      else
        type = :bad
      end

      @square_number += 1

      {
        x: x - 16,
        y: 1300, w: 32, h: 32,
        dx: dx, dy: -5,
        angle: 0, type: type
      }
    end

  end

  # the game scene contains the game logic
  class GameScene
    attr_dr

    attr :scale_down_particles_queue, :launch_particle_queue

    def initialize
      @game = Game.new
      @launch_particle_queue = []
      @scale_down_particles_queue = []
      @score_animation_spline = [[0.0, 0.66, 1.0, 1.0], [1.0, 0.33, 0.0, 0.0]]
    end

    def tick
      calc
      render
    end

    def calc
      calc_game_over_at
      calc_particles

      # game logic is only calculated if the current scene is :game
      return if state.current_scene != :game

      # set the current score to zero for presentation
      state.current_score = 0

      # we don't want the game loop to start for half a second after the game starts
      # this gives enough time for the game scene to animate in
      return if !started_at || started_at.elapsed_time <= 30

      # update current score the the game score if things have started up
      state.current_score = @game.score

      # after, tick check the tick_result to see which animations we should kick off
      tick_result = @game.tick change_direction_requested: inputs.mouse.click

      # if the player captured a "good" square, then queue up the animation
      # of the "good" square
      if tick_result.score_occurred
        @scale_down_particles_queue << square_prefab(tick_result.scored_square).merge(start_at: Kernel.tick_count, scale_speed: -2)
      elsif tick_result.death_occurred
        # if death occured that generated the explosion animation
        # and the scale out of all the set pieces
        generate_death_particles! tick_result.all_squares
        state.best_score = state.current_score if state.current_score > state.best_score
        state.next_scene = :game_over
      end
    end

    # this function calculates the point in the time the game is over
    # an intermediary variable stored in @game.death_at is consulted
    # before transitioning to the game over scene to ensure that particle animations
    # have enough time to complete before the game over scene is rendered
    def calc_game_over_at
      return if !death_at
      return if death_at.elapsed_time < 120
      state.events.game_over_at ||= Kernel.tick_count
    end

    # this function calculates the particles
    # there are two queues of particles that are processed
    # the launch_particle_queue contains particles that are launched when the player is hit
    # the scale_down_particles_queue contains particles that need to be scaled down
    # this isn't part of the Game object because its specifically visual effects
    # and doesn't affect the game logic
    def calc_particles
      @launch_particle_queue.each do |p|
        p.x += p.launch_angle.vector_x * p.speed
        p.y += p.launch_angle.vector_y * p.speed
        p.speed *= 0.90
        p.d_a ||= 1
        p.a -= 1 * p.d_a
        p.d_a *= 1.1
      end

      @launch_particle_queue.reject! { |p| p.a <= 0 }

      @scale_down_particles_queue.each do |p|
        next if p.start_at > Kernel.tick_count
        p.scale_speed = p.scale_speed.abs
        p.x += p.scale_speed
        p.y += p.scale_speed
        p.w -= p.scale_speed * 2
        p.h -= p.scale_speed * 2
      end

      @scale_down_particles_queue.reject! { |p| p.w <= 0 }
    end

    def render
      return if !started_at
      outputs[:game_scene].primitives << game_scene_score_prefab
      outputs[:game_scene].primitives << @game.movement_outer_rect.merge(a: 128)
      outputs[:game_scene].primitives << square_prefabs(@game.squares)
      outputs[:game_scene].primitives << player_prefab(@game.player)
      outputs[:game_scene].primitives << @launch_particle_queue
      outputs[:game_scene].primitives << @scale_down_particles_queue
    end

    def square_prefab s
      color = s.type == :good ? RED : BLACK
      { **s, path: :solid, **color }
    end

    def square_prefabs squares
      squares.map { |s| square_prefab s }
    end

    # this function returns the rendering primitive for the score
    def game_scene_score_prefab
      score = state.current_score

      label_scale_prec = Easing.spline(@game.score_at || 0, Kernel.tick_count, 15, @score_animation_spline)
      rect = Layout.point row: 4, col: 12
      rect.merge(text: score, anchor_x: 0.5, anchor_y: 0.5, size_px: 128 + 50 * label_scale_prec, **GRAY)
    end

    def player_prefab player
      scale_perc = if death_at
                     Easing.smooth_stop(start_at: death_at, duration: 15, tick_count: Kernel.tick_count, power: 2)
                   else
                     Easing.smooth_start(start_at: started_at + 30, duration: 15, tick_count: Kernel.tick_count, power: 2, flip: true)
                   end

      player.merge(x: player.x + player.w / 2 * scale_perc,
                   y: player.y + player.h / 2 * scale_perc,
                   w: player.w * (1 - scale_perc),
                   h: player.h * (1 - scale_perc),
                   path: :solid,
                   **RED,
                   a: 255 * (1 - scale_perc))
    end

    # determines if score should be incremented or if the game should be over
    # this function generates the particles when the player is hit
    def generate_death_particles! all_squares
      # create a prefab for each square/set piece and queue them
      # up to fade out
      square_particles = square_prefabs(all_squares).map do |b|
        b.merge(start_at: Kernel.tick_count + 60, scale_speed: -1)
      end

      @scale_down_particles_queue.concat square_particles

      # use the starting player prefab and generate the explosion
      player_prefab_base = player_prefab(@game.player)

      # generate 12 particles with random size, launch angle and speed
      player_particles = 12.map do
        size = rand * @game.player.h * 0.5 + 10
        player_prefab_base.merge(w: size,
                                 h: size,
                                 a: 255,
                                 launch_angle: rand * 180, speed: 10 + rand * 50,
                                 path: :solid,
                                 **RED)
      end

      @launch_particle_queue.concat player_particles
    end

    # death_at is the point in time that the player died
    # the death_at value is an intermediary variable that is used to calculate the death animation
    # before setting state.game_over_at
    def death_at
      return nil if !@game.death_at
      return nil if @game.death_at < started_at
      @game.death_at
    end

    # started_at is the point in time that the player started (or retried) the game
    def started_at
      state.events.game_retried_at || state.events.game_started_at
    end
  end

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
      @animation_duration = 10
    end

    # the button is ticked every frame and check to see if the mouse
    # intersects the button's bounding box.
    # if it does, then pertinent information is stored in the @clicked_at variable
    # which is used to calculate the pulse animation
    def tick mouse
      if @clicked_at && @clicked_at.elapsed_time > @animation_duration
        @clicked_at = nil
        @on_click.call
      end

      return if !mouse.click
      return if !mouse.inside_rect? @rect
      @clicked_at = Kernel.tick_count
    end

    # this function returns an array of primitives that can be rendered
    def prefab
      # calculate the percentage of the pulse animation that has completed
      # and use the percentage to compute the size and position of the button
      perc = if @clicked_at
               Easing.spline @clicked_at, Kernel.tick_count, @animation_duration, @pulse_animation_spline
             else
               0
             end

      center = { x: @rect.x + @rect.w / 2, y: @rect.y + @rect.h / 2, anchor_x: 0.5, anchor_y: 0.5 }

      [
        { **center,
          w: @rect.w + 50 * perc,
          h: @rect.h + 50 * perc,
          path: :solid },
        { **center, text: @text, size_px: 32 }
      ]
    end
  end

```

### Squares Advanced Multi Orientation - main.rb
```ruby
  # ./samples/99_genre_arcade/squares_advanced_multi_orientation/app/main.rb
  # game concept from: https://youtu.be/Tz-AinJGDIM

  # Color pallete for game
  RED         = { r: 222, g:  63, b:  66 }
  GRAY        = { r: 128, g: 128, b: 128 }
  BLACK       = { r:   0, g:   0, b:   0 }
  LIGHT_GRAY  = { r: 237, g: 237, b: 237 }

  # initialize state to an empty hash
  def boot args
    args.state = {}
  end

  # on tick, initialize the root_scene if it's nil
  # delegate tick to the root scene container
  def tick args
    $root_scene ||= RootScene.new
    $root_scene.args = args
    $root_scene.tick

    if args.inputs.keyboard.key_down.forward_slash
      @show_fps = !@show_fps
    end

    if @show_fps
      args.outputs.primitives << DR.current_framerate_primitives
    end
  end

  # for hotloading, reset $root_scene to nil so that it's
  # reinitialized
  def reset args
    $root_scene = nil
  end

  class RootScene
    attr_dr

    def initialize
      @args = args
      @start_scene = StartScene.new
      @game_scene = GameScene.new
      @game_over_scene = GameOverScene.new
      @all_scenes = [@start_scene, @game_scene, @game_over_scene]
    end

    def tick
      defaults

      # scene management is simply based off of a value
      # on state. we only want to swap scenes at the very end
      # of tick, so we capture its current value and then
      # after all scenes run, we perform the scene swap
      state.scene_before_tick = state.current_scene

      tick_scenes
      render

      # throw an error if state.current_scene changed
      if state.scene_before_tick != state.current_scene
        raise "state.current_scene was changed during the tick. Use state.next_scene to set the scene to transfer to."
      end

      if state.next_scene
        state.current_scene = state.next_scene
        state.current_scene_at = Kernel.tick_count
        state.next_scene = nil
      end
    end

    # state has properties that are shared across scenes,
    # these are view specific concerns so it doesn't make sense
    # to put it on the core Game class
    def defaults
      state.current_scene ||= :start
      state.current_scene_at ||= 0

      state.events ||= {
        game_over_at: nil,
        game_started_at: nil,
        game_retried_at: nil
      }

      state.current_score ||= 0
      state.best_score ||= 0
    end

    # all the scenes are enumerated, args is set on each scene,
    # then tick is invoked
    def tick_scenes
      @all_scenes.each do |scene|
        scene.args = args
        scene.tick
      end
    end

    # this function renders the scenes with a transition effect
    # based off of timestamps stored in state.events
    def render
      outputs.background_color = LIGHT_GRAY

      # because of the fancy animation transition,
      # up to two scenes will be rendered.
      # the scenes_to_render function gives those two scenes,
      # and specifies which scene is being moved in vs which
      # is being moved out
      results = scenes_to_render

      # compute the y offset for each scene based on the
      # point in time the transition should start
      in_y = transition_in_y results.event_at
      out_y = transition_out_y results.event_at
      in_scene = results.in_scene
      out_scene = results.out_scene

      # render each scene taking into consideration the animation y offsets
      outputs.primitives << Grid.allscreen_rect.merge(y: in_y, path: in_scene) if in_scene
      outputs.primitives << Grid.allscreen_rect.merge(y: out_y, path: out_scene) if out_scene
    end

    def scenes_to_render
      if state.events.game_over_at
        # if game over was the last event,
        # then we want to move the game over scene in,
        # and move out the game scene
        {
          event_at: state.events.game_over_at,
          in_scene: :game_over_scene,
          out_scene: :game_scene
        }
      elsif state.events.game_retried_at
        # if game retried was the last event,
        # then we want to move in the game scene,
        # and move out the game over scene
        {
          event_at: state.events.game_retried_at,
          in_scene: :game_scene,
          out_scene: :game_over_scene
        }
      elsif state.events.game_started_at
        # if game started was the last event,
        # then we want to move in the game scene,
        # and move out the start scene
        {
          event_at: state.events.game_started_at,
          in_scene: :game_scene,
          out_scene: :start_scene
        }
      else
        # on game start, immediately present the starts scene
        {
          event_at: 0,
          in_scene: :start_scene,
          out_scene: nil
        }
      end
    end

    def transition_in_y start_at
      Grid.allscreen_y + Easing.smooth_stop(start_at: start_at,
                                            duration: 30,
                                            tick_count: Kernel.tick_count,
                                            power: 4,
                                            flip: true) * -Grid.allscreen_h
    end

    def transition_out_y start_at
      Easing.smooth_stop(start_at: start_at,
                         duration: 30,
                         tick_count: Kernel.tick_count,
                         power: 4) * Grid.allscreen_h
    end
  end

  # the start scene is loaded when the game is started
  # it contains a PulseButton that starts the game by setting the next_scene to :game and
  # setting the started_at time
  class StartScene
    attr_dr

    def initialize
      @play_button = PulseButton.new pulse_button_location, "play" do
        state.next_scene = :game
        state.events.game_started_at = Kernel.tick_count
        state.events.game_over_at = nil
      end
    end

    def title_prefab
      label = { text: "Squares", anchor_x: 0.5, anchor_y: 0.5, size_px: 64, **BLACK }
      if Grid.landscape?
        Layout.rect(row: 1, col: 11, w: 2, h: 2, allscreen: true)
              .center
              .merge(label)
      else
        Layout.rect(row: 1, col: 5, w: 2, h: 2, allscreen: true)
              .center
              .merge(label)
      end
    end

    def pulse_button_location
      if Grid.landscape?
        Layout.rect(row: 9, col: 11, w: 2, h: 2, allscreen: true)
      else
        Layout.rect(row: 17, col: 5, w: 2, h: 2, allscreen: true)
      end
    end

    def tick
      return if state.current_scene != :start

      @play_button.rect = pulse_button_location
      @play_button.tick inputs.mouse
      outputs[:start_scene].w = Grid.allscreen_w
      outputs[:start_scene].h = Grid.allscreen_h
      outputs[:start_scene].primitives << title_prefab
      outputs[:start_scene].primitives << @play_button.prefab
    end
  end

  # the game over scene is displayed when the game is over
  # it contains a PulseButton that restarts the game by setting the next_scene to :game and
  # setting the game_retried_at time
  class GameOverScene
    attr_dr

    def initialize
      @replay_button = PulseButton.new replay_button_location, "replay" do
        state.next_scene = :game
        state.events.game_retried_at = Kernel.tick_count
        state.events.game_over_at = nil
      end
    end

    def replay_button_location
      if Grid.landscape?
        Layout.rect(row: 9, col: 11, w: 2, h: 2, allscreen: true)
      else
        Layout.rect(row: 16, col: 5, w: 2, h: 2, allscreen: true)
      end
    end

    def title_prefab
      label = { text: "Game Over", anchor_x: 0.5, anchor_y: 0.5, size_px: 64 }
      if Grid.landscape?
        Layout.rect(row: 1, col: 11, w: 2, h: 2, allscreen: true)
              .center
              .merge(label)
      else
        Layout.rect(row: 1, col: 5, w: 2, h: 2, allscreen: true)
              .center
              .merge(label)
      end
    end

    def current_score_prefab
      label = { text: state.current_score, anchor_x: 0.5, anchor_y: 0.5, size_px: 128, **RED }
      if Grid.landscape?
        Layout.rect(row: 4, col: 11, w: 2, h: 2, allscreen: true)
              .center
              .merge(label)
      else
        Layout.rect(row: 8, col: 5, w: 2, h: 2, allscreen: true)
              .center
              .merge(label)
      end
    end

    def best_score_prefab
      label = { text: "BEST #{state.best_score}", anchor_x: 0.5, anchor_y: 0.5, size_px: 64, **GRAY }
      if Grid.landscape?
        Layout.rect(row: 6, col: 11, w: 2, h: 2, allscreen: true)
              .center
              .merge(label)
      else
        Layout.rect(row: 10, col: 5, w: 2, h: 2, allscreen: true)
              .center
              .merge(label)
      end
    end

    def tick
      return if state.current_scene != :game_over
      @replay_button.rect = replay_button_location

      if (state.events&.game_over_at&.elapsed_time || 0) > 15
        @replay_button.tick inputs.mouse
      end
      outputs[:game_over_scene].w = Grid.allscreen_w
      outputs[:game_over_scene].h = Grid.allscreen_h
      outputs[:game_over_scene].primitives << title_prefab
      outputs[:game_over_scene].primitives << @replay_button.prefab
      outputs[:game_over_scene].primitives << current_score_prefab
      outputs[:game_over_scene].primitives << best_score_prefab
    end
  end

  # this is the core game (separate from it's rendering)
  class Game
    attr :score, :square_number, :squares, :square_spawn_rate,
         :movement_outer_rect, :movement_inner_rect, :player, :death_at, :score_at

    def initialize
      # initialization of the game
      @score = 0
      @square_number = 1
      @squares = []
      @square_spawn_rate = 60

      # area the player is restricted to
      @movement_outer_rect = if Grid.landscape?
                               Layout.rect(row: 10, col: 7, w: 10, h: 1, allscreen: true)
                             else
                               Layout.rect(row: 17, col: 1, w: 10, h: 1, allscreen: true)
                             end

      # player's starting location
      @player = {
        x: @movement_outer_rect.center.x,
        y: @movement_outer_rect.y,
        w: @movement_outer_rect.h,
        h: @movement_outer_rect.h,
        movement_direction: 1,
        movement_speed: 8
      }

      init_movement_inner_rect!
    end

    def init_movement_inner_rect!
      # a smaller/more forgiving area that's used
      # so that input/square movement feels a little nicer
      @movement_inner_rect = {
        x: @movement_outer_rect.x + @player.w * 1,
        y: @movement_outer_rect.y,
        w: @movement_outer_rect.w - @player.w * 2,
        h: @movement_outer_rect.h
      }
    end

    def update_layout!
      movement_outer_rect_x = @movement_outer_rect.x
      movement_outer_rect_y = @movement_inner_rect.y
      @movement_outer_rect = if Grid.landscape?
                               Layout.rect(row: 10, col: 7, w: 10, h: 1, allscreen: true)
                             else
                               Layout.rect(row: 17, col: 1, w: 10, h: 1, allscreen: true)
                             end

      init_movement_inner_rect!

      shift_x = @movement_outer_rect.x - movement_outer_rect_x
      shift_y = @movement_outer_rect.y - movement_outer_rect_y

      @player.x += shift_x
      @player.y += shift_y
      @squares.each do |square|
        square.x += shift_x
        square.y += shift_y
      end

      return { x: shift_x, y: shift_y }
    end

    def tick(change_direction_requested:)
      # tick of the game, the request to change the player's direction
      # is forwarded to tick_play
      tick_player change_direction_requested: change_direction_requested
      tick_squares
      tick_collision
    end

    def tick_player(change_direction_requested:)
      # increment the player's x and change it's diretion if it's out of the
      # outer rect
      @player.x += @player.movement_speed * @player.movement_direction
      @player.y = @movement_outer_rect.y
      @player.movement_direction *= -1 if !Geometry.inside_rect? @player, @movement_outer_rect

      # if a direction change was requested, then perform the update if
      # they aren't right at the edge of the movement area
      return if !change_direction_requested
      return if !Geometry.inside_rect? @player, @movement_inner_rect
      @player.movement_direction = -@player.movement_direction
    end

    def tick_squares
      # this function controls the spawning of squares and
      # movement of squares down the screen
      @squares << new_square if Kernel.tick_count.zmod? @square_spawn_rate

      @squares.each do |square|
        square.angle += 1
        square.x += square.dx
        square.y += square.dy
      end

      # delete squares that are off the screen
      @squares.reject! { |square| (square.y + square.h) < 0 }
    end

    def tick_collision
      # collision check returns a hash back to the view so
      # that the tick result can be acted on
      # we return whether death occured, whether a score occured,
      # and return the scoring square + the rest of the squares
      # which is used by the view to generate animations
      collision = Geometry.find_intersect_rect @player, @squares

      # the default collision result is "nothing happened"
      collision_result = {
        death_occurred: false,
        score_occurred: false,
        scored_square: nil,
        all_squares: Array.new(@squares)
      }

      if !collision
        # do nothing, collision result remains unchanged
      elsif collision.type == :good
        # if they collided with a "good" square, then
        # increment the score and update the collision result
        # with the square that was collided with
        @score += 1
        @score_at = Kernel.tick_count
        @squares.delete collision
        collision_result.merge! score_occurred: true,
                                scored_square: collision

      else
        # if they collided with a "bad" square, then it's a game over
        # clear all the current squares and set when death occurred
        @squares.clear
        @score = 0
        @square_number = 1
        @death_at = Kernel.tick_count
        collision_result.merge! death_occurred: true
      end

      # return the collision result
      collision_result
    end

    # this function returns a new square
    # every 5th square is a good square (increases the score)
    def new_square
      x = movement_inner_rect.x + rand * movement_inner_rect.w

      dx = if x > Geometry.rect_center_point(movement_inner_rect).x
             -0.9
           else
             0.9
           end

      if @square_number.zmod? 5
        type = :good
      else
        type = :bad
      end

      @square_number += 1

      {
        x: x - 16,
        y: @player.y + 1300, w: 32, h: 32,
        dx: dx, dy: -5,
        angle: 0, type: type
      }
    end

  end

  # the game scene contains the game logic
  class GameScene
    attr_dr

    attr :scale_down_particles_queue, :launch_particle_queue

    def initialize
      @game = Game.new
      @launch_particle_queue = []
      @scale_down_particles_queue = []
      @score_animation_spline = [[0.0, 0.66, 1.0, 1.0], [1.0, 0.33, 0.0, 0.0]]
    end

    def tick
      calc
      render
    end

    def calc
      should_update_layout = state.current_scene_at == Kernel.tick_count || Grid.orientation_changed? || events.resize_occurred

      if should_update_layout
        shifted_location = @game.update_layout!

        if shifted_location
          @launch_particle_queue.each do |p|
            p.x += shifted_location.x
            p.y += shifted_location.y
          end

          @scale_down_particles_queue.each do |p|
            p.x += shifted_location.x
            p.y += shifted_location.y
          end
        end
      end

      calc_game_over_at
      calc_particles

      # game logic is only calculated if the current scene is :game
      return if state.current_scene != :game

      # set the current score to zero for presentation
      state.current_score = 0

      # we don't want the game loop to start for half a second after the game starts
      # this gives enough time for the game scene to animate in
      return if !started_at || started_at.elapsed_time <= 30

      # update current score the the game score if things have started up
      state.current_score = @game.score

      # after, tick check the tick_result to see which animations we should kick off
      tick_result = @game.tick change_direction_requested: inputs.mouse.click

      # if the player captured a "good" square, then queue up the animation
      # of the "good" square
      if tick_result.score_occurred
        @scale_down_particles_queue << square_prefab(tick_result.scored_square).merge(start_at: Kernel.tick_count, scale_speed: -2)
      elsif tick_result.death_occurred
        # if death occured that generated the explosion animation
        # and the scale out of all the set pieces
        generate_death_particles! tick_result.all_squares
        state.best_score = state.current_score if state.current_score > state.best_score
        state.next_scene = :game_over
      end
    end

    # this function calculates the point in the time the game is over
    # an intermediary variable stored in @game.death_at is consulted
    # before transitioning to the game over scene to ensure that particle animations
    # have enough time to complete before the game over scene is rendered
    def calc_game_over_at
      return if !death_at
      return if death_at.elapsed_time < 120
      state.events.game_over_at ||= Kernel.tick_count
    end

    # this function calculates the particles
    # there are two queues of particles that are processed
    # the launch_particle_queue contains particles that are launched when the player is hit
    # the scale_down_particles_queue contains particles that need to be scaled down
    # this isn't part of the Game object because its specifically visual effects
    # and doesn't affect the game logic
    def calc_particles
      @launch_particle_queue.each do |p|
        p.x += p.launch_angle.vector_x * p.speed
        p.y += p.launch_angle.vector_y * p.speed
        p.speed *= 0.90
        p.d_a ||= 1
        p.a -= 1 * p.d_a
        p.d_a *= 1.1
      end

      @launch_particle_queue.reject! { |p| p.a <= 0 }

      @scale_down_particles_queue.each do |p|
        next if p.start_at > Kernel.tick_count
        p.scale_speed = p.scale_speed.abs
        p.x += p.scale_speed
        p.y += p.scale_speed
        p.w -= p.scale_speed * 2
        p.h -= p.scale_speed * 2
      end

      @scale_down_particles_queue.reject! { |p| p.w <= 0 }
    end

    def render
      return if !started_at
      outputs[:game_scene].w = Grid.allscreen_w
      outputs[:game_scene].h = Grid.allscreen_h
      outputs[:game_scene].primitives << score_prefab
      outputs[:game_scene].primitives << @game.movement_outer_rect.merge(path: :solid, **GRAY, a: 128)
      outputs[:game_scene].primitives << square_prefabs(@game.squares)
      outputs[:game_scene].primitives << player_prefab(@game.player)
      outputs[:game_scene].primitives << @launch_particle_queue
      outputs[:game_scene].primitives << @scale_down_particles_queue
    end

    def square_prefab s
      color = s.type == :good ? RED : BLACK
      { **s, path: :solid, **color }
    end

    def square_prefabs squares
      squares.map { |s| square_prefab s }
    end

    # this function returns the rendering primitive for the score
    def score_prefab
      score = state.current_score

      label_scale_prec = Easing.spline(@game.score_at || 0, Kernel.tick_count, 15, @score_animation_spline)
      label = { text: score, anchor_x: 0.5, anchor_y: 0.5, size_px: 128 + 50 * label_scale_prec, **RED }
      if Grid.landscape?
        Layout.rect(row: 1, col: 11, w: 2, h: 2, allscreen: true)
              .center
              .merge(label)
      else
        Layout.rect(row: 9, col: 5, w: 2, h: 2, allscreen: true)
              .center
              .merge(label)
      end
    end

    def player_prefab player
      scale_perc = if death_at
                     Easing.smooth_stop(start_at: death_at, duration: 15, tick_count: Kernel.tick_count, power: 2)
                   else
                     Easing.smooth_start(start_at: started_at + 30, duration: 15, tick_count: Kernel.tick_count, power: 2, flip: true)
                   end

      player.merge(x: player.x + player.w / 2 * scale_perc,
                   y: player.y + player.h / 2 * scale_perc,
                   w: player.w * (1 - scale_perc),
                   h: player.h * (1 - scale_perc),
                   path: :solid,
                   **RED,
                   a: 255 * (1 - scale_perc))
    end

    # determines if score should be incremented or if the game should be over
    # this function generates the particles when the player is hit
    def generate_death_particles! all_squares
      # create a prefab for each square/set piece and queue them
      # up to fade out
      square_particles = square_prefabs(all_squares).map do |b|
        b.merge(start_at: Kernel.tick_count + 60, scale_speed: -1)
      end

      @scale_down_particles_queue.concat square_particles

      # use the starting player prefab and generate the explosion
      player_prefab_base = player_prefab(@game.player)

      # generate 12 particles with random size, launch angle and speed
      player_particles = 12.map do
        size = rand * @game.player.h * 0.5 + 10
        player_prefab_base.merge(w: size,
                                 h: size,
                                 a: 255,
                                 launch_angle: rand * 180, speed: 10 + rand * 50,
                                 path: :solid,
                                 **RED)
      end

      @launch_particle_queue.concat player_particles
    end

    # death_at is the point in time that the player died
    # the death_at value is an intermediary variable that is used to calculate the death animation
    # before setting state.game_over_at
    def death_at
      return nil if !@game.death_at
      return nil if @game.death_at < started_at
      @game.death_at
    end

    # started_at is the point in time that the player started (or retried) the game
    def started_at
      state.events.game_retried_at || state.events.game_started_at
    end
  end

  # This class encapsulates the logic of a button that pulses when clicked.
  # It is used in the StartScene and GameOverScene classes.
  class PulseButton
    attr :rect, :text, :on_click, :clicked_at

    # a block is passed into the constructor and is called when the button is clicked,
    # and after the pulse animation is complete
    def initialize rect, text, &on_click
      @rect = rect
      @text = text
      @on_click = on_click
      @pulse_animation_spline = [[0.0, 0.90, 1.0, 1.0], [1.0, 0.10, 0.0, 0.0]]
      @animation_duration = 10
    end

    # the button is ticked every frame and check to see if the mouse
    # intersects the button's bounding box.
    # if it does, then pertinent information is stored in the @clicked_at variable
    # which is used to calculate the pulse animation
    def tick mouse
      if @clicked_at && @clicked_at.elapsed_time > @animation_duration
        @clicked_at = nil
        @on_click.call
      end

      mouse_rect = { x: mouse.x + Grid.allscreen_offset_x, y: mouse.y + Grid.allscreen_offset_y }
      return if !mouse.click
      return if !Geometry.inside_rect? mouse_rect, @rect
      @clicked_at = Kernel.tick_count
    end

    # this function returns an array of primitives that can be rendered
    def prefab
      # calculate the percentage of the pulse animation that has completed
      # and use the percentage to compute the size and position of the button
      perc = if @clicked_at
               Easing.spline @clicked_at, Kernel.tick_count, @animation_duration, @pulse_animation_spline
             else
               0
             end

      center = { x: @rect.x + @rect.w / 2, y: @rect.y + @rect.h / 2, anchor_x: 0.5, anchor_y: 0.5 }

      [
        { **center,
          w: @rect.w + 50 * perc,
          h: @rect.h + 50 * perc,
          path: :solid },
        { **center, text: @text, size_px: 32 }
      ]
    end
  end

```

### Twinstick - main.rb
```ruby
  # ./samples/99_genre_arcade/twinstick/app/main.rb
  class Game
    attr_gtk

    def initialize args
      @on_screen_gamepad_left = OnScreenGamepad.new args.inputs, side: :left
      @on_screen_gamepad_right = OnScreenGamepad.new args.inputs, side: :right
      reset_game
    end

    def reset_game
      @player = { x: 600, y: 320, w: 80, h: 80,
                  path: 'sprites/circle/solid.png',
                  vx: 0,
                  vy: 0,
                  health: 10,
                  health_perc: 1.0,
                  cooldown: 0,
                  score: 0 }
      @spawn_timer = 120
      @enemies = []
      @bullets = []
    end

    def tick
      @on_screen_gamepad_left.tick
      @on_screen_gamepad_right.tick
      spawn_enemies
      kill_enemies
      move_enemies
      move_bullets
      move_player
      fire_player
      render
      calc_game_over
    end

    def calc_game_over
      if @player.health < 0
        reset_game
      end
    end

    def render
      outputs.background_color = [30, 30, 30]

      outputs.primitives << [@player, @enemies, @bullets]

      progress_bar = Geometry.rect(
        x: @player.x + 40,
        y: @player.y + 80 + 32,
        w: 256,
        h: 32,
        anchor_x: 0.5,
        anchor_y: 0.5,
      ).merge(r: 0, g: 0, b: 0, path: :solid)

      health_area = Geometry.zoom_rect(rect: progress_bar, px: -8)
      current_health = { **health_area, w: health_area.w * @player.health_perc }

      outputs.primitives << progress_bar
      outputs.primitives << health_area.merge(r: 255, g: 255, b: 255, path: :solid)
      outputs.primitives << current_health.merge(r: 80, g: 155, b: 80, path: :solid)

      if DR.platform?(:touch)
        outputs.primitives << { x: 640, y: 720, text: "Finger on left side of screen to move. Finger on right side of screen to shoot.", anchor_x: 0.5, anchor_y: 1.5, r: 255, g: 255, b: 255 }
      elsif inputs.last_active == :keyboard || inputs.last_active == :mouse
        outputs.primitives << { x: 640, y: 720, text: "WASD to move, Arrow Keys to shoot.", anchor_x: 0.5, anchor_y: 1.5, r: 255, g: 255, b: 255 }
      elsif inputs.last_active == :controller
        outputs.primitives << { x: 640, y: 720, text: "Left Analog to move, Right Analog to shoot.", anchor_x: 0.5, anchor_y: 1.5, r: 255, g: 255, b: 255 }
      end

      outputs.primitives << @on_screen_gamepad_left.primitives
      outputs.primitives << @on_screen_gamepad_right.primitives
    end

    def health_progress_bar_primitives

    end

    def spawn_enemies
      should_spawn_enemy ||= Kernel.tick_count == 0
      should_spawn_enemy ||= Kernel.tick_count.zmod?(@spawn_timer.clamp(30, 120))
      return if !should_spawn_enemy

      angle = rand 360
      @enemies << {
        x: 600 + angle.vector_x * 800,
        y: 320 + angle.vector_y * 800,
        w: 80, h: 80, path: "sprites/circle/solid.png",
        r: 128 + rand(128), g: 128 + rand(128), b: 128 + rand(128)
      }
    end

    def kill_enemies
      enemy_collision = Geometry.find_intersect_rect(@player, @enemies)
      if enemy_collision
        @enemies.delete enemy_collision
        @player.health -= 1
      end

      @bullets.each do |bullet|
        bullet_collision = Geometry.find_intersect_rect(bullet, @enemies)
        next if !bullet_collision

        @enemies.delete bullet_collision
        bullet.kills ||= 0
        bullet.kills += 1
        @player.score += bullet.kills
        @spawn_timer -= bullet.kills * 2
        @player.health += 1 if @player.health < 10 && bullet.kills > 1
      end

      @player.health_perc = @player.health_perc.lerp(@player.health.fdiv(10), 0.1)
    end

    def move_enemies
      @enemies.each do |enemy|
        angle = Geometry.angle @player, enemy
        enemy.x -= angle.vector_x * 2.5
        enemy.y -= angle.vector_y * 2.5
      end
    end

    def move_bullets
      @bullets.each do |bullet|
        bullet.x += bullet.vx
        bullet.y += bullet.vy
      end

      @bullets.reject! do |bullet|
        bullet.x < -20 || bullet.y < -20 || bullet.x > 1300 || bullet.y > 740
      end
    end

    def move_player
      @player.vx = @player.vx * 0.9
      @player.vy = @player.vy * 0.9

      @player.x += @player.vx
      @player.y += @player.vy
      @player.x = @player.x.clamp 0, 1200
      @player.y = @player.y.clamp 0, 640

      dir = inputs.keyboard.directional_vector_wasd ||
            inputs.controller_one.directional_vector_left_analog_cardinal ||
            @on_screen_gamepad_left.dpad_vector

      return if !dir

      @player.vx += dir.x * 0.75
      @player.vy += dir.y * 0.75
    end

    def fire_player
      @player.cooldown -= 1

      return if @player.cooldown > 0

      dir = inputs.keyboard.directional_vector_arrow ||
            inputs.controller_one.directional_vector_right_analog_cardinal ||
            @on_screen_gamepad_right.dpad_vector

      return if !dir

      @bullets << {
        x: @player.x + 30 + 40 * dir.x,
        y: @player.y + 30 + 40 * dir.y,
        w: 20, h: 20, path: "sprites/circle/solid.png", r: 232, g: 232, b: 232,
        vx: dir.x * 10 + @player.vx / 7.5, vy: dir.y * 10 + @player.vy / 7.5
      }

      @player.cooldown = 30
    end
  end

  module Main
    def tick args
      @game ||= Game.new args
      @game.args = args
      @game.tick
    end

    def reset args
      @game = nil
    end
  end

  # On screen game pad implementation from DragonRuby's sample code
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


  GTK.reset

```

### Twinstick Gamepad - main.rb
```ruby
  # ./samples/99_genre_arcade/twinstick_gamepad/app/main.rb
  class Game
    attr_dr

    def defaults
      state.player ||= { x: 640,
                         y: 360,
                         w: 80,
                         h: 80,
                         dx: 0,
                         dy: 0,
                         max_speed: 5,
                         anchor_x: 0.5,
                         anchor_y: 0.5,
                         angle: 0 }
      state.bullets ||= []
    end

    def tick
      defaults
      calc
      render
    end

    def calc
      calc_player
      calc_bullets
    end

    def calc_player
      if firing_active?
        player.angle_delta = Geometry.angle_delta player.angle,
                                                  fire_angle

        player.angle += player.angle_delta * 0.25

        player.last_fired_at ||= 0

        if player.last_fired_at.elapsed_time > 10
          state.bullets << {
            x: player.x,
            y: player.y,
            w: 10,
            h: 10,
            anchor_x: 0.5,
            anchor_y: 0.5,
            angle: player.angle,
            dx: player.angle.vector_x * 10,
            dy: player.angle.vector_y * 10,
            created_at: Kernel.tick_count
          }

          player.last_fired_at = Kernel.tick_count
        end
      end

      if movement_active?
        angle = movement_angle

        player.dx += angle.vector_x * player.max_speed * 0.1
        player.dx  = player.dx.clamp(-player.max_speed, player.max_speed)
        player.dy += angle.vector_y * player.max_speed * 0.1
        player.dy  = player.dy.clamp(-player.max_speed, player.max_speed)
      end

      player.x  += player.dx
      player.y  += player.dy
      player.dx *= 0.9
      player.dy *= 0.9
    end

    def calc_bullets
      state.bullets.each do |bullet|
        bullet.x += bullet.dx
        bullet.y += bullet.dy
      end

      state.bullets.reject! do |bullet|
        bullet.created_at.elapsed_time > 120
      end
    end

    def render
      outputs.primitives << state.bullets.map do |bullet|
        bullet.merge(path: "sprites/circle/red.png")
      end

      outputs.primitives << player.merge(path: "sprites/circle/blue.png")
    end

    def player
      state.player
    end

    def movement_active?
      inputs.controller_one
            .left_analog_active?(threshold_perc: 0.5) ||
      inputs.keyboard.w_scancode ||
      inputs.keyboard.s_scancode ||
      inputs.keyboard.a_scancode ||
      inputs.keyboard.d_scancode
    end

    def firing_active?
      inputs.controller_one
            .right_analog_active?(threshold_perc: 0.5) ||
      inputs.keyboard.up_arrow   ||
      inputs.keyboard.down_arrow ||
      inputs.keyboard.left_arrow ||
      inputs.keyboard.right_arrow
    end

    def fire_angle
      if inputs.controller_one.right_analog_active?(threshold_perc: 0.5)
        (inputs.controller_one.right_analog_angle + 22).ifloor(45)
      elsif inputs.keyboard.up_arrow && inputs.keyboard.right_arrow
        45
      elsif inputs.keyboard.up_arrow && inputs.keyboard.left_arrow
        135
      elsif inputs.keyboard.down_arrow && inputs.keyboard.left_arrow
        225
      elsif inputs.keyboard.down_arrow && inputs.keyboard.right_arrow
        315
      elsif inputs.keyboard.up_arrow
        90
      elsif inputs.keyboard.down_arrow
        270
      elsif inputs.keyboard.left_arrow
        180
      elsif inputs.keyboard.right_arrow
        0
      end
    end

    def movement_angle
      if inputs.controller_one.left_analog_active?(threshold_perc: 0.5)
        inputs.controller_one.left_analog_angle
      elsif inputs.keyboard.w_scancode && inputs.keyboard.d_scancode
        45
      elsif inputs.keyboard.w_scancode && inputs.keyboard.a_scancode
        135
      elsif inputs.keyboard.s_scancode && inputs.keyboard.a_scancode
        225
      elsif inputs.keyboard.s_scancode && inputs.keyboard.d_scancode
        315
      elsif inputs.keyboard.w_scancode
        90
      elsif inputs.keyboard.s_scancode
        270
      elsif inputs.keyboard.a_scancode
        180
      elsif inputs.keyboard.d_scancode
        0
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

```
