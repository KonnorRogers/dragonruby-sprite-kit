### Checkboxes - main.rb
```ruby
  # ./samples/09_ui_controls/01_checkboxes/app/main.rb
  def boot args
    # initialize args.state to an empty hash on boot
    args.state = {}
  end

  def tick args
    defaults args
    calc args
    render args
  end

  def defaults args
    # animation duration of the checkbox (15 frames/quarter of a second)
    args.state.checkbox_animation_duration ||= 15

    # use layout apis to position check boxes
    # set the time the checkbox was changed to "the past" so it shows up immediately on load
    args.state.checkboxes ||= [
      Layout.rect(row: 0, col: 0, w: 1, h: 1)
            .merge(id: :option_1, text: "Option 1", checked: false, changed_at: -args.state.checkbox_animation_duration),
      Layout.rect(row: 1, col: 0, w: 1, h: 1)
            .merge(id: :option_2, text: "Option 2", checked: false, changed_at: -args.state.checkbox_animation_duration),
      Layout.rect(row: 2, col: 0, w: 1, h: 1)
            .merge(id: :option_3, text: "Option 3", checked: false, changed_at: -args.state.checkbox_animation_duration),
      Layout.rect(row: 3, col: 0, w: 1, h: 1)
            .merge(id: :option_4, text: "Option 4", checked: false, changed_at: -args.state.checkbox_animation_duration),
    ]

    # if it's the first tick, then load checkbox state from save file
    if Kernel.tick_count == 0
      load_checkbox_state args.state.checkboxes
    end
  end

  def calc args
    return if !args.inputs.mouse.click

    # see if any checkboxes were checked
    clicked_checkbox = args.state.checkboxes.find do |checkbox|
      Geometry.inside_rect? args.inputs.mouse, checkbox
    end

    # if no checkboxes were clicked, return
    return if !clicked_checkbox

    # toggle the checkbox's checked state and mark when it was checked
    clicked_checkbox.checked = !clicked_checkbox.checked
    clicked_checkbox.changed_at = Kernel.tick_count

    # save checkbox state to file
    save_checkbox_state args.state.checkboxes
  end

  def render args
    # render checkboxes using the checkbox_prefab function
    args.outputs.primitives << args.state.checkboxes.map do |checkbox|
      checkbox_prefab checkbox, args.state.checkbox_animation_duration
    end
  end

  def checkbox_prefab checkbox, animation_duration
    # this is the visuals for the checkbox

    # compute the location of the label
    label = {
      x: checkbox.x + checkbox.w + 8,
      y: checkbox.center.y,
      text: checkbox.text,
      anchor_x: 0.0,
      anchor_y: 0.5,
      size_px: 22
    }

    # this represents the checkbox area
    border = {
      x: checkbox.x, y: checkbox.y, w: checkbox.w, h: checkbox.h,
      r: 200, g: 200, b: 200,
      path: :solid
    }

    # determine the check state fade in/fade out percentage
    # use the checkbox.changed_at to determine the percentage
    animation_percentage = if checkbox.checked
                             Easing.smooth_stop(start_at: checkbox.changed_at,
                                                duration: animation_duration,
                                                tick_count: Kernel.tick_count,
                                                power: 4,
                                                flip: false)
                           else
                             Easing.smooth_stop(start_at: checkbox.changed_at,
                                                duration: animation_duration,
                                                tick_count: Kernel.tick_count,
                                                power: 4,
                                                flip: true)
                           end

    # using the percentage that was calculated, and
    # render a solid that represents the checkbox's "checked" indicator
    indicator = {
      x: checkbox.center.x,
      y: checkbox.center.y,
      w: (checkbox.w / 2) * animation_percentage,
      h: (checkbox.h / 2) * animation_percentage,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: :solid,
      r: 0, g: 0, b: 0,
      a: animation_percentage * 255
    }

    # render the labe, border, and indicator
    [
      label,
      border,
      indicator,
    ]
  end

  def save_checkbox_state checkboxes
    # create the save data in the format of id,checked
    # eg:
    #   option_1,true
    #   option_2,false
    #   option_3,false
    #   option_4,false
    content = checkboxes.map do |c|
      "#{c.id},#{c.checked}"
    end.join "\n"

    # write the contents to data/checkbox-state.txt
    DR.write_file "data/checkbox-state.txt", content
  end

  def load_checkbox_state checkboxes
    # read the save file
    content = DR.read_file "data/checkbox-state.txt"

    # if it doesn't exist then return
    return if !content

    # eg:
    #   option_1,true
    #   option_2,false
    #   option_3,false
    #   option_4,false
    # becomes:
    #   results = {
    #     option_1: true,
    #     option_2: false,
    #     option_3: false,
    #     option_4: false,
    #   }
    results = { }

    # each line has the id of the checkbox, and its value
    content.each_line do |l|
      # get the tokens split on commas for the line
      tokens = l.strip.split(",")

      # the first token is the id of the checkbox
      id = tokens[0].to_sym

      # the second value is the check state
      checked = tokens[1] == "true"

      # store values in the results lookup
      results[id] = checked
    end

    # after the results have been parsed from the file,
    # go through the checkboxes and set their checked value to
    # what was found in the file
    checkboxes.each do |c|
      c.checked = results[c.id]
    end
  end

```

### Toggle Button - main.rb
```ruby
  # ./samples/09_ui_controls/01_toggle_button/app/main.rb
  class ToggleButton
    attr :on_off

    def initialize(x:, y:, w:, h:, on_off:, button_text:, on_click:)
      @x = x
      @y = y
      @w = w
      @h = h
      @on_off = on_off
      @button_text = button_text
      @on_click = on_click
    end

    def prefab
      color = if @on_off
                { r: 255, g: 255, b: 255 }
              else
                { r: 128, g: 128, b: 128 }
              end
      [
        { x: @x,
          y: @y,
          w: @w,
          h: @h,
          path: :solid,
          r: 30,
          g: 30,
          b: 30 },
        { x: @x + @w / 2,
          y: @y + @h / 2,
          text: "#{@button_text.call(@on_off)}",
          anchor_x: 0.5,
          anchor_y: 0.5,
          **color },
      ]
    end

    def click_rect
      { x: @x, y: @y, w: @w, h: @h }
    end

    def tick inputs
      if inputs.mouse.click && inputs.mouse.inside_rect?(click_rect)
        @on_off = !@on_off
        @on_click.call(@on_off)
      end
    end
  end

  def tick args
    init_state args
    args.state.buttons.each { |button| button.tick args.inputs }
    args.outputs.primitives << args.state.buttons.map { |button| button.prefab }
  end

  def init_state args
    return if Kernel.tick_count != 0

    args.state.game_speed  ||= :slow
    args.state.color_theme ||= :dark
    args.state.bg_music    ||= :unmuted
    game_speed_button = ToggleButton.new(x: 8,
                                         y: 720 - 32 - 8,
                                         w: 512,
                                         h: 32,
                                         on_off: true,
                                         button_text: lambda { |on_off|
                                           "Game Speed: #{args.state.game_speed} (on_off state: #{on_off})"
                                         },
                                         on_click: lambda { |on_off|
                                           if on_off
                                             args.state.game_speed = :fast
                                           else
                                             args.state.game_speed = :slow
                                           end
                                         })

    game_color_theme_button = ToggleButton.new(x: 8,
                                               y: 720 - 64 - 16,
                                               w: 512,
                                               h: 32,
                                               on_off: true,
                                               button_text: lambda { |on_off|
                                                 "Color Theme: #{args.state.color_theme} (on_off state: #{on_off})"
                                               },
                                               on_click: lambda { |on_off|
                                                 if on_off
                                                   args.state.color_theme = :dark
                                                 else
                                                   args.state.color_theme = :light
                                                 end
                                               })

    bg_music_button = ToggleButton.new(x: 8,
                                       y: 720 - 96 - 24,
                                       w: 512,
                                       h: 32,
                                       on_off: true,
                                       button_text: lambda { |on_off|
                                         "Background Music: #{args.state.bg_music} (on_off state: #{on_off})"
                                       },
                                       on_click: lambda { |on_off|
                                         if on_off
                                           args.state.bg_music = :unmuted
                                         else
                                           args.state.bg_music = :muted
                                         end
                                       })

    args.state.buttons = [
      game_speed_button,
      game_color_theme_button,
      bg_music_button,
    ]
  end

  DR.reset

```

### Menu Navigation - main.rb
```ruby
  # ./samples/09_ui_controls/02_menu_navigation/app/main.rb
  class Game
    attr_dr

    def tick
      defaults
      calc
      render
    end

    def render
      outputs.primitives << state.selection_point.merge(w: state.menu.button_w + 8,
                                                        h: state.menu.button_h + 8,
                                                        a: 128,
                                                        r: 0,
                                                        g: 200,
                                                        b: 100,
                                                        path: :solid,
                                                        anchor_x: 0.5,
                                                        anchor_y: 0.5)

      outputs.primitives << state.menu.buttons.map(&:primitives)
    end

    def calc_directional_input
      return if state.input_debounce.elapsed_time < 10
      return if !inputs.directional_vector
      state.input_debounce = Kernel.tick_count

      state.selected_button = Geometry::rect_navigate(
        rect: state.selected_button,
        rects: state.menu.buttons,
        left_right: inputs.left_right,
        up_down: inputs.up_down,
        wrap_x: true,
        wrap_y: true,
        using: lambda { |e| e.rect }
      )
    end

    def calc_mouse_input
      return if !inputs.mouse.moved
      hovered_button = state.menu.buttons.find { |b| Geometry::intersect_rect? inputs.mouse, b.rect }
      if hovered_button
        state.selected_button = hovered_button
      end
    end

    def calc
      target_point = state.selected_button.rect.center
      state.selection_point.x = state.selection_point.x.lerp(target_point.x, 0.25)
      state.selection_point.y = state.selection_point.y.lerp(target_point.y, 0.25)
      calc_directional_input
      calc_mouse_input
    end

    def defaults
      if !state.menu
        state.menu = {
          button_cell_w: 2,
          button_cell_h: 1,
        }
        state.menu.button_w = Layout::rect(w: 2).w
        state.menu.button_h = Layout::rect(h: 1).h
        state.menu.buttons = [
          menu_prefab(id: :item_1, text: "Item 1", row: 0, col: 0, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_2, text: "Item 2", row: 0, col: 2, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_3, text: "Item 3", row: 0, col: 4, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_4, text: "Item 4", row: 1, col: 0, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_5, text: "Item 5", row: 1, col: 2, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_6, text: "Item 6", row: 1, col: 4, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_7, text: "Item 7", row: 2, col: 0, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_8, text: "Item 8", row: 2, col: 2, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_9, text: "Item 9", row: 2, col: 4, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
        ]
      end

      state.selected_button ||= state.menu.buttons.first
      state.selection_point ||= { x: state.selected_button.rect.center.x,
                                  y: state.selected_button.rect.center.y }
      state.input_debounce  ||= 0
    end

    def menu_prefab id:, text:, row:, col:, w:, h:;
      rect = Layout::rect(row: row, col: col, w: w, h: h)
      {
        id: id,
        row: row,
        col: col,
        text: text,
        rect: rect,
        primitives: [
          rect.merge(primitive_marker: :border),
          rect.center.merge(text: text, anchor_x: 0.5, anchor_y: 0.5)
        ]
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

### Menu Navigation Advanced - main.rb
```ruby
  # ./samples/09_ui_controls/02_menu_navigation_advanced/app/main.rb
  class Game
    attr_dr

    def initialize
      # items to render within the menu
      @items = [
        { id: :bow, },
        { id: :boomerang, },
        { id: :hookshot, },
        { id: :bomb, },
        { id: :powder, },
        { id: :pot_1, },
        { id: :fire_rod, },
        { id: :ice_rod, },
        { id: :ether, },
        { id: :quake, },
        { id: :bombos, },
        { id: :pot_2, },
        { id: :lantern, },
        { id: :hammer, },
        { id: :flute, },
        { id: :net, },
        { id: :mudora, },
        { id: :pot_3, },
        { id: :shovel, },
        { id: :somaria, },
        { id: :bryna, },
        { id: :cape, },
        { id: :mirror, },
        { id: :pot3, },
        { id: :boots, },
        { id: :mitt, },
        { id: :flippers, },
        { id: :pearl, },
      ]

      # compute the menu location for each item and capture the rect
      # along with generating the prefab
      @items.each_with_index do |item, i|
        row = i.idiv(6)
        col = i % 6
        item.click_box = Layout.rect(row: 1 + row * 2, col: 0.50 + col * 2.5, w: 2, h: 2)
        item.prefab = [
          item.click_box.merge(path: :solid, r: 0, g: 0, b: 0),
          item.click_box.center.merge(text: "#{item.id}", r: 255, g: 255, b: 255, anchor_x: 0.5, anchor_y: 0.5)
        ]
      end
    end

    def tick
      calc
      render
    end

    def calc
      # set the hovered item to the first item
      @hovered_item ||= @items.first

      if inputs.last_active == :mouse
        # if the mouse is used, then recompute the hovered item
        # using the mouse location
        moused_item = @items.find { |item| Geometry.inside_rect? inputs.mouse, item.click_box }

        # if the mouse is over an item, then set it
        # as the new hovered item, otherwise keep the current selection
        @hovered_item = moused_item || @hovered_item

        # if mouse is clicked then select the item
        if inputs.mouse.click && @hovered_item
          item_selected! @hovered_item
        end
      else
        # if controller or keyboard is the last active input
        # then use Geometry.rect_navigate to select the item
        @hovered_item = Geometry.rect_navigate(rect: @hovered_item,
                                               rects: @items,
                                               left_right: inputs.key_down.left_right,
                                               up_down: inputs.key_down.up_down,
                                               using: :click_box)

        # if enter (keyboard) or A (controller) is pressed, then select the item
        if inputs.keyboard.key_down.enter || inputs.controller_one.key_down.a
          item_selected! @hovered_item
        end
      end
    end

    # item selection logic would go here
    def item_selected! item
      DR.notify "#{item.id} was selected."
    end

    def render
      outputs.background_color = [30, 30, 30]

      # Layout apis used to create the item menu
      # main items section
      outputs[:items_popup].primitives << Layout.rect(row: 0, col: 0, w: 15.5, h: 12)
                                                .merge(path: :solid, r: 255, g: 255, b: 255, a: 128)
      outputs[:items_popup].primitives << Layout.rect(row: 0, col: 0, w: 15, h: 1)
                                                .center
                                                .merge(text: "Items",
                                                       anchor_x: 0.5,
                                                       anchor_y: 0.5,
                                                       size_px: 48)

      outputs[:items_popup].primitives << @items.map(&:prefab)

      # example of using Layout to create other sections
      outputs[:items_popup].primitives << Layout.rect(row: 0, col: 15.5, w: 8.5, h: 3)
                                                .merge(path: :solid, r: 255, g: 255, b: 255, a: 128)
      outputs[:items_popup].primitives << Layout.rect(row: 0, col: 15.5, w: 8.5, h: 1)
                                                .center
                                                .merge(text: "Pendants",
                                                       anchor_x: 0.5,
                                                       anchor_y: 0.5,
                                                       size_px: 48)

      # example of using Layout to create other sections
      outputs[:items_popup].primitives << Layout.rect(row: 3, col: 15.5, w: 8.5, h: 3)
                                                .merge(path: :solid, r: 255, g: 255, b: 255, a: 128)
      outputs[:items_popup].primitives << Layout.rect(row: 3, col: 15.5, w: 8.5, h: 1)
                                                .center
                                                .merge(text: "Crystals",
                                                       anchor_x: 0.5,
                                                       anchor_y: 0.5,
                                                       size_px: 48)

      # example of using Layout to create other sections
      outputs[:items_popup].primitives << Layout.rect(row: 6, col: 15.5, w: 8.5, h: 6)
                                                .merge(path: :solid, r: 255, g: 255, b: 255, a: 128)
      outputs[:items_popup].primitives << Layout.rect(row: 6, col: 15.5, w: 8.5, h: 1)
                                                .center
                                                .merge(text: "Equipment",
                                                       anchor_x: 0.5,
                                                       anchor_y: 0.5,
                                                       size_px: 48)

      # render the current hovered item indicator and label
      outputs[:items_popup].primitives << @hovered_item.click_box.merge(path: :solid, r: 0, g: 160, b: 0, a: 128)
      outputs[:items_popup].primitives << Layout.rect(row: 11, col: 0, w: 15.5, h: 1)
                                                .center
                                                .merge(text: "Hovered Item: #{@hovered_item.id}", anchor_x: 0.5, anchor_y: 0.5)

      # fade and slide in animation
      perc = Easing.smooth_stop(start_at: 0,
                                duration: 90,
                                tick_count: Kernel.tick_count,
                                power: 3)

      outputs.primitives << { x: 0,
                              y: (1 - perc) * 1280,
                              w: 1280,
                              h: 720,
                              a: 255 * perc,
                              path: :items_popup }
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

### Radial Menu - main.rb
```ruby
  # ./samples/09_ui_controls/03_radial_menu/app/main.rb
  class Game
    attr_dr

    def tick
      defaults
      calc
      render
    end

    def defaults
      state.menu_items = [
        { id: :item_1, text: "Item 1" },
        { id: :item_2, text: "Item 2" },
        { id: :item_3, text: "Item 3" },
        { id: :item_4, text: "Item 4" },
        { id: :item_5, text: "Item 5" },
        { id: :item_6, text: "Item 6" },
        { id: :item_7, text: "Item 7" },
        { id: :item_8, text: "Item 8" },
        { id: :item_9, text: "Item 9" },
      ]

      state.menu_status     ||= :hidden
      state.menu_radius     ||= 200
      state.menu_status_at  ||= -1000
    end

    def calc
      state.menu_items.each_with_index do |item, i|
        item.menu_angle = 90 + (360 / state.menu_items.length) * i
        item.menu_angle_range = 360 / state.menu_items.length - 10
      end

      state.menu_items.each do |item|
        item.rect = Geometry.rect_props x: 640 + item.menu_angle.vector_x * state.menu_radius - 50,
                                        y: 360 + item.menu_angle.vector_y * state.menu_radius - 25,
                                        w: 100,
                                        h: 50

        item.circle = { x: item.rect.x + item.rect.w / 2, y: item.rect.y + item.rect.h / 2, radius: item.rect.w / 2 }
      end

      show_menu_requested = false
      if state.menu_status == :hidden
        show_menu_requested = true if inputs.controller_one.key_down.a
        show_menu_requested = true if inputs.mouse.click
      end

      hide_menu_requested = false
      if state.menu_status == :shown
        hide_menu_requested = true if inputs.controller_one.key_down.b
        hide_menu_requested = true if inputs.mouse.click && !state.hovered_menu_item
      end

      if state.menu_status == :shown && state.hovered_menu_item && (inputs.mouse.click || inputs.controller_one.key_down.a)
        DR.notify! "You selected #{state.hovered_menu_item[:text]}"
      elsif show_menu_requested
        state.menu_status = :shown
        state.menu_status_at = Kernel.tick_count
      elsif hide_menu_requested
        state.menu_status = :hidden
        state.menu_status_at = Kernel.tick_count
      end

      state.hovered_menu_item = state.menu_items.find { |item| Geometry.point_inside_circle? inputs.mouse, item.circle }

      if inputs.controller_one.active && inputs.controller_one.left_analog_active?(threshold_perc: 0.5)
        state.hovered_menu_item = state.menu_items.find do |item|
          Geometry.angle_within_range? inputs.controller_one.left_analog_angle, item.menu_angle, item.menu_angle_range
        end
      end
    end

    def menu_prefab item, perc
      dx = item.rect.center.x - 640
      x = 640 + dx * perc
      dy = item.rect.center.y - 360
      y = 360 + dy * perc
      Geometry.rect_props item.rect.merge x: x - item.rect.w / 2, y: y - item.rect.h / 2
    end

    def ring_prefab x_center, y_center, radius, precision:, color: nil
      color ||= { r: 0, g: 0, b: 0, a: 255 }
      pi = Math::PI
      lines = []

      precision.map do |i|
        theta = 2.0 * pi * i / precision
        next_theta = 2.0 * pi * (i + 1) / precision

        {
          x: x_center + radius * theta.cos_r,
          y: y_center + radius * theta.sin_r,
          x2: x_center + radius * next_theta.cos_r,
          y2: y_center + radius * next_theta.sin_r,
          **color
        }
      end
    end

    def circle_prefab x_center, y_center, radius, precision:, color: nil
      color ||= { r: 0, g: 0, b: 0, a: 255 }
      pi = Math::PI
      lines = []

      # Indie/Pro Only (uses triangles)
      precision.map do |i|
        theta = 2.0 * pi * i / precision
        next_theta = 2.0 * pi * (i + 1) / precision

        {
          x:  x_center + radius * theta.cos_r,
          y:  y_center + radius * theta.sin_r,
          x2: x_center + radius * next_theta.cos_r,
          y2: y_center + radius * next_theta.sin_r,
          y3: y_center,
          x3: x_center,
          source_x:  0,
          source_y:  0,
          source_x2: 0,
          source_y2: radius,
          source_x3: radius,
          source_y3: 0,
          path:      :solid,
          **color,
        }
      end
    end

    def render
      outputs.debug.watch "Controller"
      outputs.debug.watch pretty_format(inputs.controller_one.to_h)

      outputs.debug.watch "Mouse"
      outputs.debug.watch pretty_format(inputs.mouse.to_h)

      # outputs.debug.watch "Mouse"
      # outputs.debug.watch pretty_format(inputs.mouse)
      outputs.primitives << { x: 640, y: 360, w: 10, h: 10, path: :solid, r: 128, g: 0, b: 0, a: 128, anchor_x: 0.5, anchor_y: 0.5 }

      if state.menu_status == :shown
        perc = Easing.ease(state.menu_status_at, Kernel.tick_count, 30, :smooth_stop_quart)
      else
        perc = Easing.ease(state.menu_status_at, Kernel.tick_count, 30, :smooth_stop_quart, :flip)
      end

      outputs.primitives << state.menu_items.map do |item|
        a = 255 * perc
        color = { r: 128, g: 128, b: 128, a: a }
        if state.hovered_menu_item == item
          color = { r: 80, g: 128, b: 80, a: a }
        end

        menu = menu_prefab(item, perc)

        if state.menu_status == :shown
          ring = ring_prefab(menu.center.x, menu.center.y, item.circle.radius, precision: 30, color: color.merge(a: 128))
          circle = circle_prefab(menu.center.x, menu.center.y, item.circle.radius, precision: 30, color: color.merge(a: 128))
        end

        [
          ring,
          circle,
          menu.merge(path: :solid, **color),
          menu.center.merge(text: item.text, a: a, anchor_x: 0.5, anchor_y: 0.5)
        ]
      end
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

### Scroll View - main.rb
```ruby
  # ./samples/09_ui_controls/03_scroll_view/app/main.rb
  class ScrollView
    attr_dr

    attr :y_offset, :rect, :clicked_items, :target_y_offset

    def initialize row:, col:, w:, h:;
      @items = []
      @clicked_items = []
      @y_offset = 0
      @scroll_view_dy = 0
      @rect = Layout.rect row: row,
                          col: col,
                          w: w,
                          h: h,
                          include_row_gutter: true,
                          include_col_gutter: true
      @primitives = []
    end

    def add_item prefab
      raise "prefab must be a Hash" unless prefab.is_a? Hash
      @items << prefab
    end

    def content_height
      lowest_item = @items.min_by { |primitive| primitive.y } || { x: 0, y: 0 }
      h = @rect.h

      if lowest_item
        h -= lowest_item.y - Layout.gutter
      end

      h
    end

    def y_offset_bottom_limit
      -80
    end

    def y_offset_top_limit
      content_height - @rect.h + @rect.y + 80
    end

    def tick_inputs
      @clicked_items = []

      if inputs.mouse.down
        @last_mouse_held_y = inputs.mouse.y
        @last_mouse_held_y_diff = 0
      elsif inputs.mouse.held
        @last_mouse_held_y ||= inputs.mouse.y
        @last_mouse_held_y_diff ||= 0
        @last_mouse_held_y_diff = inputs.mouse.y - @last_mouse_held_y
        @last_mouse_held_y = inputs.mouse.y
      end

      if inputs.mouse.down
        @mouse_down_at = Kernel.tick_count
        @mouse_down_y = inputs.mouse.y
        if @scroll_view_dy.abs < 7
          @maybe_click = true
        else
          @maybe_click = false
        end

        @scroll_view_dy = 0
      elsif inputs.mouse.held
        @target_y_offset = @y_offset + (inputs.mouse.y - @mouse_down_y) * 2
        @mouse_down_y = inputs.mouse.y
      elsif inputs.mouse.up
        @target_y_offset = nil
        @mouse_up_at = Kernel.tick_count
        @mouse_up_y = inputs.mouse.y

        if @maybe_click && (@last_mouse_held_y_diff).abs <= 1 && (@mouse_down_at - @mouse_up_at).abs < 12
          if inputs.mouse.y - 20 > @rect.y && inputs.mouse.y < (@rect.y + @rect.h - 20)
            @clicked_items = offset_items.reject { |primitive| !primitive.w || !primitive.h }
                                         .find_all { |primitive| inputs.mouse.inside_rect? primitive }
          end
        else
          @scroll_view_dy += @last_mouse_held_y_diff
        end
        @mouse_down_at = nil
        @mouse_up_at = nil
      end

      if inputs.keyboard.key_down.page_down
        if @scroll_view_dy >= 0
          @scroll_view_dy += 5
        else
          @scroll_view_dy = @scroll_view_dy.lerp(0, 1)
        end
      elsif inputs.keyboard.key_down.page_up
        if @scroll_view_dy <= 0
          @scroll_view_dy -= 5
        else
          @scroll_view_dy = @scroll_view_dy.lerp(0, 1)
        end
      end

      if inputs.mouse.wheel
        if inputs.mouse.wheel.inverted
          @scroll_view_dy -= inputs.mouse.wheel.y
        else
          @scroll_view_dy += inputs.mouse.wheel.y
        end
      end

    end

    def tick
      if @target_y_offset
        if @target_y_offset < y_offset_bottom_limit
          @y_offset = @y_offset.lerp @target_y_offset, 0.05
        elsif @target_y_offset > y_offset_top_limit
          @y_offset = @y_offset.lerp @target_y_offset, 0.05
        else
          @y_offset = @y_offset.lerp @target_y_offset, 0.5
        end
        @target_y_offset = nil if @y_offset.round == @target_y_offset.round
        @scroll_view_dy = 0
      end

      tick_inputs

      @y_offset += @scroll_view_dy

      if @y_offset < 0
        if inputs.mouse.held
          # if @y_offset < -80
          #   @y_offset = -80
          # end
        else
          @y_offset = @y_offset.lerp(0, 0.2)
        end
      end

      if content_height <= (@rect.h - @rect.y)
        @y_offset = 0
        @scroll_view_dy = 0
      elsif @y_offset > content_height - @rect.h + @rect.y
        if inputs.mouse.held
          # if @y_offset > (content_height - @rect.h + @rect.y) + 80
          #   @y_offset = (content_height - @rect.h + @rect.y) + 80
          # end
        else
          @y_offset = @y_offset.lerp(content_height - @rect.h + @rect.y, 0.2)
        end
      end
      @scroll_view_dy *= 0.95
      @scroll_view_dy = @scroll_view_dy.round(2)
    end

    def items
      @items
    end

    def offset_items
      @items.map { |primitive| primitive.merge(y: primitive.y + @y_offset) }
    end

    def prefab
      outputs[:scroll_view].w = Grid.w
      outputs[:scroll_view].h = Grid.h
      outputs[:scroll_view].background_color = [0, 0, 0, 0]

      outputs[:scroll_view_content].w = Grid.w
      outputs[:scroll_view_content].h = Grid.h
      outputs[:scroll_view_content].background_color = [0, 0, 0, 0]

      outputs[:scroll_view_content].primitives << offset_items

      outputs[:scroll_view].primitives << {
        x: @rect.x,
        y: @rect.y,
        w: @rect.w,
        h: @rect.h,
        source_x: @rect.x,
        source_y: @rect.y,
        source_w: @rect.w,
        source_h: @rect.h,
        path: :scroll_view_content
      }

      outputs[:scroll_view].primitives << [
        { x: @rect.x,
          y: @rect.y,
          w: @rect.w,
          h: @rect.h,
          primitive_marker: :border,
          r: 128,
          g: 128,
          b: 128 },
      ]

      { x: 0,
        y: 0,
        w: Grid.w,
        h: Grid.h,
        path: :scroll_view }
    end
  end

  class Game
    attr_dr

    attr :scroll_view

    def initialize
      @scroll_view = ScrollView.new row: 2, col: 0, w: 12, h: 20
    end

    def defaults
      state.scroll_view_dy             ||= 0
      state.scroll_view_offset_y       ||= 0
    end

    def calc
      if Kernel.tick_count == 0
        80.times do |i|
          @scroll_view.add_item Layout.rect(row: 2 + i * 2, col: 0, w: 2, h: 2).merge(id: "item_#{i}_square_1".to_sym, path: :solid, r: 32 + i * 2, g: 32, b: 32)
          @scroll_view.add_item Layout.rect(row: 2 + i * 2, col: 0, w: 2, h: 2).center.merge(text: "item #{i}", anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255)
          @scroll_view.add_item Layout.rect(row: 2 + i * 2, col: 2, w: 2, h: 2).merge(id: "item_#{i}_square_2".to_sym, path: :solid, r: 64 + i * 2, g: 64, b: 64)
        end
      end

      @scroll_view.args = args
      @scroll_view.tick

      if @scroll_view.clicked_items.length > 0
        puts @scroll_view.clicked_items
      end
    end

    def render
      outputs.primitives << @scroll_view.prefab
    end

    def tick
      defaults
      calc
      render
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

### Accessiblity For The Blind - main.rb
```ruby
  # ./samples/09_ui_controls/04_accessiblity_for_the_blind/app/main.rb
  def tick args
    # create three buttons
    args.state.button_1 ||= { x: 0, y: 640, w: 100, h: 50 }
    args.state.button_1_label ||= { x: 50,
                                    y: 665,
                                    text: "button 1",
                                    anchor_x: 0.5,
                                    anchor_y: 0.5 }

    args.state.button_2 ||= { x: 104, y: 640, w: 100, h: 50 }
    args.state.button_2_label ||= { x: 154,
                                    y: 665,
                                    text: "button 2",
                                    anchor_x: 0.5,
                                    anchor_y: 0.5 }

    args.state.button_3 ||= { x: 208, y: 640, w: 100, h: 50 }
    args.state.button_3_label ||= { x: 258,
                                    y: 665,
                                    text: "button 3",
                                    anchor_x: 0.5,
                                    anchor_y: 0.5 }

    # create a label
    args.state.label_hello_world ||= { x: 640,
                                       y: 360,
                                       text: "hello world",
                                       anchor_x: 0.5,
                                       anchor_y: 0.5 }

    args.outputs.borders << args.state.button_1
    args.outputs.labels  << args.state.button_1_label

    args.outputs.borders << args.state.button_2
    args.outputs.labels  << args.state.button_2_label

    args.outputs.borders << args.state.button_3
    args.outputs.labels  << args.state.button_3_label

    args.outputs.labels  << args.state.label_hello_world

    # args.outputs.a11y is cleared every tick, internally the key
    # of the dictionary value is used to reference the interactable element.
    # the key can be a symbol or a string (everything get's converted to strings
    # beind the scenes)

    # =======================================
    # from the Console run DR.a11y_enable!
    # ctrl+r will disable a11y (or you can run DR.a11y_disable! in the console)
    # =======================================

    # with the a11y emulation enabled, you can only use left arrow, right arrow, and enter
    # when you press enter, DR converts the location to a mouse click
    args.outputs.a11y[:button_1] = {
      a11y_text: "button 1",
      a11y_trait: :button,
      x: args.state.button_1.x,
      y: args.state.button_1.y,
      w: args.state.button_1.w,
      h: args.state.button_1.h
    }

    args.outputs.a11y[:button_2] = {
      a11y_text: "button 2",
      a11y_trait: :button,
      x: args.state.button_2.x,
      y: args.state.button_2.y,
      w: args.state.button_2.w,
      h: args.state.button_2.h
    }

    args.outputs.a11y[:button_3] = {
      a11y_text: "button 3",
      a11y_trait: :button,
      x: args.state.button_3.x,
      y: args.state.button_3.y,
      w: args.state.button_3.w,
      h: args.state.button_3.h
    }

    args.outputs.a11y[:label_hello] = {
      a11y_text: "hello world",
      a11y_trait: :label,
      x: args.state.label_hello_world.x,
      y: args.state.label_hello_world.y,
      anchor_x: 0.5,
      anchor_y: 0.5,
    }

    # flash a notification for each respective button
    if args.inputs.mouse.click && args.inputs.mouse.inside_rect?(args.state.button_1)
      DR.notify_extended! message: "Button 1 clicked", a: 255
      # you can use a11y to speak information
      args.outputs.a11y["notify button clicked"] = {
        a11y_text: "button 1 clicked",
        a11y_trait: :notification
      }
    end

    if args.inputs.mouse.click && args.inputs.mouse.inside_rect?(args.state.button_2)
      DR.notify_extended! message: "Button 2 clicked", a: 255
    end

    if args.inputs.mouse.click && args.inputs.mouse.inside_rect?(args.state.button_3)
      DR.notify_extended! message: "Button 3 clicked", a: 255
      # you can also use a11y to redirect focus to another control
      args.outputs.a11y["notify button clicked"] = {
        a11y_trait: :notification,
        a11y_notification_target: :label_hello
      }
    end
  end

  DR.reset

```

### Animated Toggle Switch - main.rb
```ruby
  # ./samples/09_ui_controls/05_animated_toggle_switch/app/main.rb
  class ToggleSwitch
    attr :toggle_state

    def initialize(row:, col:, toggle_state: :left, on_click:)
      @click_rect = Layout.rect(row: row, col: col, w: 2, h: 1)
      @switch_rect = Layout.rect(row: row, col: col, w: 1, h: 1)
      left_x =  Layout.rect(row: row, col: col, w: 1, h: 1).x
      right_x = Layout.rect(row: row, col: col + 1, w: 1, h: 1).x
      @diff_x = right_x - left_x
      @animation_duration = 15
      @toggle_state = toggle_state
      @click_at = -@animation_duration
      @on_click = on_click
    end

    def prefab
      perc = if @toggle_state == :right
               Easing.smooth_stop(start_at: @click_at,
                                  duration: @animation_duration,
                                  tick_count: Kernel.tick_count,
                                  power: 4)
             elsif @toggle_state == :left
               Easing.smooth_stop(start_at: @click_at,
                                  duration: @animation_duration,
                                  tick_count: Kernel.tick_count,
                                  power: 4,
                                  flip: true)
             end

      text = if @toggle_state == :right
               "on"
             else
               "off"
              end

      switch_diff_x = @diff_x * perc

      switch_rect_prefab = [
        { **@switch_rect,
          path: :solid,
          r: 30,
          g: 30,
          b: 30,
          x: @switch_rect.x + switch_diff_x },
        { x: @switch_rect.x + 4 + switch_diff_x,
          y: @switch_rect.y + 4,
          w: @switch_rect.w - 8,
          h: @switch_rect.h - 8,
          path: :solid,
          r: 255,
          g: 255,
          b: 255 },
      ]

      switch_bg_prefab = { **@click_rect, path: :solid, r: 30, g: 30, b: 30 }

      switch_label_prefab = { **@switch_rect.center,
                              text: "#{text}",
                              anchor_x: 0.5,
                              anchor_y: 0.5,
                              r: 0,
                              g: 0,
                              b: 0,
                              x: @switch_rect.center.x + switch_diff_x }

      [
        switch_bg_prefab,
        switch_rect_prefab,
        switch_label_prefab,
      ]
    end

    def tick inputs
      return if !inputs.mouse.click
      return if !inputs.mouse.point.inside_rect?(@click_rect)

      if @toggle_state == :left
        @toggle_state = :right
        @click_at = Kernel.tick_count
      else
        @toggle_state = :left
        @click_at = Kernel.tick_count
      end

      @on_click.call @toggle_state
    end
  end

  class Game
    attr_dr

    def initialize
      @slide_toggle_buttons = [
        ToggleSwitch.new(row: 0,
                        col: 0,
                        toggle_state: :right,
                        on_click: lambda { |toggle_state| DR.notify "toggle 1 toggled to #{toggle_state}!" }),
        ToggleSwitch.new(row: 1,
                        col: 0,
                        toggle_state: :left,
                        on_click: lambda { |toggle_state| DR.notify "toggle 2 toggled to #{toggle_state}!" }),
      ]
    end

    def tick
      @slide_toggle_buttons.each { |btn| btn.tick inputs }
      outputs.primitives << @slide_toggle_buttons.map(&:prefab)
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

### Input Remapping - main.rb
```ruby
  # ./samples/09_ui_controls/06_input_remapping/app/main.rb
  # sample app demonstrates how you can create a UI for remapping inputs
  # for a controller/keyboard

  # wrapper game class so we aren't having to pass args.state everywhere
  class Game
    attr_dr # this class macro adds args.inputs, outputs, etc to Game

    def initialize
      # default input mappings for keyboard and controller one
      @input_mappings = {
        keyboard: {
          move_left: [:left_arrow],
          move_right: [:right_arrow]
        },
        controller_one: {
          move_left: [:left],
          move_right: [:right]
        }
      }

      # default the current input method to keyboard
      @current_input = :keyboard

      # set the current game mode to "playing the game" (ability to move the player)
      @mode = :game

      # initialized the player
      @player = {
        x: 640, y: 360, w: 80, h: 80,
        path: :solid,
        r: 80, g: 128, b: 128,
        anchor_x: 0.5,
        anchor_y: 0.5
      }
    end

    def tick
      # if the mode is game, then tick_game, otherwise tick_remap
      if @mode == :game
        tick_game
      elsif @mode == :remap
        tick_remap
      end

      # render remap_buttons
      args.outputs.primitives << remap_button_prefabs

      # render the player
      args.outputs.primitives << @player
    end

    def tick_game
      # determine what the current input is based on what was last used
      if args.inputs.last_active == :controller
        @current_input = :controller_one
      elsif args.inputs.last_active == :keyboard
        @current_input = :keyboard
      end

      # check the input mappings for the named action
      if activated? :move_left
        @player.x -= 5
      elsif activated? :move_right
        @player.x += 5
      end

      # if the mouse is used an the click intersects
      # with an input mapping button, then set the mode to "remapping mode"
      # capture which mapping will be updated
      if args.inputs.mouse.key_down.left
        button = remap_buttons.find { |b| args.inputs.mouse.inside_rect?(b.rect) }
        if button
          @mode = :remap
          @remap_input_name = button.input_name
          @remap_input_type = button.input_type
        end
      end
    end

    def tick_remap
      # if we are in remapping mode, get all keys that were pressed for
      # the input we are attempting to update
      keys = inputs.send(@remap_input_type).key_down.truthy_keys

      # if keys are returned, then update the mapping table with the new key alias
      # after updating the mapping, set the game back to "playing the game" mode
      if keys.length > 0
        @input_mappings[@remap_input_type][@remap_input_name] = keys
        @mode = :game
      end
    end

    # method returns true if the mapping for the pressed/held key, for the current input is true
    def activated? input_name
      # a reminder of what input mappings looks like:
      # @input_mappings = {
      #   keyboard: {
      #     move_left: [:left_arrow],
      #     move_right: [:right_arrow]
      #   },
      #   controller_one: {
      #     move_left: [:left],
      #     move_right: [:right]
      #   }
      # }
      @input_mappings[@current_input][input_name].any? { |k| inputs.send(@current_input).key_down_or_held?(k) }
    end

    def remap_buttons
      # create button information by traversing the current mapping
      @input_mappings.flat_map do |input_type, input_names|
        # .flat_map in combination with .map will give us a flattened list of buttons
        # from the input_mappings hash
        input_names.map do |input_name, input_keys|
          {
            input_keys: input_keys,
            input_type: input_type,
            input_name: input_name
          }
        end
      end.map_with_index do |h, i|
        # now that we have the hash with pertinant metadata,
        # use the Layout apis to generate rectagles (hit boxes) and text for the button
        {
          rect: Layout.rect(row: i, col: 0, w: 12, h: 1),
          text: "#{h.input_type} #{h.input_name}: #{h.input_keys}",
          **h
        }
      end
    end

    def remap_button_prefabs
      # take the rects from remap buttons and generate the
      # prefab
      remap_buttons.map do |b|
        # if the mode is "remapping mode", then change the color of the button
        # so we know which key we are attempting to remap
        color = if @mode == :remap && @remap_input_name == b.input_name && @remap_input_type == b.input_type
                  { r: 80, g: 80, b: 30 }
                else
                  { r: 30, g: 30, b: 30 }
                end
        [
          { **b.rect, path: :solid, **color }, # background border
          { **b.rect.center, text: "#{b.text}", anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255 } # text/label of the button
        ]
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

  DR.reset

```

### Progress Bar - main.rb
```ruby
  # ./samples/09_ui_controls/07_progress_bar/app/main.rb
  def tick args
    args.outputs.background_color = [30, 30, 30]

    # track the max_hp, current_hp, and hp_perc (this is what we'll use to render remaining health)
    args.state.max_hp ||= 100
    args.state.current_hp ||= 100
    args.state.hp_perc ||= 1.0

    # every frame, lerp the hp_perc to current_hp / max_hp
    args.state.hp_perc = args.state.hp_perc.lerp(args.state.current_hp / args.state.max_hp, 0.1)

    # if j is pressed, or mouse is clicked, decrease the current hp (reset it if hp hits 0)
    if args.inputs.keyboard.key_down.enter || args.inputs.mouse.click
      if args.state.current_hp == 0
        args.state.current_hp = args.state.max_hp
      else
        args.state.current_hp -= 10
      end
    end

    args.outputs.labels << { x: 640,
                             y: 360 - 32,
                             text: "#{args.state.current_hp} / #{args.state.max_hp}",
                             anchor_x: 0.5,
                             anchor_y: 0.5,
                             r: 255, g: 255, b: 255 }

    # outer black border of the progress bar
    args.outputs.sprites << { x: 640 - 64,
                              y: 360,
                              w: 128,
                              h: 32,
                              path: :solid,
                              r: 0,
                              g: 0,
                              b: 0,
                              anchor_y: 0.5 }

    # inner white area of the progress bar
    args.outputs.sprites << { x: 640 - 62,
                              y: 360,
                              w: 124,
                              h: 28,
                              path: :solid,
                              r: 255,
                              g: 255,
                              b: 255,
                              anchor_y: 0.5 }

    # current health
    args.outputs.sprites << { x: 640 - 62,
                              y: 360,
                              w: 124 * args.state.hp_perc,
                              h: 28,
                              path: :solid,
                              r: 0,
                              g: 128,
                              b: 128,
                              anchor_y: 0.5 }
  end

```
