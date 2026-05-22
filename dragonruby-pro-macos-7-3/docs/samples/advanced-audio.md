### Audio Mixer - main.rb
```ruby
  # ./samples/07_advanced_audio/01_audio_mixer/app/main.rb
  # these are the properties that you can sent on args.audio
  def spawn_new_sound args, name, path
    # Spawn randomly in an area that won't be covered by UI.
    screenx = (rand * 600.0) + 200.0
    screeny = (rand * 400.0) + 100.0

    id = new_sound_id! args
    # you can hang anything on the audio hashes you want, so we store the
    #  actual screen position in here for convenience.
    args.audio[id] = {
      name: name,
      input: path,
      screenx: screenx,
      screeny: screeny,
      x: ((screenx / 1279.0) * 2.0) - 1.0,  # scale to -1.0 - 1.0 range
      y: ((screeny / 719.0) * 2.0) - 1.0,   # scale to -1.0 - 1.0 range
      z: 0.0,
      gain: 1.0,
      pitch: 1.0,
      looping: true,
      paused: false
    }

    args.state.selected = id
  end

  # these are values you can change on the ~args.audio~ data structure
  def input_panel args
    return unless args.state.panel
    return if args.state.dragging

    audio_entry = args.audio[args.state.selected]
    results = args.state.panel

    if args.state.mouse_state == :held && args.inputs.mouse.position.inside_rect?(results.pitch_slider_rect.rect)
      audio_entry.pitch = 2.0 * ((args.inputs.mouse.x - results.pitch_slider_rect.rect.x).to_f / (results.pitch_slider_rect.rect.w - 1.0))
    elsif args.state.mouse_state == :held && args.inputs.mouse.position.inside_rect?(results.playtime_slider_rect.rect)
      audio_entry.playtime = audio_entry.length_ * ((args.inputs.mouse.x - results.playtime_slider_rect.rect.x).to_f / (results.playtime_slider_rect.rect.w - 1.0))
    elsif args.state.mouse_state == :held && args.inputs.mouse.position.inside_rect?(results.gain_slider_rect.rect)
      audio_entry.gain = (args.inputs.mouse.x - results.gain_slider_rect.rect.x).to_f / (results.gain_slider_rect.rect.w - 1.0)
    elsif args.inputs.mouse.click && args.inputs.mouse.position.inside_rect?(results.looping_checkbox_rect.rect)
      audio_entry.looping = !audio_entry.looping
    elsif args.inputs.mouse.click && args.inputs.mouse.position.inside_rect?(results.paused_checkbox_rect.rect)
      audio_entry.paused = !audio_entry.paused
    elsif args.inputs.mouse.click && args.inputs.mouse.position.inside_rect?(results.delete_button_rect.rect)
      args.audio.delete args.state.selected
    end
  end

  def render_sources args
    args.outputs.primitives << args.audio.keys.map do |k|
      s = args.audio[k]

      isselected = (k == args.state.selected)

      color = isselected ? [ 0, 255, 0, 255 ] : [ 0, 0, 255, 255 ]
      [
        [s.screenx, s.screeny, args.state.boxsize, args.state.boxsize, *color].solid,

        {
          x: s.screenx + args.state.boxsize.half,
          y: s.screeny,
          text: s.name,
          r: 255,
          g: 255,
          b: 255,
          alignment_enum: 1
        }.label!
      ]
    end
  end

  def playtime_str t
    return "" unless t
    minutes = (t / 60.0).floor
    seconds = t - (minutes * 60.0).to_f
    return minutes.to_s + ':' + seconds.floor.to_s + ((seconds - seconds.floor).to_s + "000")[1..3]
  end

  def label_with_drop_shadow x, y, text
    [
      { x: x + 1, y: y + 1, text: text, vertical_alignment_enum: 1, alignment_enum: 1, r:   0, g:   0, b:   0 }.label!,
      { x: x + 2, y: y + 0, text: text, vertical_alignment_enum: 1, alignment_enum: 1, r:   0, g:   0, b:   0 }.label!,
      { x: x + 0, y: y + 1, text: text, vertical_alignment_enum: 1, alignment_enum: 1, r: 200, g: 200, b: 200 }.label!
    ]
  end

  def check_box opts = {}
    checkbox_template = Layout.rect(w: 0.5, h: 0.5, col: 2)
    final_rect = checkbox_template.center_inside_rect_y(Layout.rect(row: opts.row, col: opts.col))
    color = { r:   0, g:   0, b:   0 }
    color = { r: 255, g: 255, b: 255 } if opts.checked

    {
      rect: final_rect,
      primitives: [
        (final_rect.to_solid color)
      ]
    }
  end

  def progress_bar opts = {}
    outer_rect  = Layout.rect(row: opts.row, col: opts.col, w: 5, h: 1)
    color = opts.percentage * 255
    baseline_progress_bar = opts.args
                                .layout
                                .rect(w: 5, h: 0.5)

    final_rect = baseline_progress_bar.center_inside_rect(outer_rect)
    center = Geometry.rect_center_point(final_rect)

    {
      rect: final_rect,
      primitives: [
        final_rect.merge(r: color, g: color, b: color, a: 128).solid!,
        label_with_drop_shadow(center.x, center.y, opts.text)
      ]
    }
  end

  def panel_primitives args, audio_entry
    results = { primitives: [] }

    return results unless audio_entry

    # this uses DRDR's layout apis to layout the controls
    # imagine the screen is split into equal cells (24 cells across, 12 cells up and down)
    # Layout.rect returns a hash which we merge values with to create primitives
    # using Layout.rect removes the need for pixel pushing

    # args.outputs.debug << Layout.debug_primitives(r: 255, g: 255, b: 255)

    white_color = { r: 255, g: 255, b: 255 }
    label_style = white_color.merge(vertical_alignment_enum: 1)

    # panel background
    results.primitives << Layout.rect(row: 0, col: 0, w: 7, h: 6, include_col_gutter: true, include_row_gutter: true)
                                     .border!(r: 255, g: 255, b: 255)

    # title
    results.primitives << Layout.point(row: 0, col: 3.5, row_anchor: 0.5)
                                     .merge(label_style)
                                     .merge(text:           "Source #{args.state.selected} (#{args.audio[args.state.selected].name})",
                                            size_enum:      3,
                                            alignment_enum: 1)

    # seperator line
    results.primitives << Layout.rect(row: 1, col: 0, w: 7, h: 0)
                                     .line!(white_color)

    # screen location
    results.primitives << Layout.point(row: 1.0, col: 0, row_anchor: 0.5)
                                     .merge(label_style)
                                     .merge(text: "screen:")

    results.primitives << Layout.point(row: 1.0, col: 2, row_anchor: 0.5)
                                     .merge(label_style)
                                     .merge(text: "(#{audio_entry.screenx.to_i}, #{audio_entry.screeny.to_i})")

    # position
    results.primitives << Layout.point(row: 1.5, col: 0, row_anchor: 0.5)
                                     .merge(label_style)
                                     .merge(text: "position:")

    results.primitives << Layout.point(row: 1.5, col: 2, row_anchor: 0.5)
                                     .merge(label_style)
                                     .merge(text: "(#{audio_entry[:x].round(5).to_s[0..6]}, #{audio_entry[:y].round(5).to_s[0..6]})")

    results.primitives << Layout.point(row: 2.0, col: 0, row_anchor: 0.5)
                                     .merge(label_style)
                                     .merge(text: "pitch:")

    results.pitch_slider_rect = progress_bar(row: 2.0, col: 2,
                                             percentage: audio_entry.pitch / 2.0,
                                             text: "#{audio_entry.pitch.to_sf}",
                                             args: args)

    results.primitives << results.pitch_slider_rect.primitives

    results.primitives << Layout.point(row: 2.5, col: 0, row_anchor: 0.5)
                                     .merge(label_style)
                                     .merge(text: "playtime:")

    results.playtime_slider_rect = progress_bar(args: args,
                                                row:  2.5,
                                                col:  2,
                                                percentage: (audio_entry.playtime || 1) / (audio_entry.length_ || 1),
                                                text: "#{playtime_str(audio_entry.playtime)} / #{playtime_str(audio_entry.length_)}")

    results.primitives << results.playtime_slider_rect.primitives

    results.primitives << Layout.point(row: 3.0, col: 0, row_anchor: 0.5)
                                     .merge(label_style)
                                     .merge(text: "gain:")

    results.gain_slider_rect = progress_bar(args: args,
                                            row:  3.0,
                                            col:  2,
                                            percentage: audio_entry.gain,
                                            text: "#{audio_entry.gain.to_sf}")

    results.primitives << results.gain_slider_rect.primitives


    results.primitives << Layout.point(row: 3.5, col: 0, row_anchor: 0.5)
                                     .merge(label_style)
                                     .merge(text: "looping:")

    checkbox_template = Layout.rect(w: 0.5, h: 0.5, col: 2)

    results.looping_checkbox_rect = check_box(args: args, row: 3.5, col: 2, checked: audio_entry.looping)
    results.primitives << results.looping_checkbox_rect.primitives

    results.primitives << Layout.point(row: 4.0, col: 0, row_anchor: 0.5)
                                     .merge(label_style)
                                     .merge(text: "paused:")

    checkbox_template = Layout.rect(w: 0.5, h: 0.5, col: 2)

    results.paused_checkbox_rect = check_box(args: args, row: 4.0, col: 2, checked: !audio_entry.paused)
    results.primitives << results.paused_checkbox_rect.primitives

    results.delete_button_rect = { rect: Layout.rect(row: 5, col: 0, w: 7, h: 1) }

    results.primitives << results.delete_button_rect.rect.to_solid(r: 180)

    results.primitives << Layout.point(row: 5, col: 3.5, row_anchor: 0.5)
                                     .merge(label_style)
                                     .merge(text: "DELETE", alignment_enum: 1)

    return results
  end

  def render_panel args
    args.state.panel = nil
    audio_entry = args.audio[args.state.selected]
    return unless audio_entry

    mouse_down = (args.state.mouse_held >= 0)
    args.state.panel = panel_primitives args, audio_entry
    args.outputs.primitives << args.state.panel.primitives
  end

  def new_sound_id! args
    args.state.sound_id ||= 0
    args.state.sound_id  += 1
    args.state.sound_id
  end

  def render_launcher args
    args.outputs.primitives << args.state.spawn_sound_buttons.map(&:primitives)
  end

  def render_ui args
    render_launcher args
    render_panel args
  end

  def tick args
    defaults args
    render args
    input args
  end

  def input args
    if !args.audio[args.state.selected]
      args.state.selected = nil
      args.state.dragging = nil
    end

    # spawn button and node interaction
    if args.inputs.mouse.click
      spawn_sound_button = args.state.spawn_sound_buttons.find { |b| args.inputs.mouse.inside_rect? b.rect }

      audio_click_key, audio_click_value = args.audio.find do |k, v|
        args.inputs.mouse.inside_rect? [v.screenx, v.screeny, args.state.boxsize, args.state.boxsize]
      end

      if spawn_sound_button
        args.state.selected = nil
        spawn_new_sound args, spawn_sound_button.name, spawn_sound_button.path
      elsif audio_click_key
        args.state.selected = audio_click_key
      end
    end

    if args.state.mouse_state == :held && args.state.selected
      v = args.audio[args.state.selected]
      if args.inputs.mouse.inside_rect? [v.screenx, v.screeny, args.state.boxsize, args.state.boxsize]
        args.state.dragging = args.state.selected
      end

      if args.state.dragging
        s = args.audio[args.state.selected]
        # you can hang anything on the audio hashes you want, so we store the
        #  actual screen position so it doesn't scale weirdly vs your mouse.
        s.screenx = args.inputs.mouse.x - (args.state.boxsize / 2)
        s.screeny = args.inputs.mouse.y - (args.state.boxsize / 2)

        s.screeny = 50 if s.screeny < 50
        s.screeny = (719 - args.state.boxsize) if s.screeny > (719 - args.state.boxsize)
        s.screenx = 0 if s.screenx < 0
        s.screenx = (1279 - args.state.boxsize) if s.screenx > (1279 - args.state.boxsize)

        s.x = ((s.screenx / 1279.0) * 2.0) - 1.0  # scale to -1.0 - 1.0 range
        s.y = ((s.screeny / 719.0) * 2.0) - 1.0   # scale to -1.0 - 1.0 range
      end
    elsif args.state.mouse_state == :released
      args.state.dragging = nil
    end

    input_panel args
  end

  def defaults args
    args.state.mouse_state      ||= :released
    args.state.dragging_source  ||= false
    args.state.selected         ||= 0
    args.state.next_sound_index ||= 0
    args.state.boxsize          ||= 30
    args.state.sound_files      ||= [
      { name: :tada,   path: "sounds/tada.wav"   },
      { name: :splash, path: "sounds/splash.wav" },
      { name: :drum,   path: "sounds/drum.mp3"   },
      { name: :spring, path: "sounds/spring.wav" },
      { name: :music,  path: "sounds/music.ogg"  }
    ]

    # generate buttons based off the sound collection above
    args.state.spawn_sound_buttons ||= begin
      # create a group of buttons
      # column centered (using col_offset to calculate the column offset)
      # where each item is 2 columns apart
      rects = Layout.rect_group row:   11,
                                     col_offset: {
                                       count: args.state.sound_files.length,
                                       w:     2
                                     },
                                     dcol:  2,
                                     w:     2,
                                     h:     1,
                                     group: args.state.sound_files

      # now that you have the rects
      # construct the metadata for the buttons
      rects.map do |rect|
        {
          rect: rect,
          name: rect.name,
          path: rect.path,
          primitives: [
            rect.to_border(r: 255, g: 255, b: 255),
            rect.to_label(x: rect.center_x,
                          y: rect.center_y,
                          text: "#{rect.name}",
                          alignment_enum: 1,
                          vertical_alignment_enum: 1,
                          r: 255, g: 255, b: 255)
          ]
        }
      end
    end

    if args.inputs.mouse.up
      args.state.mouse_state = :released
      args.state.dragging_source = false
    elsif args.inputs.mouse.down
      args.state.mouse_state = :held
    end

    args.outputs.background_color = [ 0, 0, 0, 255 ]
  end

  def render args
    render_ui args
    render_sources args
  end

```

### Sound Synthesis - main.rb
```ruby
  # ./samples/07_advanced_audio/02_sound_synthesis/app/main.rb
  begin # region: top level tick methods
    def tick args
      defaults args
      render args
      input args
      process_audio_queue args
    end

    def defaults args
      args.state.sine_waves      ||= {}
      args.state.square_waves    ||= {}
      args.state.saw_tooth_waves ||= {}
      args.state.triangle_waves  ||= {}
      args.state.audio_queue     ||= []
      args.state.buttons         ||= [
        (frequency_buttons args),
        (sine_wave_note_buttons args),
        (bell_buttons args),
        (square_wave_note_buttons args),
        (saw_tooth_wave_note_buttons args),
        (triangle_wave_note_buttons args),
      ].flatten
    end

    def render args
      args.outputs.borders << args.state.buttons.map { |b| b[:border] }
      args.outputs.labels  << args.state.buttons.map { |b| b[:label]  }
    end

    def input args
      args.state.buttons.each do |b|
        if args.inputs.mouse.click && (args.inputs.mouse.click.inside_rect? b[:rect])
          parameter_string = (b.slice :frequency, :note, :octave).map { |k, v| "#{k}: #{v}" }.join ", "
          DR.notify! "#{b[:method_to_call]} #{parameter_string}"
          send b[:method_to_call], args, b
        end
      end

      if args.inputs.mouse.click && (args.inputs.mouse.click.inside_rect? (Layout.rect(row: 0).yield_self { |r| r.merge y: r.y + r.h.half, h: r.h.half }))
        DR.openurl 'https://www.youtube.com/watch?v=zEzovM5jT-k&ab_channel=AmirRajan'
      end
    end

    def process_audio_queue args
      to_queue = args.state.audio_queue.find_all { |v| v[:queue_at] <= Kernel.tick_count }
      args.state.audio_queue -= to_queue
      to_queue.each { |a| args.audio[a[:id]] = a }

      args.audio.find_all { |k, v| v[:decay_rate] }
        .each     { |k, v| v[:gain] -= v[:decay_rate] }

      sounds_to_stop = args.audio
                         .find_all { |k, v| v[:stop_at] && Kernel.tick_count >= v[:stop_at] }
                         .map { |k, v| k }

      sounds_to_stop.each { |k| args.audio.delete k }
    end
  end

  begin # region: button definitions, ui layout, callback functions
    def button args, opts
      button_def = opts.merge rect: (Layout.rect (opts.merge w: 2, h: 1))

      button_def[:border] = button_def[:rect].merge r: 0, g: 0, b: 0

      label_offset_x = 5
      label_offset_y = 30

      button_def[:label]  = button_def[:rect].merge text: opts[:text],
                                                    size_enum: -2.5,
                                                    x: button_def[:rect].x + label_offset_x,
                                                    y: button_def[:rect].y + label_offset_y

      button_def
    end

    def play_sine_wave args, sender
      queue_sine_wave args,
                      frequency: sender[:frequency],
                      duration: 1.seconds,
                      fade_out: true
    end

    def play_note args, sender
      method_to_call = :queue_sine_wave
      method_to_call = :queue_square_wave    if sender[:type] == :square
      method_to_call = :queue_saw_tooth_wave if sender[:type] == :saw_tooth
      method_to_call = :queue_triangle_wave  if sender[:type] == :triangle
      method_to_call = :queue_bell           if sender[:type] == :bell

      send method_to_call, args,
           frequency: (frequency_for note: sender[:note], octave: sender[:octave]),
           duration: 1.seconds,
           fade_out: true
    end

    def frequency_buttons args
      [
        (button args,
                row: 4.0, col: 0, text: "300hz",
                frequency: 300,
                method_to_call: :play_sine_wave),
        (button args,
                row: 5.0, col: 0, text: "400hz",
                frequency: 400,
                method_to_call: :play_sine_wave),
        (button args,
                row: 6.0, col: 0, text: "500hz",
                frequency: 500,
                method_to_call: :play_sine_wave),
      ]
    end

    def sine_wave_note_buttons args
      [
        (button args,
                row: 1.5, col: 2, text: "Sine C4",
                note: :c, octave: 4, type: :sine, method_to_call: :play_note),
        (button args,
                row: 2.5, col: 2, text: "Sine D4",
                note: :d, octave: 4, type: :sine, method_to_call: :play_note),
        (button args,
                row: 3.5, col: 2, text: "Sine E4",
                note: :e, octave: 4, type: :sine, method_to_call: :play_note),
        (button args,
                row: 4.5, col: 2, text: "Sine F4",
                note: :f, octave: 4, type: :sine, method_to_call: :play_note),
        (button args,
                row: 5.5, col: 2, text: "Sine G4",
                note: :g, octave: 4, type: :sine, method_to_call: :play_note),
        (button args,
                row: 6.5, col: 2, text: "Sine A5",
                note: :a, octave: 5, type: :sine, method_to_call: :play_note),
        (button args,
                row: 7.5, col: 2, text: "Sine B5",
                note: :b, octave: 5, type: :sine, method_to_call: :play_note),
        (button args,
                row: 8.5, col: 2, text: "Sine C5",
                note: :c, octave: 5, type: :sine, method_to_call: :play_note),
      ]
    end

    def square_wave_note_buttons args
      [
        (button args,
                row: 1.5, col: 6, text: "Square C4",
                note: :c, octave: 4, type: :square, method_to_call: :play_note),
        (button args,
                row: 2.5, col: 6, text: "Square D4",
                note: :d, octave: 4, type: :square, method_to_call: :play_note),
        (button args,
                row: 3.5, col: 6, text: "Square E4",
                note: :e, octave: 4, type: :square, method_to_call: :play_note),
        (button args,
                row: 4.5, col: 6, text: "Square F4",
                note: :f, octave: 4, type: :square, method_to_call: :play_note),
        (button args,
                row: 5.5, col: 6, text: "Square G4",
                note: :g, octave: 4, type: :square, method_to_call: :play_note),
        (button args,
                row: 6.5, col: 6, text: "Square A5",
                note: :a, octave: 5, type: :square, method_to_call: :play_note),
        (button args,
                row: 7.5, col: 6, text: "Square B5",
                note: :b, octave: 5, type: :square, method_to_call: :play_note),
        (button args,
                row: 8.5, col: 6, text: "Square C5",
                note: :c, octave: 5, type: :square, method_to_call: :play_note),
      ]
    end
    def saw_tooth_wave_note_buttons args
      [
        (button args,
                row: 1.5, col: 8, text: "Saw C4",
                note: :c, octave: 4, type: :saw_tooth, method_to_call: :play_note),
        (button args,
                row: 2.5, col: 8, text: "Saw D4",
                note: :d, octave: 4, type: :saw_tooth, method_to_call: :play_note),
        (button args,
                row: 3.5, col: 8, text: "Saw E4",
                note: :e, octave: 4, type: :saw_tooth, method_to_call: :play_note),
        (button args,
                row: 4.5, col: 8, text: "Saw F4",
                note: :f, octave: 4, type: :saw_tooth, method_to_call: :play_note),
        (button args,
                row: 5.5, col: 8, text: "Saw G4",
                note: :g, octave: 4, type: :saw_tooth, method_to_call: :play_note),
        (button args,
                row: 6.5, col: 8, text: "Saw A5",
                note: :a, octave: 5, type: :saw_tooth, method_to_call: :play_note),
        (button args,
                row: 7.5, col: 8, text: "Saw B5",
                note: :b, octave: 5, type: :saw_tooth, method_to_call: :play_note),
        (button args,
                row: 8.5, col: 8, text: "Saw C5",
                note: :c, octave: 5, type: :saw_tooth, method_to_call: :play_note),
      ]
    end

    def triangle_wave_note_buttons args
      [
        (button args,
                row: 1.5, col: 10, text: "Triangle C4",
                note: :c, octave: 4, type: :triangle, method_to_call: :play_note),
        (button args,
                row: 2.5, col: 10, text: "Triangle D4",
                note: :d, octave: 4, type: :triangle, method_to_call: :play_note),
        (button args,
                row: 3.5, col: 10, text: "Triangle E4",
                note: :e, octave: 4, type: :triangle, method_to_call: :play_note),
        (button args,
                row: 4.5, col: 10, text: "Triangle F4",
                note: :f, octave: 4, type: :triangle, method_to_call: :play_note),
        (button args,
                row: 5.5, col: 10, text: "Triangle G4",
                note: :g, octave: 4, type: :triangle, method_to_call: :play_note),
        (button args,
                row: 6.5, col: 10, text: "Triangle A5",
                note: :a, octave: 5, type: :triangle, method_to_call: :play_note),
        (button args,
                row: 7.5, col: 10, text: "Triangle B5",
                note: :b, octave: 5, type: :triangle, method_to_call: :play_note),
        (button args,
                row: 8.5, col: 10, text: "Triangle C5",
                note: :c, octave: 5, type: :triangle, method_to_call: :play_note),
      ]
    end

    def bell_buttons args
      [
        (button args,
                row: 1.5, col: 4, text: "Bell C4",
                note: :c, octave: 4, type: :bell, method_to_call: :play_note),
        (button args,
                row: 2.5, col: 4, text: "Bell D4",
                note: :d, octave: 4, type: :bell, method_to_call: :play_note),
        (button args,
                row: 3.5, col: 4, text: "Bell E4",
                note: :e, octave: 4, type: :bell, method_to_call: :play_note),
        (button args,
                row: 4.5, col: 4, text: "Bell F4",
                note: :f, octave: 4, type: :bell, method_to_call: :play_note),
        (button args,
                row: 5.5, col: 4, text: "Bell G4",
                note: :g, octave: 4, type: :bell, method_to_call: :play_note),
        (button args,
                row: 6.5, col: 4, text: "Bell A5",
                note: :a, octave: 5, type: :bell, method_to_call: :play_note),
        (button args,
                row: 7.5, col: 4, text: "Bell B5",
                note: :b, octave: 5, type: :bell, method_to_call: :play_note),
        (button args,
                row: 8.5, col: 4, text: "Bell C5",
                note: :c, octave: 5, type: :bell, method_to_call: :play_note),
      ]
    end
  end

  begin # region: wave generation
    begin # sine wave
      def defaults_sine_wave_for
        { frequency: 440, sample_rate: 48000 }
      end

      def sine_wave_for opts = {}
        opts = defaults_sine_wave_for.merge opts
        frequency   = opts[:frequency]
        sample_rate = opts[:sample_rate]
        period_size = (sample_rate.fdiv frequency).ceil
        period_size.map_with_index do |i|
          Math::sin((2.0 * Math::PI) / (sample_rate.to_f / frequency.to_f) * i)
        end.to_a
      end

      def defaults_queue_sine_wave
        { frequency: 440, duration: 60, gain: 1.0, fade_out: false, queue_in: 0 }
      end

      def queue_sine_wave args, opts = {}
        opts        = defaults_queue_sine_wave.merge opts
        frequency   = opts[:frequency]
        sample_rate = 48000

        sine_wave = sine_wave_for frequency: frequency, sample_rate: sample_rate
        args.state.sine_waves[frequency] ||= sine_wave_for frequency: frequency, sample_rate: sample_rate

        proc = lambda do
          generate_audio_data args.state.sine_waves[frequency], sample_rate
        end

        audio_state = new_audio_state args, opts
        audio_state[:input] = [1, sample_rate, proc]
        queue_audio args, audio_state: audio_state, wave: sine_wave
      end
    end

    begin # region: square wave
      def defaults_square_wave_for
        { frequency: 440, sample_rate: 48000 }
      end

      def square_wave_for opts = {}
        opts = defaults_square_wave_for.merge opts
        sine_wave = sine_wave_for opts
        sine_wave.map do |v|
          if v >= 0
            1.0
          else
            -1.0
          end
        end.to_a
      end

      def defaults_queue_square_wave
        { frequency: 440, duration: 60, gain: 0.3, fade_out: false, queue_in: 0 }
      end

      def queue_square_wave args, opts = {}
        opts        = defaults_queue_square_wave.merge opts
        frequency   = opts[:frequency]
        sample_rate = 48000

        square_wave = square_wave_for frequency: frequency, sample_rate: sample_rate
        args.state.square_waves[frequency] ||= square_wave_for frequency: frequency, sample_rate: sample_rate

        proc = lambda do
          generate_audio_data args.state.square_waves[frequency], sample_rate
        end

        audio_state = new_audio_state args, opts
        audio_state[:input] = [1, sample_rate, proc]
        queue_audio args, audio_state: audio_state, wave: square_wave
      end
    end

    begin # region: saw tooth wave
      def defaults_saw_tooth_wave_for
        { frequency: 440, sample_rate: 48000 }
      end

      def saw_tooth_wave_for opts = {}
        opts = defaults_saw_tooth_wave_for.merge opts
        sine_wave = sine_wave_for opts
        period_size = sine_wave.length
        sine_wave.map_with_index do |v, i|
          (((i % period_size).fdiv period_size) * 2) - 1
        end
      end

      def defaults_queue_saw_tooth_wave
        { frequency: 440, duration: 60, gain: 0.3, fade_out: false, queue_in: 0 }
      end

      def queue_saw_tooth_wave args, opts = {}
        opts        = defaults_queue_saw_tooth_wave.merge opts
        frequency   = opts[:frequency]
        sample_rate = 48000

        saw_tooth_wave = saw_tooth_wave_for frequency: frequency, sample_rate: sample_rate
        args.state.saw_tooth_waves[frequency] ||= saw_tooth_wave_for frequency: frequency, sample_rate: sample_rate

        proc = lambda do
          generate_audio_data args.state.saw_tooth_waves[frequency], sample_rate
        end

        audio_state = new_audio_state args, opts
        audio_state[:input] = [1, sample_rate, proc]
        queue_audio args, audio_state: audio_state, wave: saw_tooth_wave
      end
    end

    begin # region: triangle wave
      def defaults_triangle_wave_for
        { frequency: 440, sample_rate: 48000 }
      end

      def triangle_wave_for opts = {}
        opts = defaults_saw_tooth_wave_for.merge opts
        sine_wave = sine_wave_for opts
        period_size = sine_wave.length
        sine_wave.map_with_index do |v, i|
          ratio = (i.fdiv period_size)
          if ratio <= 0.5
            (ratio * 4) - 1
          else
            ratio -= 0.5
            1 - (ratio * 4)
          end
        end
      end

      def defaults_queue_triangle_wave
        { frequency: 440, duration: 60, gain: 1.0, fade_out: false, queue_in: 0 }
      end

      def queue_triangle_wave args, opts = {}
        opts        = defaults_queue_triangle_wave.merge opts
        frequency   = opts[:frequency]
        sample_rate = 48000

        triangle_wave = triangle_wave_for frequency: frequency, sample_rate: sample_rate
        args.state.triangle_waves[frequency] ||= triangle_wave_for frequency: frequency, sample_rate: sample_rate

        proc = lambda do
          generate_audio_data args.state.triangle_waves[frequency], sample_rate
        end

        audio_state = new_audio_state args, opts
        audio_state[:input] = [1, sample_rate, proc]
        queue_audio args, audio_state: audio_state, wave: triangle_wave
      end
    end

    begin # region: bell
      def defaults_queue_bell
        { frequency: 440, duration: 1.seconds, queue_in: 0 }
      end

      def queue_bell args, opts = {}
        (bell_to_sine_waves (defaults_queue_bell.merge opts)).each { |b| queue_sine_wave args, b }
      end

      def bell_harmonics
        [
          { frequency_ratio: 0.5, duration_ratio: 1.00 },
          { frequency_ratio: 1.0, duration_ratio: 0.80 },
          { frequency_ratio: 2.0, duration_ratio: 0.60 },
          { frequency_ratio: 3.0, duration_ratio: 0.40 },
          { frequency_ratio: 4.2, duration_ratio: 0.25 },
          { frequency_ratio: 5.4, duration_ratio: 0.20 },
          { frequency_ratio: 6.8, duration_ratio: 0.15 }
        ]
      end

      def defaults_bell_to_sine_waves
        { frequency: 440, duration: 1.seconds, queue_in: 0 }
      end

      def bell_to_sine_waves opts = {}
        opts = defaults_bell_to_sine_waves.merge opts
        bell_harmonics.map do |b|
          {
            frequency: opts[:frequency] * b[:frequency_ratio],
            duration:  opts[:duration] * b[:duration_ratio],
            queue_in:  opts[:queue_in],
            gain:      (1.fdiv bell_harmonics.length),
            fade_out:  true
          }
        end
      end
    end

    begin # audio entity construction
      def generate_audio_data sine_wave, sample_rate
        sample_size = (sample_rate.fdiv (1000.fdiv 60)).ceil
        copy_count  = (sample_size.fdiv sine_wave.length).ceil
        sine_wave * copy_count
      end

      def defaults_new_audio_state
        { frequency: 440, duration: 60, gain: 1.0, fade_out: false, queue_in: 0 }
      end

      def new_audio_state args, opts = {}
        opts        = defaults_new_audio_state.merge opts
        decay_rate  = 0
        decay_rate  = 1.fdiv(opts[:duration]) * opts[:gain] if opts[:fade_out]
        frequency   = opts[:frequency]
        sample_rate = 48000

        {
          id:               (new_id! args),
          frequency:        frequency,
          sample_rate:      48000,
          stop_at:          Kernel.tick_count + opts[:queue_in] + opts[:duration],
          gain:             opts[:gain].to_f,
          queue_at:         Kernel.tick_count + opts[:queue_in],
          decay_rate:       decay_rate,
          pitch:            1.0,
          looping:          true,
          paused:           false
        }
      end

      def queue_audio args, opts = {}
        graph_wave args, opts[:wave], opts[:audio_state][:frequency]
        args.state.audio_queue << opts[:audio_state]
      end

      def new_id! args
        args.state.audio_id ||= 0
        args.state.audio_id  += 1
      end

      def graph_wave args, wave, frequency
        if Kernel.tick_count != args.state.graphed_at
          args.outputs.static_lines.clear
          args.outputs.static_sprites.clear
        end

        wave = wave

        r, g, b = frequency.to_i % 85,
                  frequency.to_i % 170,
                  frequency.to_i % 255

        starting_rect = Layout.rect(row: 5, col: 13)
        x_scale    = 10
        y_scale    = 100
        max_points = 25

        points = wave
        if wave.length > max_points
          resolution = wave.length.idiv max_points
          points = wave.find_all.with_index { |y, i| (i % resolution == 0) }
        end

        args.outputs.static_lines << points.map_with_index do |y, x|
          next_y = points[x + 1]

          if next_y
            {
              x:  starting_rect.x + (x * x_scale),
              y:  starting_rect.y + starting_rect.h.half + y_scale * y,
              x2: starting_rect.x + ((x + 1) * x_scale),
              y2: starting_rect.y + starting_rect.h.half + y_scale * next_y,
              r:  r,
              g:  g,
              b:  b
            }
          end
        end

        args.outputs.static_sprites << points.map_with_index do |y, x|
          {
            x:  (starting_rect.x + (x * x_scale)) - 2,
            y:  (starting_rect.y + starting_rect.h.half + y_scale * y) - 2,
            w:  4,
            h:  4,
            path: 'sprites/square-white.png',
            r: r,
            g: g,
            b: b
          }
        end

        args.state.graphed_at = Kernel.tick_count
      end
    end

    begin # region: musical note mapping
      def defaults_frequency_for
        { note: :a, octave: 5, sharp:  false, flat:   false }
      end

      def frequency_for opts = {}
        opts = defaults_frequency_for.merge opts
        octave_offset_multiplier  = opts[:octave] - 5
        note = note_frequencies_octave_5[opts[:note]]
        if octave_offset_multiplier < 0
          note = note * 1 / (octave_offset_multiplier.abs + 1)
        elsif octave_offset_multiplier > 0
          note = note * (octave_offset_multiplier.abs + 1) / 1
        end
        note
      end

      def note_frequencies_octave_5
        {
          a: 440.0,
          a_sharp: 466.16, b_flat: 466.16,
          b: 493.88,
          c: 523.25,
          c_sharp: 554.37, d_flat: 587.33,
          d: 587.33,
          d_sharp: 622.25, e_flat: 659.25,
          e: 659.25,
          f: 698.25,
          f_sharp: 739.99, g_flat: 739.99,
          g: 783.99,
          g_sharp: 830.61, a_flat: 830.61
        }
      end
    end
  end

  DR.reset

```

### Rhythm Game Calibration - main.rb
```ruby
  # ./samples/07_advanced_audio/03_rhythm_game_calibration/app/main.rb
  def tick args
    defaults args
    tick_audio args
    tick_calibration args

    if Kernel.tick_count > args.state.start_playing_on_tick
      args.state.beat_accumulator += args.state.beats_per_tick
      args.state.quarter_beat = args.state.beat_accumulator.to_i
      args.state.previous_quarter_beat ||= args.state.quarter_beat
    end

    if args.state.previous_quarter_beat != args.state.quarter_beat
      args.state.previous_quarter_beat_at = args.state.quarter_beat
      args.state.quarter_beat_occurred_at = Kernel.tick_count
    end

    if (Kernel.tick_count - args.state.quarter_beat_occurred_at + args.state.calibration_ticks).abs == 0
      args.state.fx_queue << { x: 640,
                               y: 360,
                               w: 100,
                               h: 100,
                               r: 255,
                               anchor_x: 0.5,
                               anchor_y: 0.5,
                               g: 0,
                               b: 0,
                               a: 255,
                               path: :solid }

      args.state.fx_queue << { x: 640,
                               y: 360,
                               w: 100,
                               h: 100,
                               r: 255,
                               anchor_x: 0.5,
                               anchor_y: 0.5,
                               g: 0,
                               b: 0,
                               a: 255,
                               d_size: 20,
                               path: :solid }
    end

    if args.inputs.keyboard.key_down.space || args.inputs.controller_one.key_down.a
      input_diff = (Kernel.tick_count - args.state.quarter_beat_occurred_at + args.state.calibration_ticks)
      if input_diff.abs <= 1
        args.state.label_fx_queue << { x: 640,
                                       y: 360,
                                       anchor_x: 0.5,
                                       anchor_y: 0.5,
                                       text: "perfect! (#{input_diff})" }
      elsif input_diff.abs <= 3
        args.state.label_fx_queue << { x: 640,
                                       y: 360,
                                       anchor_x: 0.5,
                                       anchor_y: 0.5,
                                       text: "great! (#{input_diff})" }
      elsif input_diff.abs <= 5
        args.state.label_fx_queue << { x: 640,
                                       y: 360,
                                       anchor_x: 0.5,
                                       anchor_y: 0.5,
                                       text: "okay... (#{input_diff})" }
      else
        args.state.label_fx_queue << { x: 640,
                                       y: 360,
                                       anchor_x: 0.5,
                                       anchor_y: 0.5,
                                       text: "bad :-( (#{input_diff})" }
      end
    end

    calc_fx_queues args
    render args
  end

  def defaults args
    args.state.track_length_in_ticks     ||= 2057
    args.state.main_track                ||= :track_1
    args.state.other_track               ||= :track_2
    args.state.fx_queue                  ||= []
    args.state.label_fx_queue            ||= []
    args.state.play_head                 ||= 0
    args.state.start_playing_on_tick     ||= 180
    args.state.beats_per_minute          ||= 140
    args.state.beats_per_second          ||= args.state.beats_per_minute / 60.0
    args.state.beats_per_tick            ||= args.state.beats_per_second / 60.0
    args.state.beat_accumulator          ||= 0
    args.state.quarter_beat              ||= 0
    args.state.calibration_ticks         ||= 0
    args.state.quarter_beat_interval     ||= 1.fdiv(args.state.beats_per_tick).to_i
    args.state.quarter_beat_inputs       ||= 0
    args.state.quarter_beat_diff_history ||= []
  end

  def tick_audio args
    return if Kernel.tick_count < args.state.start_playing_on_tick

    # start up audio
    args.audio[:track_1] ||= {
      input: "sounds/music.ogg",
      gain: 1.0,
      looping: false
    }

    args.audio[:track_2] ||= {
      input: "sounds/music.ogg",
      looping: false,
      gain: 0.0
    }

    # play head increment every tick
    args.state.play_head += 1
    args.state.play_head = args.state.play_head % args.state.track_length_in_ticks

    # every 10 seconds, cross fade
    if args.state.play_head.zmod?(600) && Kernel.tick_count > args.state.start_playing_on_tick
      if args.state.main_track == :track_1
        args.state.main_track = :track_2
        args.state.other_track = :track_1
      else
        args.state.main_track = :track_1
        args.state.other_track = :track_2
      end

      if args.audio[args.state.main_track]
        args.audio[args.state.main_track].playtime = args.state.play_head.idiv(60)
      end
    end

    # perform cross fade
    if args.audio[args.state.main_track]
      args.audio[args.state.main_track].gain += 0.1
      args.audio[args.state.main_track].gain = 1.0 if args.audio[args.state.main_track].gain > 1.0
    end

    if args.audio[args.state.other_track]
      args.audio[args.state.other_track].gain -= 0.1
      args.audio[args.state.other_track].gain = 0.0 if args.audio[args.state.other_track].gain < 0.0
    end
  end

  def tick_calibration args
    if args.inputs.keyboard.key_down.up || args.inputs.controller_one.key_down.up
      args.state.calibration_ticks += 1
    elsif args.inputs.keyboard.key_down.down || args.inputs.controller_one.key_down.down
      args.state.calibration_ticks -= 1
    end

    if args.inputs.keyboard.key_down.m || args.inputs.controller_one.key_down.b
      args.state.player_beat_at = Kernel.tick_count
    else
      args.state.player_beat_at = nil
    end

    if args.state.player_beat_at && args.state.quarter_beat_occurred_at
      diff = args.state.player_beat_at - args.state.quarter_beat_occurred_at
      description = if (diff + args.state.calibration_ticks) < 0
                      "early: increase calibration value"
                    elsif (diff + args.state.calibration_ticks) > 0
                      "late:  decrease calibration value"
                    else
                      "perfect"
                    end

      quarter_beat_diff = { diff: (diff + args.state.calibration_ticks), description: description }
      args.state.quarter_beat_diff_history.unshift quarter_beat_diff.copy
      if args.state.quarter_beat_diff_history.length > 20
        args.state.quarter_beat_diff_history = args.state.quarter_beat_diff_history.take 20
      end
    end
  end

  def calc_fx_queues args
    args.state.fx_queue.each do |fx|
      fx.at ||= Kernel.tick_count
      fx.d_size ||= 0
      fx.w += fx.d_size
      fx.h += fx.d_size
    end

    args.state.fx_queue.reject! { |fx| fx.at.elapsed_time > 5 }

    args.state.label_fx_queue.each do |fx|
      fx.at ||= Kernel.tick_count
      fx.a  ||= 255
      fx.y    = fx.y.lerp(540, 0.1)
      fx.a   -= 5
    end

    args.state.label_fx_queue.reject! { |fx| fx.a <= 0 }
  end

  def render args
    if Kernel.tick_count < args.state.start_playing_on_tick
      args.outputs.labels << { x: 640,
                               y: 360,
                               text: "Count down: #{(args.state.start_playing_on_tick - Kernel.tick_count).idiv(60) + 1}",
                               anchor_x: 0.5,
                               anchor_y: 0.5 }
    end

    args.outputs.borders << { x: 640, y: 360, w: 100, h: 100,
                              anchor_x: 0.5, anchor_y: 0.5,
                              r: 255, g: 0, b: 0, a: 255 }

    args.outputs.primitives << args.state.fx_queue
    args.outputs.primitives << args.state.label_fx_queue
    args.state.previous_quarter_beat = args.state.quarter_beat

    args.outputs.debug.watch "Instructions: Close your eyes and listen to the beat and press 'M' (or 'B' on your controller) when you hear a quarter beat."
    args.outputs.debug.watch "              Press 'UP' or 'DOWN' to adjust calibration_ticks."
    args.outputs.debug.watch "              Press 'SPACE' (or 'A' on your controller) on quarter beats to test calibration."

    if args.audio[:track_1] && args.audio[:track_2]
      args.outputs.debug.watch "track_1 gain: #{args.audio[:track_1].gain.to_sf}"
      args.outputs.debug.watch "track_2 gain: #{args.audio[:track_2].gain.to_sf}"
    end

    args.outputs.debug.watch "beat accumulator: #{args.state.beat_accumulator.to_sf}"
    args.outputs.debug.watch "quarter beat: #{args.state.quarter_beat}"
    args.outputs.debug.watch "calibration_ticks: #{args.state.calibration_ticks.to_i}"
    args.state.quarter_beat_diff_history.each do |item|
      if item.diff >= 0
        args.outputs.debug.watch "+#{item.diff.to_sf} #{item.description}"
      elsif item.diff < 0
        args.outputs.debug.watch "#{item.diff.to_sf} #{item.description}"
      end
    end
  end

```
