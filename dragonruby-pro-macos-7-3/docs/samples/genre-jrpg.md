### Cutscenes - main.rb
```ruby
  # ./samples/99_genre_jrpg/cutscenes/app/main.rb
  # creation of a game class
  class Game
    attr_dr # adds arg properties to the class

    def initialize
      # have the hero start at the center and the npc be at the far right
      @hero = { x: 640,
                y: 360,
                w: 80,
                h: 80,
                look_dir: { x: 1, y: 0 },
                anchor_x: 0.5,
                anchor_y: 0.5,
                path: "sprites/square/blue.png" }

      @npc = { x: 1000,
               y: 360,
               w: 80,
               h: 80,
               anchor_x: 0.5,
               anchor_y: 0.5,
               path: "sprites/square/red.png" }

      # queue for cutscene actions
      @cutscene = []
    end

    def hero_look_angle
      # given the vector the player is looking at, return an angle
      Geometry.vec2_angle(@hero.look_dir)
    end

    def hero_interaction_box
      # calculate the interaction hit box for the player based off of where they are looking
      @hero.intersect_box = { x: @hero.x + @hero.w / 2 * hero_look_angle.vector_x,
                              y: @hero.y + @hero.h / 2 * hero_look_angle.vector_y,
                              w: 80,
                              h: 80,
                              anchor_x: 0.5,
                              anchor_y: 0.5 }
    end

    def tick
      calc
      render
    end

    def calc
      tick_cutscene

      # if a cutscene isn't currently play, then return control to the player
      if !in_cutscene?
        calc_facing
        calc_movement
        calc_interaction
      end
    end

    def tick_cutscene
      # if the cutscene array is empty then skip
      return if @cutscene.length == 0

      # loop through all the cutscene items and compute the start_at and end_at times
      # based off of the relative frame timings
      @cutscene.each do |scene|
        scene.start_at ||= scene.frame_start_at + Kernel.tick_count
        scene.end_at   ||= scene.frame_end_at + Kernel.tick_count
      end

      # get all cutscene actions that are active
      scenes_to_tick = @cutscene.find_all { |scene| scene.start_at <= Kernel.tick_count }

      # for each of those actions, run them
      scenes_to_tick.each { |scene| scene.run.call }

      # remove any actions that have completed
      @cutscene.reject! { |scene| scene.end_at <= Kernel.tick_count }
    end

    def calc_interaction
      # return if the player hasn't pressed a on the controller or space on the keyboard
      return if !interaction_requested?

      # if interaction is requested and the hero's interaction box
      # intersects with the npc, then queue cutscene actions
      if Geometry.intersect_rect?(hero_interaction_box, @npc)
        @cutscene = [
          # from frame 1 to 60 (over one second), have the npc move up
          { frame_start_at: 0, frame_end_at:  60, run: lambda { @npc.y += 5  } },
          # from frame 60 to 120, have the hero move down
          { frame_start_at: 60, frame_end_at: 120, run: lambda { @hero.y -= 5 } },
          # then move both back at the same time
          { frame_start_at: 120, frame_end_at: 180, run: lambda { @npc.y -= 5  } },
          { frame_start_at: 120, frame_end_at: 180, run: lambda { @hero.y += 5  } },
        ]
      end
    end

    def interaction_requested?
      inputs.controller_one.key_down.a || inputs.keyboard.key_down.space
    end

    # you are considered to be in a cutscene
    def in_cutscene?
      @cutscene && !@cutscene.empty?
    end

    def calc_facing
      # compute the direction the player is facing based off of input
      # the direction the player is facing only changes if only one
      # key is down between up, down, left, and right
      return if inputs.left_right != 0 && inputs.up_down != 0
      @hero.look_dir = { x: inputs.left_right, y: inputs.up_down }
    end

    def calc_movement
      # axis aligned bounding box movement (player can't overlap with the npc)o

      # first set the hero's x location based off of horizontal movement
      # we use the &.x safe operation because directional vector will return
      # nil if there is no directional input
      # this horizontal movement vector is multipled by 5 which represents
      # the player's speed
      @hero.x += (inputs.directional_vector&.x || 0) * 5

      # after the player is moved, check collision on the horizontal plane (standard AABB processing)
      if Geometry.intersect_rect?(@hero, @npc)
        if @hero.x < @npc.x
          @hero.x = @npc.x - @hero.w
        else
          @hero.x = @npc.x + @hero.w
        end
      end

      # now do the same for the player movement on the vertical access
      @hero.y += (inputs.controller_one.directional_vector&.y || 0) * 5

      if Geometry.intersect_rect?(@hero, @npc)
        if @hero.y < @npc.y
          @hero.y = @npc.y - @hero.h
        else
          @hero.y = @npc.y + @hero.h
        end
      end
    end

    def render
      # render the player, player's interaction box, npc, and instructions
      outputs.primitives << hero_interaction_box.merge(path: :solid, r: 255, g: 0, b: 0)
      outputs.primitives << @hero.merge(angle: hero_look_angle)
      outputs.primitives << @npc
      outputs.primitives << { x: 640,
                              y: 640,
                              text: "Interact with NPC to start cutscene",
                              anchor_x: 0.5,
                              anchor_y: 0.5,
                              size_px: 26 }
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

### Turn Based Battle - main.rb
```ruby
  # ./samples/99_genre_jrpg/turn_based_battle/app/main.rb
  def tick args
    args.state.phase ||= :selecting_top_level_action
    args.state.potential_action ||= :attack
    args.state.currently_acting_hero_index ||= 0
    args.state.enemies ||= [
      { name: "Goblin A" },
      { name: "Goblin B" },
      { name: "Goblin C" }
    ]

    args.state.heroes ||= [
      { name: "Hero A" },
      { name: "Hero B" },
      { name: "Hero C" }
    ]

    args.state.potential_enemy_index ||= 0

    if args.state.phase == :selecting_top_level_action
      if args.inputs.keyboard.key_down.down
        case args.state.potential_action
        when :attack
          args.state.potential_action = :special
        when :special
          args.state.potential_action = :magic
        when :magic
          args.state.potential_action = :items
        when :items
          args.state.potential_action = :items
        end
      elsif args.inputs.keyboard.key_down.up
        case args.state.potential_action
        when :attack
          args.state.potential_action = :attack
        when :special
          args.state.potential_action = :attack
        when :magic
          args.state.potential_action = :special
        when :items
          args.state.potential_action = :magic
        end
      end

      if args.inputs.keyboard.key_down.enter
        args.state.selected_action = args.state.potential_action
        args.state.next_phase = :selecting_target
      end
    end

    if args.state.phase == :selecting_target
      if args.inputs.keyboard.key_down.left
        select_previous_live_enemy args
      elsif args.inputs.keyboard.key_down.right
        select_next_live_enemy args
      end

      args.state.potential_enemy_index = args.state.potential_enemy_index.clamp(0, args.state.enemies.length - 1)

      if args.inputs.keyboard.key_down.enter
        args.state.enemies[args.state.potential_enemy_index].dead = true
        args.state.potential_enemy_index = args.state.enemies.find_index { |e| !e.dead }
        args.state.selected_action = nil
        args.state.potential_action = :attack
        args.state.next_phase = :selecting_top_level_action
        args.state.currently_acting_hero_index += 1
        if args.state.currently_acting_hero_index >= args.state.heroes.length
          args.state.currently_acting_hero_index = 0
        end
      end
    end

    if args.state.next_phase
      args.state.phase = args.state.next_phase
      args.state.next_phase = nil
    end

    render_actions_menu args
    render_enemies args
    render_heroes args
    render_hero_statuses args
  end

  def select_next_live_enemy args
    next_target_index = args.state.enemies.find_index.with_index { |e, i| !e.dead && i > args.state.potential_enemy_index }
    if next_target_index
      args.state.potential_enemy_index = next_target_index
    end
  end

  def select_previous_live_enemy args
    args.state.potential_enemy_index -= 1
    if args.state.potential_enemy_index < 0
      args.state.potential_enemy_index = 0
    elsif args.state.enemies[args.state.potential_enemy_index].dead
      select_previous_live_enemy args
    end
  end

  def render_actions_menu args
    args.outputs.borders << Layout.rect(row:  8, col: 0, w: 4, h: 4, include_row_gutter: true, include_col_gutter: true)
    if !args.state.selected_action
      selected_rect = if args.state.potential_action == :attack
                        Layout.rect(row:  8, col: 0, w: 4, h: 1)
                      elsif args.state.potential_action == :special
                        Layout.rect(row:  9, col: 0, w: 4, h: 1)
                      elsif args.state.potential_action == :magic
                        Layout.rect(row: 10, col: 0, w: 4, h: 1)
                      elsif args.state.potential_action == :items
                        Layout.rect(row: 11, col: 0, w: 4, h: 1)
                      end

      args.outputs.solids  << selected_rect.merge(r: 200, g: 200, b: 200)
    end

    args.outputs.borders << Layout.rect(row:  8, col: 0, w: 4, h: 1)
    args.outputs.labels  << Layout.rect(row:  8, col: 0, w: 4, h: 1).center.merge(text: "Attack", vertical_alignment_enum: 1, alignment_enum: 1)

    args.outputs.borders << Layout.rect(row:  9, col: 0, w: 4, h: 1)
    args.outputs.labels  << Layout.rect(row:  9, col: 0, w: 4, h: 1).center.merge(text: "Special", vertical_alignment_enum: 1, alignment_enum: 1)

    args.outputs.borders << Layout.rect(row: 10, col: 0, w: 4, h: 1)
    args.outputs.labels  << Layout.rect(row: 10, col: 0, w: 4, h: 1).center.merge(text: "Magic", vertical_alignment_enum: 1, alignment_enum: 1)

    args.outputs.borders << Layout.rect(row: 11, col: 0, w: 4, h: 1)
    args.outputs.labels  << Layout.rect(row: 11, col: 0, w: 4, h: 1).center.merge(text: "Items", vertical_alignment_enum: 1, alignment_enum: 1)
  end

  def render_enemies args
    args.outputs.primitives << args.state.enemies.map_with_index do |e, i|
      if e.dead
        nil
      elsif i == args.state.potential_enemy_index && args.state.phase == :selecting_target
        [
          Layout.rect(row: 1, col: 9 + i * 2, w: 2, h: 2).solid!(r: 200, g: 200, b: 200),
          Layout.rect(row: 1, col: 9 + i * 2, w: 2, h: 2).border!,
          Layout.rect(row: 1, col: 9 + i * 2, w: 2, h: 2).center.label!(text: "#{e.name}", vertical_alignment_enum: 1, alignment_enum: 1)
        ]
      else
        [
          Layout.rect(row: 1, col: 9 + i * 2, w: 2, h: 2).border!,
          Layout.rect(row: 1, col: 9 + i * 2, w: 2, h: 2).center.label!(text: "#{e.name}", vertical_alignment_enum: 1, alignment_enum: 1)
        ]
      end
    end
  end

  def render_heroes args
    args.outputs.primitives << args.state.heroes.map_with_index do |h, i|
      if i == args.state.currently_acting_hero_index
        [
          Layout.rect(row: 5, col: 9 + i * 2, w: 2, h: 2).solid!(r: 200, g: 200, b: 200),
          Layout.rect(row: 5, col: 9 + i * 2, w: 2, h: 2).border!,
          Layout.rect(row: 5, col: 9 + i * 2, w: 2, h: 2).center.label!(text: "#{h.name}", vertical_alignment_enum: 1, alignment_enum: 1)
        ]
      else
        [
          Layout.rect(row: 5, col: 9 + i * 2, w: 2, h: 2).border!,
          Layout.rect(row: 5, col: 9 + i * 2, w: 2, h: 2).center.label!(text: "#{h.name}", vertical_alignment_enum: 1, alignment_enum: 1)
        ]
      end
    end
  end

  def render_hero_statuses args
    args.outputs.borders << Layout.rect(row: 8, col: 4, w: 20, h: 4, include_col_gutter: true, include_row_gutter: true)
  end

  DR.reset

```
