### Alchemy Game Starting Point - main.rb
```ruby
  # ./samples/99_genre_crafting/alchemy_game_starting_point/app/main.rb
  # A collection of function related to elements of natrue
  class Element
    # returns the tile size in pixels { w:, h: }
    # Layout::rect is a virtual grid that is 24 columns by 12 rows
    def self.tile_size
      Layout::rect(w: 1, h: 1)
             .slice(:w, :h)
    end

    # given a point/position in pixels, returns a rect with
    # { x:, y:, w:, h:, center: { x:, y: } }
    def self.tile_rect x:, y:, anchor_x: 0, anchor_y: 0, **ignore
      w, h = tile_size.values_at(:w, :h)
      Geometry.rect_props x: x - w * anchor_x,
                          y: y - h * anchor_y,
                          w: w,
                          h: h
    end

    # given a element, and it's position, this fucntion
    # returns render primitives that represent the element
    # visually
    def self.prefab_icon element, x:, y:, anchor_x: 0, anchor_y: 0, **ignore
      # if the element is decorated with an added_at property,
      # it means that we want to apply a fade in effect to the
      # prefab
      a = if element.added_at && element.added_at.elapsed_time < 60
            # fade in slow to fast over 1 second
            perc = Easing.ease element.added_at, Kernel.tick_count, 60, :smooth_start_quint
            255 * perc
          else
            255
          end

      # given the elements position, create a tile rect with the sprite and alpha
      tile_rect(x: x, y: y).merge(path: "sprites/square/#{element.name}.png", a: a)
    end

    # this represents the element prefab it its entirety
    # the sprite, a background rect and a text label above the
    # background rect
    def self.prefab element, position, shift_x: 0, shift_y: 0
      rect = tile_rect x: position.x + shift_x,
                       y: position.y + shift_y

      [
        # icon
        prefab_icon(element, x: position.x, y: position.y),
        # background rect
        rect.merge(path: :solid, h: 16, r: 0, g: 0, b: 0, a: 200),
        # text label
        {
          x: rect.center.x,
          y: rect.y,
          text: "#{element.name}",
          anchor_x: 0.5,
          anchor_y: 0,
          size_px: 16,
          r: 255,
          g: 255,
          b: 255
        },

        # white border
        rect.merge(primitive_marker: :border, r: 255, g: 255, b: 255)
      ]
    end

    # given a collection of elements,
    # this function returns a collection of grouped elements
    # (elements that are intersecting each other, or connected
    # to each other, because of a mutual neighbor element)
    def self.create_groupings elements
      grouped_elements = []

      rects_with_source = elements.map do |r|
        r.rect.merge(source: r)
      end

      rects_with_source.each do |r|
        grouped = grouped_elements.find do |g|
          g.any? { |i| i.intersect_rect? r }
        end

        if !grouped
          grouped_elements << [r]
        else
          grouped << r
        end
      end

      grouped_elements.map do |e|
        e.map { |r| r.source }
      end.uniq
    end
  end

  class Game
    attr_dr

    def tick
      defaults
      calc
      render
    end

    def defaults
      # elements of nature and what they require to be created
      state.elements ||= [
        { name: :violet,  requires: [:red, :blue, :black] },
        { name: :indigo,  requires: [:red, :blue, :white] },
        { name: :gray,    requires: [:white, :black] },
        { name: :green,   requires: [:blue, :yellow] },
        { name: :orange,  requires: [:red, :yellow] },
      ]

      # elements that have been discovered seeded with the basic elements
      state.discovered_elements ||= [
        { name: :white },
        { name: :black },
        { name: :red },
        { name: :yellow },
        { name: :blue },
      ]

      # the canvas area where elements are placed/mixed
      state.canvas ||= {
        rect: Layout::rect(row: 0, col: 0, w: 20, h: 12),
        elements: []
      }

      # fx queue for faiding out sprites
      state.fade_out_queue ||= []

      # fx queue for mouse particles
      state.mouse_particles_queue ||= []

      # invalid mixtures queue (used to signal invalid mixtures)
      state.invalid_mixtures_queue ||= []
    end

    # adds a clone of an element to the canvas area
    # used by mouse movement and click events
    # and element discovery
    def add_element_to_canvas! element, position, fade_in: false
      return if !element
      new_entry = element.copy
      new_entry.added_at = Kernel.tick_count if fade_in
      new_entry.position = { x: position.x, y: position.y }
      state.canvas.elements << new_entry
      new_entry
    end

    def input_mouse
      # if the mouse is clicked...
      if inputs.mouse.down
        # check to see if any of the elements in the toolbar
        # were clicked, if so, set the selected element to the
        # clicked element
        toolbar_element = state.discovered_elements
                               .find do |r|
                                 inputs.mouse.intersect_rect? r.rect
                               end

        if toolbar_element
          state.selected_element = toolbar_element
        end

        # if no toolbar element was clicked, then check to see
        # if an element on the canvas was clicked
        if !state.selected_element
          state.selected_element = state.canvas.elements.reverse.find do |r|
            inputs.mouse.intersect_rect? r.rect
          end

          # if an element was clicked, remove it from the canvas
          if state.selected_element
            state.canvas.elements.reject! { |r| r == state.selected_element }
          end
        end

        if state.selected_element
          state.selected_element = state.selected_element.copy
        end
      elsif inputs.mouse.held && inputs.mouse.moved
        # emit pretty particles when the mouse is held and moved
        if Kernel.tick_count.zmod? 2
          state.mouse_particles_queue << {
            x: inputs.mouse.x + 10.randomize(:ratio, :sign),
            y: inputs.mouse.y + 10.randomize(:ratio, :sign),
            w: 10, h: 10, path: "sprites/star.png"
          }
        end
      elsif inputs.mouse.up
        if state.selected_element
          # if mouse is released,
          # cr
          if inputs.mouse.intersect_rect?(state.canvas.rect)
            rect = Element.tile_rect(x: inputs.mouse.up.x,
                                     y: inputs.mouse.up.y,
                                     anchor_x: 0.5,
                                     anchor_y: 0.5)


            # add the element to the canvas area and create particles
            # around the element drop
            created_element = add_element_to_canvas! state.selected_element, rect

            # get all intersecting elements with the element that was just being dragged
            intersecting_elements = state.canvas.elements.find_all do |element|
              element != created_element && Geometry::intersect_rect?(element.rect, created_element.rect)
            end

            # shake elements if the element doesn't have any potential interactions
            notify_invalid_mixture! created_element, intersecting_elements

            state.mouse_particles_queue.concat(30.map do |i|
                                                 { x: rect.center.x + 10.randomize(:ratio, :sign),
                                                   y: rect.center.y + 10.randomize(:ratio, :sign),
                                                   start_at: Kernel.tick_count + i + rand(2),
                                                   w: 10, h: 10, path: "sprites/star.png" }
                                               end)

          else
            # if the mouse was released outside of the canvas area
            # then delete the element/remove it from the canvas
            w, h = Element.tile_size.values_at(:w, :h)

            # add the element to the fade out queue
            state.fade_out_queue << Element.prefab_icon(state.selected_element,
                                                        x: inputs.mouse.up.x - w / 2,
                                                        y: inputs.mouse.up.y - h / 2,
                                                        anchor_x: 0.5,
                                                        anchor_y: 0.5)
          end
        end

        state.selected_element = nil
      end
    end

    def notify_invalid_mixture! source, intersecting_elements
      return if intersecting_elements.length == 0

      # look through all the intersecting elements
      # see if any of their requirements match the source element
      # or the intersecting element
      possible = intersecting_elements.any? do |r|
        state.elements.any? do |sr|
          sr.requires.include?(source.name) &&
          sr.requires.include?(r.name)
        end
      end

      # check to see if the source element and the intersecting element
      # are of the same type
      duplicate_ids = intersecting_elements.any? { |r| r.name == source.name }

      # play an error sound if the requirements for interactions don't match,
      # or if duplicate elements are touching
      if !possible || duplicate_ids
        state.invalid_mixtures_queue << { ref_id: source.object_id, at: Kernel.tick_count }
        intersecting_elements.each do |r|
          state.invalid_mixtures_queue << { ref_id: r.object_id, at: Kernel.tick_count }
        end
      end
    end

    def calc
      calc_collision_bodies
      input_mouse
      calc_discovered_elements
      calc_queues
      calc_collision_bodies
    end

    def calc_queues
      # process the fade out queue
      state.fade_out_queue.each do |fx|
        fx.dx ||= 0.1
        fx.dy ||= 0.1
        fx.a ||= 255
        fx.a -= 5
        fx.x += fx.dx
        fx.y += fx.dy
        fx.w -= fx.dx * 2 if fx.w > 0
        fx.h -= fx.dy * 2 if fx.h > 0
        fx.dx *= 1.1
        fx.dy *= 1.1
      end

      state.fade_out_queue.reject! { |fx| fx.a <= 0 }

      # process the mouse particles queue
      state.mouse_particles_queue.each do |mp|
        mp.start_at ||= Kernel.tick_count
        mp.a ||= 255
        if mp.start_at < Kernel.tick_count
          mp.dx ||= 1.randomize(:ratio, :sign)
          mp.dy ||= 1.randomize(:ratio, :sign)
          mp.x += mp.dx
          mp.y += mp.dy
          mp.a -= 5
          mp.dx *= 1.05
          mp.dy *= 1.05
        end
      end

      state.mouse_particles_queue.reject! { |mp| mp.a <= 0 }

      state.invalid_mixtures_queue.reject! do |fx|
        fx.at.elapsed_time > 15
      end
    end

    def calc_discovered_elements
      groups = Element.create_groupings state.canvas.elements

      while groups.length > 0
        # pop a group of elements from the groups array
        group = groups.pop

        # for all the elements, get their names, this
        # represets the collection of elements that are
        # needed for other elements to be created (based on their requirements)
        keys = group.map { |g| g.name }
        completed_element = nil

        # for all elements, check their requires, and see if
        # the group of elements that are touching match
        state.elements.each do |r|
          if r.requires.uniq - keys == []
            completed_element = r
            break
          end
        end

        # if an element can be created, then remove the elements
        # that were used to create the element
        if completed_element
          to_remove = []
          completed_element.requires.each do |r|
            group.each do |g|
              if r == g.name
                to_remove << g
                break
              end
            end
          end

          # compute the general center of the cluster of elements
          min_x = to_remove.map { |i| i.position.x }.min
          min_y = to_remove.map { |i| i.position.y }.min
          max_x = to_remove.map { |i| i.position.x }.max
          max_y = to_remove.map { |i| i.position.y }.max
          avg_x = (min_x + max_x) / 2
          avg_y = (min_y + max_y) / 2

          # remove each used element from the canvas
          # fade them out, and add the new element to the canvas
          to_remove.each do |r|
            state.canvas.elements.reject! { |i| i == r }
            state.fade_out_queue << Element.prefab_icon(r, r.position)

            add_element_to_canvas!(completed_element,
                                   Element.tile_rect(x: avg_x, y: avg_y),
                                   fade_in: true)
          end

          # if the newly created element is not in the list of discovered elements
          # then add it to the list of discovered elements
          if state.discovered_elements.none? { |i| i.name == completed_element.name }
            state.discovered_elements << { name: completed_element.name, added_at: Kernel.tick_count }
          end
        end
      end
    end

    def calc_collision_bodies
      state.discovered_elements.each_with_index do |e, i|
        r = Layout::rect(row: i, col: 20, w: 1, h: 1)
        e.merge! rect: Layout::rect(row: i, col: 20, w: 1, h: 1),
                 position: r.slice(:x, :y)
      end

      state.canvas.elements.each do |e|
        r = Element.tile_rect(e.position)
        e.merge! rect: r,
                 position: r.slice(:x, :y)
      end

      if state.selected_element
        r = Element.tile_rect(x: inputs.mouse.position.x, y: inputs.mouse.position.y, anchor_x: 0.5, anchor_y: 0.5)
        state.selected_element.merge!(rect: r, position: r.slice(:x, :y))
      end
    end

    def render
      render_bg
      render_toolbar
      render_canvas_elements
      render_selected_element
      render_queues
    end

    def render_queues
      outputs.primitives << state.fade_out_queue
      outputs.primitives << state.mouse_particles_queue.reject { |mp| mp.start_at > Kernel.tick_count }
    end

    def render_selected_element
      # if an element is selected, render it at the mouse position
      if state.selected_element
        w, h = Layout::rect(w: 1, h: 1).values_at(:w, :h)
        outputs.primitives << Element.prefab(state.selected_element,
                                             x: inputs.mouse.x - w / 2,
                                             y: inputs.mouse.y - h / 2)
      end
    end

    def render_bg
      # black letterbox
      outputs.background_color = [0, 0, 0]

      # canvas area with lighter purple
      outputs.primitives << Layout::rect(row: 0, col:  0, w: 20, h: 12).merge(path: :solid, r: 59, g: 58, b: 97)

      # toolbar area with darker purple
      outputs.primitives << Layout::rect(row: 0, col: 20, w: 4, h: 12).merge(path: :solid, r: 59, g: 58, b: 80)

      # border around the canvas area
      outputs.primitives << state.canvas.rect.merge(primitive_marker: :border, r: 255, g: 255, b: 255)
    end

    def render_toolbar
      unique_elements = (state.elements.map { |r| r.name } +
                         state.discovered_elements.map { |r| r.name }).uniq
      outputs.primitives << unique_elements.length.map.with_index do |r, i|
        if i <= state.discovered_elements.length - 1
          nil
        else
          # for all undiscovered elements, create a placeholder question mark box
          Layout::rect(row: i, col: 20)
                 .yield_self do |r|
                   [
                     r.merge(primitive_marker: :border, r: 255, g: 255, b: 255),
                     r.center.merge(text: "?", anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255)
                   ]
                 end
        end
      end

      # create a prefab for each discovered element
      outputs.primitives << state.discovered_elements.map.with_index do |r, i|
        hover = if inputs.mouse.intersect_rect? r.rect
                  r.rect.merge(path: :solid, r: 0, g: 80, b: 80, a: 100)
                end

        [Element.prefab(r, r.position), hover]
      end
    end

    def render_canvas_elements
      if inputs.mouse.held && state.selected_element
        grouped_elements = Element.create_groupings(state.canvas.elements)

        # get all elements that are connected to the selected element
        # (ie intersecting with the mouse)
        connected_to_mouse = grouped_elements.find_all do |g|
          g.find { |e| Geometry::intersect_rect? state.selected_element.rect, e.rect }
        end.flatten

        outputs.primitives << state.canvas.elements.map do |element|
          is_part_of_invalid_mixture = state.invalid_mixtures_queue.any? { |i| i.ref_id == element.object_id }

          shift_x, shift_y = if is_part_of_invalid_mixture
                               [5.randomize(:ratio, :sign), 5.randomize(:ratio, :sign)]
                             else
                               [0, 0]
                             end

          pre = Element.prefab element, element.position, shift_x: shift_x, shift_y: shift_y
          # if the element that is about to be rendered is connected to the selected element
          # then render it with a hover effect
          hover = if state.selected_element && connected_to_mouse.any? { |i| i == element }
                    element.rect.merge(path: :solid, r: 0, g: 80, b: 80, a: 100)
                  end
          [pre, hover]
        end
      else
        # hover effect for mouse intersecting topmost element
        mouse_intersecting_element = if !inputs.mouse.held
                                       state.canvas.elements.reverse.find do |element|
                                         Geometry::intersect_rect? inputs.mouse, element.rect
                                       end
                                     end

        outputs.primitives << state.canvas.elements.map do |element|
          is_part_of_invalid_mixture = state.invalid_mixtures_queue.any? { |i| i.ref_id == element.object_id }

          shift_x, shift_y = if is_part_of_invalid_mixture
                               [5.randomize(:ratio, :sign), 5.randomize(:ratio, :sign)]
                             else
                               [0, 0]
                             end

          pre = Element.prefab element, element.position, shift_x: shift_x, shift_y: shift_y
          hover = if mouse_intersecting_element == element
                    element.rect.merge(path: :solid, r: 0, g: 80, b: 80, a: 100)
                  end
          [pre, hover]
        end
      end
    end
  end

  $game = Game.new
  def tick args
    $game.args = args
    $game.tick
  end

```

### Cooking Game Starting Point - main.rb
```ruby
  # ./samples/99_genre_crafting/cooking_game_starting_point/app/main.rb
  class Game
    attr_dr

    def initialize
      @ingredients_in_hand = []
      @available_ingredients = [
        :flour,
        :baking_soda,
        :sugar,
        :flour,
        :baking_soda,
        :sugar
      ]
    end

    def tick
      calc
      render
    end

    def ingredient_selection_prefabs
      @available_ingredients.map.with_index do |ingredient, index|
        ingredient_selection_prefab(
          id: ingredient,
          index: index)
      end
    end

    def ingredients_in_hand_prefabs
      @ingredients_in_hand.map.with_index do |ingredient, index|
        render_box = Layout.rect(col: 11, row: 4 - index, w: 2, h: 2)
        {
          id: ingredient,
          index: index,
          render_box: render_box,
          primitives: [
            render_box.merge(path: "sprites/square/green.png", a: 128),
            render_box.center.merge(text: ingredient.to_s.split('_').map(&:capitalize).join(' '),
                                    anchor_x: 0.5,
                                    anchor_y: 0.5)
          ]
        }
      end
    end

    def cook_ingredients_in_hand_prefab
      render_box = Layout.rect(col: 10, row: 7, w: 4, h: 2)
      {
        id: :cook_ingredients_in_hand,
        render_box: render_box,
        primitives: [
          render_box.merge(path: :solid, r: 255, g: 255, b: 255),
          render_box.center.merge(text: "Cook Ingredients", anchor_x: 0.5, anchor_y: 0.5)
        ]
      }
    end

    def calc
      select_ingredient!
      cook_ingredients_in_hand!
    end

    def select_ingredient!
      @hovered_ingredient_selection = ingredient_selection_prefabs.find { |i| Geometry.intersect_rect? inputs.mouse, i.render_box }

      if inputs.mouse.click && @hovered_ingredient_selection
        @available_ingredients.delete_at @hovered_ingredient_selection.index
        @ingredients_in_hand << @hovered_ingredient_selection.id
      end
    end

    def cook_ingredients_in_hand!
      return if !inputs.mouse.click
      return if !Geometry.intersect_rect?(inputs.mouse, cook_ingredients_in_hand_prefab.render_box)

      if @ingredients_in_hand.include?(:flour) &&
         @ingredients_in_hand.include?(:baking_soda) &&
         @ingredients_in_hand.include?(:sugar) &&
         @ingredients_in_hand.length == 3
        @ingredients_in_hand.clear
        @available_ingredients.push_back(:cake)
      else
        @ingredients_in_hand.clear
        @available_ingredients.push_back(:poop)
      end
    end

    def render
      outputs.sprites << { x: 640, y: 360, w: 80, h: 80, path: "sprites/square/blue.png", anchor_x: 0.5, anchor_y: 0.5 }
      render_ingredient_selection
      outputs.primitives << ingredients_in_hand_prefabs.map { |i| i.primitives }
      outputs.primitives << cook_ingredients_in_hand_prefab.primitives
    end

    def render_ingredient_selection
      if @hovered_ingredient_selection
        outputs.primitives << @hovered_ingredient_selection.render_box.merge(path: :solid, r: 255, g: 0, b: 0, a: 128)
      end
      outputs.primitives << ingredient_selection_prefabs.map { |i| i.primitives }
    end

    def ingredient_selection_prefab(id: , index:)
      text = id.to_s
               .split('_')
               .map(&:capitalize)
               .join(' ')

      render_box = Layout.rect(col: 22, row: index * 2, w: 2, h: 2)

      {
        id: id,
        index: index,
        render_box: render_box,
        primitives: [
          render_box.merge(path: "sprites/square/green.png", a: 128),
          render_box.center.merge(text: text, anchor_x: 0.5, anchor_y: 0.5)
        ]
      }
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

### Craft Game Starting Point - main.rb
```ruby
  # ./samples/99_genre_crafting/craft_game_starting_point/app/main.rb
  # ==================================================
  # A NOTE TO JAM CRAFT PARTICIPANTS:
  # The comments and code in here are just as small piece of DragonRuby's capabilities.
  # Be sure to check out the rest of the sample apps. Start with README.txt and go from there!
  # ==================================================

  # def tick args is the entry point into your game. This function is called at
  # a fixed update time of 60hz (60 fps).
  def tick args
    # The defaults function intitializes the game.
    defaults args

    # After the game is initialized, render it.
    render args

    # After rendering the player should be able to respond to input.
    input args

    # After responding to input, the game performs any additional calculations.
    calc args
  end

  def defaults args
    # hide the mouse cursor for this game, we are going to render our own cursor
    if Kernel.tick_count == 0
      DR.hide_cursor
    end

    args.state.click_ripples ||= []

    # everything is on a 1280x720 virtual canvas, so you can
    # hardcode locations

    # define the borders for where the inventory is located
    # args.state is a data structure that accepts any arbitrary parameters
    # so you can create an object graph without having to create any classes.

    # Bottom left is 0, 0. Top right is 1280, 720.
    # The inventory area is at the top of the screen
    # the number 80 is the size of all the sprites, so that is what is being
    # used to decide the with and height
    args.state.sprite_size = 80

    args.state.inventory_border.w  = args.state.sprite_size * 10
    args.state.inventory_border.h  = args.state.sprite_size * 3
    args.state.inventory_border.x  = 10
    args.state.inventory_border.y  = 710 - args.state.inventory_border.h

    # define the borders for where the crafting area is located
    # the crafting area is below the inventory area
    # the number 80 is the size of all the sprites, so that is what is being
    # used to decide the with and height
    args.state.craft_border.x =  10
    args.state.craft_border.y = 220
    args.state.craft_border.w = args.state.sprite_size * 3
    args.state.craft_border.h = args.state.sprite_size * 3

    # define the area where results are located
    # the crafting result is to the right of the craft area
    args.state.result_border.x =  10 + args.state.sprite_size * 3 + args.state.sprite_size
    args.state.result_border.y = 220 + args.state.sprite_size
    args.state.result_border.w = args.state.sprite_size
    args.state.result_border.h = args.state.sprite_size

    # initialize items for the first time if they are nil
    # you start with 15 wood, 1 chest, and 5 plank
    # Ruby has built in syntax for dictionaries (they look a lot like json objects).
    # Ruby also has a special type called a Symbol denoted with a : followed by a word.
    # Symbols are nice because they remove the need for magic strings.
    if !args.state.items
      args.state.items = [
        {
          id: :wood, # :wood is a Symbol, this is better than using "wood" for the id
          quantity: 15,
          path: 'sprites/wood.png',
          location: :inventory,
          ordinal_x: 0, ordinal_y: 0
        },
        {
          id: :chest,
          quantity: 1,
          path: 'sprites/chest.png',
          location: :inventory,
          ordinal_x: 1, ordinal_y: 0
        },
        {
          id: :plank,
          quantity: 5,
          path: 'sprites/plank.png',
          location: :inventory,
          ordinal_x: 2, ordinal_y: 0
        },
      ]

      # after initializing the oridinal positions, derive the pixel
      # locations assuming that the width and height are 80
      args.state.items.each { |item| set_inventory_position args, item }
    end

    # define all the oridinal positions of the inventory slots
    if !args.state.inventory_area
      args.state.inventory_area = [
        { ordinal_x: 0,  ordinal_y: 0 },
        { ordinal_x: 1,  ordinal_y: 0 },
        { ordinal_x: 2,  ordinal_y: 0 },
        { ordinal_x: 3,  ordinal_y: 0 },
        { ordinal_x: 4,  ordinal_y: 0 },
        { ordinal_x: 5,  ordinal_y: 0 },
        { ordinal_x: 6,  ordinal_y: 0 },
        { ordinal_x: 7,  ordinal_y: 0 },
        { ordinal_x: 8,  ordinal_y: 0 },
        { ordinal_x: 9,  ordinal_y: 0 },
        { ordinal_x: 0,  ordinal_y: 1 },
        { ordinal_x: 1,  ordinal_y: 1 },
        { ordinal_x: 2,  ordinal_y: 1 },
        { ordinal_x: 3,  ordinal_y: 1 },
        { ordinal_x: 4,  ordinal_y: 1 },
        { ordinal_x: 5,  ordinal_y: 1 },
        { ordinal_x: 6,  ordinal_y: 1 },
        { ordinal_x: 7,  ordinal_y: 1 },
        { ordinal_x: 8,  ordinal_y: 1 },
        { ordinal_x: 9,  ordinal_y: 1 },
        { ordinal_x: 0,  ordinal_y: 2 },
        { ordinal_x: 1,  ordinal_y: 2 },
        { ordinal_x: 2,  ordinal_y: 2 },
        { ordinal_x: 3,  ordinal_y: 2 },
        { ordinal_x: 4,  ordinal_y: 2 },
        { ordinal_x: 5,  ordinal_y: 2 },
        { ordinal_x: 6,  ordinal_y: 2 },
        { ordinal_x: 7,  ordinal_y: 2 },
        { ordinal_x: 8,  ordinal_y: 2 },
        { ordinal_x: 9,  ordinal_y: 2 },
      ]

      # after initializing the oridinal positions, derive the pixel
      # locations assuming that the width and height are 80
      args.state.inventory_area.each { |i| set_inventory_position args, i }

      # if you want to see the result you can use the Ruby function called "puts".
      # Uncomment this line to see the value.
      # puts args.state.inventory_area

      # You can see all things written via puts in DragonRuby's Console, or under logs/log.txt.
      # To bring up DragonRuby's Console, press the ~ key within the game.
    end

    # define all the oridinal positions of the craft slots
    if !args.state.craft_area
      args.state.craft_area = [
        { ordinal_x: 0, ordinal_y: 0 },
        { ordinal_x: 0, ordinal_y: 1 },
        { ordinal_x: 0, ordinal_y: 2 },
        { ordinal_x: 1, ordinal_y: 0 },
        { ordinal_x: 1, ordinal_y: 1 },
        { ordinal_x: 1, ordinal_y: 2 },
        { ordinal_x: 2, ordinal_y: 0 },
        { ordinal_x: 2, ordinal_y: 1 },
        { ordinal_x: 2, ordinal_y: 2 },
      ]

      # after initializing the oridinal positions, derive the pixel
      # locations assuming that the width and height are 80
      args.state.craft_area.each { |c| set_craft_position args, c }
    end
  end


  def render args
    # for the results area, create a sprite that show its boundaries
    args.outputs.primitives << { x: args.state.result_border.x,
                                 y: args.state.result_border.y,
                                 w: args.state.result_border.w,
                                 h: args.state.result_border.h,
                                 path: 'sprites/border-black.png' }

    # for each inventory spot, create a sprite
    # args.outputs.primitives is how DragonRuby performs a render.
    # Adding a single hash or multiple hashes to this array will tell
    # DragonRuby to render those primitives on that frame.

    # The .map function on Array is used instead of any kind of looping.
    # .map returns a new object for every object within an Array.
    args.outputs.primitives << args.state.inventory_area.map do |a|
      { x: a.x, y: a.y, w: a.w, h: a.h, path: 'sprites/border-black.png' }
    end

    # for each craft spot, create a sprite
    args.outputs.primitives << args.state.craft_area.map do |a|
      { x: a.x, y: a.y, w: a.w, h: a.h, path: 'sprites/border-black.png' }
    end

    # after the borders have been rendered, render the
    # items within those slots (and allow for highlighting)
    # if an item isn't currently being held
    allow_inventory_highlighting = !args.state.held_item

    # go through each item and render them
    # use Array's find_all method to remove any items that are currently being held
    args.state.items.find_all { |item| item[:location] != :held }.map do |item|
      # if an item is currently being held, don't render it in it's spot within the
      # inventory or craft area (this is handled via the find_all method).

      # the item_prefab returns a hash containing all the visual components of an item.
      # the main sprite, the black background, the quantity text, and a hover indication
      # if the mouse is currently hovering over the item.
      args.outputs.primitives << item_prefab(args, item, allow_inventory_highlighting, args.inputs.mouse)
    end

    # The last thing we want to render is the item currently being held.
    args.outputs.primitives << item_prefab(args, args.state.held_item, allow_inventory_highlighting, args.inputs.mouse)

    args.outputs.primitives << args.state.click_ripples

    # render a mouse cursor since we have the OS cursor hidden
    args.outputs.primitives << { x: args.inputs.mouse.x - 5, y: args.inputs.mouse.y - 5, w: 10, h: 10, path: 'sprites/circle-gray.png', a: 128 }
  end

  # Alrighty! This is where all the fun happens
  def input args
    # if the mouse is clicked and not item is currently being held
    # args.state.held_item is nil when the game starts.
    # If the player clicks, the property args.inputs.mouse.click will
    # be a non nil value, we don't want to process any of the code here
    # if the mouse hasn't been clicked
    return if !args.inputs.mouse.click

    # if a click occurred, add a ripple to the ripple queue
    args.state.click_ripples << { x: args.inputs.mouse.x - 5, y: args.inputs.mouse.y - 5, w: 10, h: 10, path: 'sprites/circle-gray.png', a: 128 }

    # if the mouse has been clicked, and no item is currently held...
    if !args.state.held_item
      # see if any of the items intersect the pointer using the inside_rect? method
      # the find method will either return the first object that returns true
      # for the match clause, or it'll return nil if nothing matches the match clause
      found = args.state.items.find do |item|
        # for each item in args.state.items, run the following boolean check
        args.inputs.mouse.click.point.inside_rect?(item)
      end

      # if an item intersects the mouse pointer, then set the item's location to :held and
      # set args.state.held_item to the item for later reference
      if found
        args.state.held_item = found
        found[:location] = :held
      end

    # if the mouse is clicked and an item is currently beign held....
    elsif args.state.held_item
      # determine if a slot within the craft area was clicked
      craft_area = args.state.craft_area.find { |a| args.inputs.mouse.click.point.inside_rect? a }

      # also determine if a slot within the inventory area was clicked
      inventory_area = args.state.inventory_area.find { |a| args.inputs.mouse.click.point.inside_rect? a }

      # if the click was within a craft area
      if craft_area
        # check to see if an item is already there and ignore the click if an item is found
        # item_at_craft_slot is a helper method that returns an item or nil for a given oridinal
        # position
        item_already_there = item_at_craft_slot args, craft_area[:ordinal_x], craft_area[:ordinal_y]

        # if an item *doesn't* exist in the craft area
        if !item_already_there
          # if the quantity they are currently holding is greater than 1
          if args.state.held_item[:quantity] > 1
            # remove one item (creating a seperate item of the same type), and place it
            # at the oridinal position and location of the craft area
            # the .merge method on Hash creates a new Hash, but updates any values
            # passed as arguments to merge
            new_item = args.state.held_item.merge(quantity: 1,
                                                  location: :craft,
                                                  ordinal_x: craft_area[:ordinal_x],
                                                  ordinal_y: craft_area[:ordinal_y])

            # after the item is crated, place it into the args.state.items collection
            args.state.items << new_item

            # then subtract one from the held item
            args.state.held_item[:quantity] -= 1

          # if the craft area is available and there is only one item being held
          elsif args.state.held_item[:quantity] == 1
            # instead of creating any new items just set the location of the held item
            # to the oridinal position of the craft area, and then nil out the
            # held item state so that a new item can be picked up
            args.state.held_item[:location] = :craft
            args.state.held_item[:ordinal_x] = craft_area[:ordinal_x]
            args.state.held_item[:ordinal_y] = craft_area[:ordinal_y]
            args.state.held_item = nil
          end
        end

      # if the selected area is an inventory area (as opposed to within the craft area)
      elsif inventory_area

        # check to see if there is already an item in that inventory slot
        # the item_at_inventory_slot helper method returns an item or nil
        item_already_there = item_at_inventory_slot args, inventory_area[:ordinal_x], inventory_area[:ordinal_y]

        # if there is already an item there, and the item types/id match
        if item_already_there && item_already_there[:id] == args.state.held_item[:id]
          # then merge the item quantities
          held_quantity = args.state.held_item[:quantity]
          item_already_there[:quantity] += held_quantity

          # remove the item being held from the items collection (since it's quantity is now 0)
          args.state.items.reject! { |i| i[:location] == :held }

          # nil out the held_item so a new item can be picked up
          args.state.held_item = nil

        # if there currently isn't an item there, then put the held item in the slot
        elsif !item_already_there
          args.state.held_item[:location] = :inventory
          args.state.held_item[:ordinal_x] = inventory_area[:ordinal_x]
          args.state.held_item[:ordinal_y] = inventory_area[:ordinal_y]

          # nil out the held_item so a new item can be picked up
          args.state.held_item = nil
        end
      end
    end
  end

  # the calc method is executed after input
  def calc args
    # make sure that the real position of the inventory
    # items are updated every frame to ensure that they
    # are placed correctly given their location and oridinal positions
    # instead of using .map, here we use .each (since we are not returning a new item and just updating the items in place)
    args.state.items.each do |item|
      # based on the location of the item, invoke the correct pixel conversion method
      if item[:location] == :inventory
        set_inventory_position args, item
      elsif item[:location] == :craft
        set_craft_position args, item
      elsif item[:location] == :held
        # if the item is held, center the item around the mouse pointer
        args.state.held_item.x = args.inputs.mouse.x - args.state.held_item.w.half
        args.state.held_item.y = args.inputs.mouse.y - args.state.held_item.h.half
      end
    end

    # for each hash/sprite in the click ripples queue,
    # expand its size by 20 percent and decrease its alpha
    # by 10.
    args.state.click_ripples.each do |ripple|
      delta_w = ripple.w * 1.2 - ripple.w
      delta_h = ripple.h * 1.2 - ripple.h
      ripple.x -= delta_w.half
      ripple.y -= delta_h.half
      ripple.w += delta_w
      ripple.h += delta_h
      ripple.a -= 10
    end

    # remove any items from the collection where the alpha value is less than equal to
    # zero using the reject! method (reject with an exclamation point at the end changes the
    # array value in place, while reject without the exclamation point returns a new array).
    args.state.click_ripples.reject! { |ripple| ripple.a <= 0 }
  end

  # helper function for finding an item at a craft slot
  def item_at_craft_slot args, ordinal_x, ordinal_y
    args.state.items.find { |i| i[:location] == :craft && i[:ordinal_x] == ordinal_x && i[:ordinal_y] == ordinal_y }
  end

  # helper function for finding an item at an inventory slot
  def item_at_inventory_slot args, ordinal_x, ordinal_y
    args.state.items.find { |i| i[:location] == :inventory && i[:ordinal_x] == ordinal_x && i[:ordinal_y] == ordinal_y }
  end

  # helper function that creates a visual representation of an item
  def item_prefab args, item, should_highlight, mouse
    return nil unless item

    overlay = nil

    x = item.x
    y = item.y
    w = item.w
    h = item.h

    if should_highlight && mouse.point.inside_rect?(item)
      overlay = { x: x, y: y, w: w, h: h, path: "sprites/square-blue.png", a: 130, }
    end

    [
      # sprites are hashes with a path property, this is the main sprite
      { x: x,      y: y, w: args.state.sprite_size, h: args.state.sprite_size, path: item[:path], },

      # this represents the black area in the bottom right corner of the main sprite so that the
      # quantity is visible
      { x: x + 55, y: y, w: 25, h: 25, path: "sprites/square-black.png", }, # sprites are hashes with a path property

      # labels are hashes with a text property
      { x: x + 56, y: y + 22, text: "#{item[:quantity]}", r: 255, g: 255, b: 255, },

      # this is the mouse overlay, if the overlay isn't applicable, then this value will be nil (nil values will not be rendered)
      overlay
    ]
  end

  # helper function for deriving the position of an item within inventory
  def set_inventory_position args, item
    item.x = args.state.inventory_border.x + item[:ordinal_x] * 80
    item.y = (args.state.inventory_border.y + args.state.inventory_border.h - 80) - item[:ordinal_y] * 80
    item.w = 80
    item.h = 80
  end

  # helper function for deriving the position of an item within the craft area
  def set_craft_position args, item
    item.x = args.state.craft_border.x + item[:ordinal_x] * 80
    item.y = (args.state.craft_border.y + args.state.inventory_border.h - 80) - item[:ordinal_y] * 80
    item.w = 80
    item.h = 80
  end

  # Any lines outside of a function will be executed when the file is reloaded.
  # So every time you save main.rb, the game will be reset.
  # Comment out the line below if you don't want this to happen.
  DR.reset

```

### Farming Game Starting Point - main.rb
```ruby
  # ./samples/99_genre_crafting/farming_game_starting_point/app/main.rb
  def tick args
    args.state.tile_size     = 80
    args.state.player_speed  = 4
    args.state.player      ||= tile(args, 7, 3, 0, 128, 180)
    generate_map args
    #press j to plant a green onion
    if args.inputs.keyboard.j
    #change this part you can change what you want to plant
     args.state.walls << tile(args, ((args.state.player.x+80)/args.state.tile_size), ((args.state.player.y)/args.state.tile_size), 255, 255, 255)
     args.state.plants << tile(args, ((args.state.player.x+80)/args.state.tile_size), ((args.state.player.y+80)/args.state.tile_size), 0, 160, 0)
    end
    # Adds walls, background, and player to args.outputs.solids so they appear on screen
    args.outputs.solids << [0,0,1280,720, 237,189,101]
    args.outputs.sprites << [0, 0, 1280, 720, 'sprites/background.png']
    args.outputs.solids << args.state.walls
    args.outputs.solids << args.state.player
    args.outputs.solids << args.state.plants
    args.outputs.labels << [320, 640, "press J to plant", 3, 1, 255, 0, 0, 200]

    move_player args, -1,  0 if args.inputs.keyboard.left # x position decreases by 1 if left key is pressed
    move_player args,  1,  0 if args.inputs.keyboard.right # x position increases by 1 if right key is pressed
    move_player args,  0,  1 if args.inputs.keyboard.up # y position increases by 1 if up is pressed
    move_player args,  0, -1 if args.inputs.keyboard.down # y position decreases by 1 if down is pressed
  end

  # Sets position, size, and color of the tile
  def tile args, x, y, *color
    [x * args.state.tile_size, # sets definition for array using method parameters
     y * args.state.tile_size, # multiplying by tile_size sets x and y to correct position using pixel values
     args.state.tile_size,
     args.state.tile_size,
     *color]
  end

  # Creates map by adding tiles to the wall, as well as a goal (that the player needs to reach)
  def generate_map args
    return if args.state.area

    # Creates the area of the map. There are 9 rows running horizontally across the screen
    # and 16 columns running vertically on the screen. Any spot with a "1" is not
    # open for the player to move into (and is green), and any spot with a "0" is available
    # for the player to move in.
    args.state.area = [
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,],
      [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,],
      [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,],
      [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,],
      [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,],
      [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,],
      [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,],
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
    ].reverse # reverses the order of the area collection

    # By reversing the order, the way that the area appears above is how it appears
    # on the screen in the game. If we did not reverse, the map would appear inverted.

    #The wall starts off with no tiles.
    args.state.walls = []
    args.state.plants = []

    # If v is 1, a green tile is added to args.state.walls.
    # If v is 2, a black tile is created as the goal.
    args.state.area.map_2d do |y, x, v|
      if    v == 1
        args.state.walls << tile(args, x, y, 255, 160, 156) # green tile
      end
    end
  end

  # Allows the player to move their box around the screen
  def move_player args, *vector
    box = args.state.player.shift_rect(vector) # box is able to move at an angle

    # If the player's box hits a wall, it is not able to move further in that direction
    return if args.state.walls
                  .any_intersect_rect?(box)

    # Player's box is able to move at angles (not just the four general directions) fast
    args.state.player =
      args.state.player
          .shift_rect(vector.x * args.state.player_speed, # if we don't multiply by speed, then
                      vector.y * args.state.player_speed) # the box will move extremely slow
  end

```
