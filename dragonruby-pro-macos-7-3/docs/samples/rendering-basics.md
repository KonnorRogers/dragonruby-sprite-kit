### Labels - main.rb
```ruby
  # ./samples/01_rendering_basics/01_labels/app/main.rb
  =begin

  APIs listing that haven't been encountered in a previous sample apps:

  - args.outputs.labels: An array. Values in this array generate labels the screen.

  =end

  # Labels are used to represent text elements in DragonRuby

  # An example of creating a label is:
  # args.outputs.labels << {
  #   x: 320,
  #   y: 640,
  #   text: "Example",
  #   size_px: 16,
  #   anchor_x: 0.5,
  #   anchor_y: 0.5,
  #   r: 0,
  #   g: 0,
  #   b: 200,
  #   a: 255,
  #   font: "manaspace.ttf"
  # }

  # The code above does the following:
  # 1. GET the place where labels go: args.outputs.labels
  # 2. Request a new LABEL be ADDED: <<
  # 3. Hash that represents the label
  #    { x: 320,
  #      y: 640,
  #      text: "Text",
  #      font: "fonts/font.ttf",
  #      anchor_x: 0.5,
  #      anchor_y: 0.5,
  #      r: 0,
  #      g: 0,
  #      b: 0,
  #      a: 255,
  #      size_px: 20,
  #      blendmode: 1 }


  module Main
    # The tick method is called by DragonRuby every frame
    # args contains all the information regarding the game.
    def tick args
      # render the current frame to the screen centered vertically and horizontally at 640, 620
      args.outputs.labels << { x: 640, y: 620, anchor_x: 0.5, anchor_y: 0.5, text: "frame: #{Kernel.tick_count}" }

      # Here are some examples of simple labels, with the minimum number of parameters
      # Note that the default values for the other parameters are 0, except for Alpha which is 255 and Font Style which is the default font
      args.outputs.labels << { x: 5,          y: 720 - 5, text: "This is a label located at the top left." }
      args.outputs.labels << { x: 5,          y:      30, text: "This is a label located at the bottom left." }
      args.outputs.labels << { x: 1280 - 420, y: 720 - 5, text: "This is a label located at the top right." }
      args.outputs.labels << { x: 1280 - 440, y: 30,      text: "This is a label located at the bottom right." }

      # Demonstration of the Size Enum Parameter

      # size_enum of -2 is equivalent to using size_px: 18
      args.outputs.labels << { x: 175 + 150, y: 635 - 50, text: "Smaller label.",  size_enum: -2 }
      args.outputs.labels << { x: 175 + 150, y: 620 - 50, text: "Smaller label.",  size_px: 18 }

      # size_enum of -1 is equivalent to using size_px: 20
      args.outputs.labels << { x: 175 + 150, y: 595 - 50, text: "Small label.",    size_enum: -1 }
      args.outputs.labels << { x: 175 + 150, y: 580 - 50, text: "Small label.",    size_px: 20 }

      # size_enum of  0 is equivalent to using size_px: 22
      args.outputs.labels << { x: 175 + 150, y: 550 - 50, text: "Medium label.",   size_enum:  0 }

      # size_enum of  1 is equivalent to using size_px: 24
      args.outputs.labels << { x: 175 + 150, y: 520 - 50, text: "Large label.",    size_enum:  1 }

      # size_enum of  2 is equivalent to using size_px: 26
      args.outputs.labels << { x: 175 + 150, y: 490 - 50, text: "Larger label.",   size_enum:  2 }

      # Demonstration of the Align Parameter
      args.outputs.lines  << { x: 175 + 150, y: 0, h: 720 }

      # alignment_enum: 0 is equivalent to anchor_x: 0
      # IMPORTANT: the default anchoring for labels is TOP LEFT (anchor_x: 0.0, anchor_y: 1.0)
      args.outputs.labels << { x: 175 + 150, y: 342 - 50, text: "Left aligned.",   anchor_x: 0, anchor_y: 0.5 }

      args.outputs.labels << { x: 175 + 150, y: 325 - 50, text: "Center aligned.", anchor_x: 0.5, anchor_y: 0.5 }

      args.outputs.labels << { x: 175 + 150, y: 305 - 50, text: "Right aligned.",  anchor_x: 1.0, anchor_y: 0.5 }

      # Demonstration of the RGBA parameters
      args.outputs.labels << { x: 600  + 150, y: 590 - 50, text: "Red Label.",   r: 255, g:   0, b:   0 }
      args.outputs.labels << { x: 600  + 150, y: 570 - 50, text: "Green Label.", r:   0, g: 255, b:   0 }
      args.outputs.labels << { x: 600  + 150, y: 550 - 50, text: "Blue Label.",  r:   0, g:   0, b: 255 }
      args.outputs.labels << { x: 600  + 150, y: 530 - 50, text: "Faded Label.", r:   0, g:   0, b:   0, a: 128 }

      # providing a custom font
      args.outputs.labels << { x: 690 + 150,
                               y: 330 - 50,
                               text: "Custom font (Hash)",
                               size_enum: 0,                 # equivalent to size_px:  22
                               alignment_enum: 1,            # equivalent to anchor_x: 0.5
                               vertical_alignment_enum: 2,   # equivalent to anchor_y: 1
                               r: 125,
                               g: 0,
                               b: 200,
                               a: 255,
                               font: "manaspc.ttf" }

      # Primitives can hold anything, and can be given a label in the following forms
      args.outputs.primitives << { x: 690 + 150,
                                   y: 330 - 80,
                                   text: "Custom font (.primitives Hash)",
                                   size_enum: 0,
                                   alignment_enum: 1,
                                   r: 125,
                                   g: 0,
                                   b: 200,
                                   a: 255,
                                   font: "manaspc.ttf" }

      args.outputs.labels << { x: 640,
                               y: 100,
                               anchor_x: 0.5,
                               anchor_y: 0.5,
                               text: "Ніколи не здам тебе. Ніколи не підведу тебе. Ніколи не буду бігати навколо і залишати тебе." }
    end
  end

```

### Labels Anchors - main.rb
```ruby
  # ./samples/01_rendering_basics/01_labels_anchors/app/main.rb
  def tick args
    # String.line_anchors is a helpful function if you want
    # to center a multi-line text vertically or horizontally
    16.times do |line_count_index|
      c = line_count_index + 1
      args.outputs.labels << String.line_anchors(c).map_with_index do |anchor_value, line_index|
        # to_sf is a hellper method for formatting numbers (useful for debugging purposes)
        v_to_s = anchor_value.to_sf(decimal_places: 1, include_sign: true)
        { x: line_count_index * 76 + 64,
          y: 360,
          text: "#{(line_index + 1).to_s.rjust(2)} [#{v_to_s}]",
          anchor_x: 0.5,
          anchor_y: anchor_value,
          size_px: 16 }
      end
    end

    args.outputs.lines << { x: 0, y: 360, x2: 1280, y2: 360 }
    args.outputs.lines << { x: 640, y: 0, x2: 640, y2: 720 }
  end

```

### Labels Text Wrapping - main.rb
```ruby
  # ./samples/01_rendering_basics/01_labels_text_wrapping/app/main.rb
  def tick args
    # create a really long string
    really_long_string =  "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In vulputate viverra metus et vehicula. Aenean quis accumsan dolor. Nulla tempus, ex et lacinia elementum, nisi felis ullamcorper sapien, sed sagittis sem justo eu lectus. Etiam ut vehicula lorem, nec placerat ligula. Duis varius ultrices magna non sagittis. Aliquam et sem vel risus viverra hendrerit. Maecenas dapibus congue lorem, a blandit mauris feugiat sit amet."
    really_long_string += "\n\n"
    really_long_string += "Sed quis metus lacinia mi dapibus fermentum nec id nunc. Donec tincidunt ante a sem bibendum, eget ultricies ex mollis. Quisque venenatis erat quis pretium bibendum. Pellentesque vel laoreet nibh. Cras gravida nisi nec elit pulvinar, in feugiat leo blandit. Quisque sodales quam sed congue consequat. Vivamus placerat risus vitae ex feugiat viverra. In lectus arcu, pellentesque vel ipsum ac, dictum finibus enim. Quisque consequat leo in urna dignissim, eu tristique ipsum accumsan. In eros sem, iaculis ac rhoncus eu, laoreet vitae ipsum. In sodales, ante eu tempus vehicula, mi nulla luctus turpis, eu egestas leo sapien et mi."

    # length of characters on line
    max_character_length = 80

    # API: String.wrapped_lines(string, max_character_length)
    long_strings_split = String.wrapped_lines really_long_string,
                                              max_character_length

    # render a label for each line and offset by the index value
    # setting the anchor_y for a label will offset the text by its
    # height
    args.outputs.labels << long_strings_split.map_with_index do |s, i|
      {
        x: 60,
        y: 720 - 60,
        anchor_y: i,
        text: s
      }
    end
  end

```

### Lines - main.rb
```ruby
  # ./samples/01_rendering_basics/02_lines/app/main.rb
  =begin
  APIs listing that haven't been encountered in a previous sample apps:

  - args.outputs.lines: Provided an Array or a Hash, lines will be rendered to the screen.
  - Kernel.tick_count: This property contains an integer value that
    represents the current frame. DragonRuby renders at 60 FPS. A value of 0
    for Kernel.tick_count represents the initial load of the game.
  =end

  # The parameters required for lines are:
  # 1. The initial point (x, y)
  # 2. The end point (x2, y2)
  # 3. The rgba values for the color and transparency (r, g, b, a)
  #    Creating a line using an Array (quick and dirty):
  #    [x, y, x2, y2, r, g, b, a]
  #    args.outputs.lines << [100, 100, 300, 300, 255, 0, 255, 255]
  #    This would create a line from (100, 100) to (300, 300)
  #    The RGB code (255, 0, 255) would determine its color, a purple
  #    It would have an Alpha value of 255, making it completely opaque
  # 4. Using Hashes, the keys are :x, :y, :x2, :y2, :r, :g, :b, and :a
  def tick args
    args.outputs.labels << { x: 640,
                             y: 700,
                             text: "Sample app shows how to create lines.",
                             size_px: 22,
                             anchor_x: 0.5,
                             anchor_y: 0.5 }

    # Render lines using Arrays/Tuples
    # This is quick and dirty and it's recommended to use Hashes long term
    args.outputs.lines  << [380, 450, 675, 450]
    args.outputs.lines  << [380, 410, 875, 410]

    # These examples utilize Kernel.tick_count to change the length of the lines over time
    # Kernel.tick_count is the ticks that have occurred in the game
    # This is accomplished by making either the starting or ending point based on the Kernel.tick_count
    args.outputs.lines  << { x:  380,
                             y:  370,
                             x2: 875,
                             y2: 370,
                             r:  Kernel.tick_count % 255,
                             g:  0,
                             b:  0,
                             a:  255 }

    args.outputs.lines  << { x:  380,
                             y:  330 - Kernel.tick_count % 25,
                             x2: 875,
                             y2: 330,
                             r:  0,
                             g:  0,
                             b:  0,
                             a:  255 }

    args.outputs.lines  << { x:  380 + Kernel.tick_count % 400,
                             y:  290,
                             x2: 875,
                             y2: 290,
                             r:  0,
                             g:  0,
                             b:  0,
                             a:  255 }
  end

```

### Solids Borders - main.rb
```ruby
  # ./samples/01_rendering_basics/03_solids_borders/app/main.rb
  =begin
  APIs listing that haven't been encountered in a previous sample apps:

  - args.outputs.solids: Provided an Array or a Hash, solid squares will be
    rendered to the screen.
  - args.outputs.borders: Provided an Array or a Hash, borders
    will be rendered to the screen.
  - args.outputs.primitives: Provided an Hash with a :primitive_marker key,
    either a solid square or border will be rendered to the screen.
  =end

  # The parameters required for rects are:
  # 1. The bottom left corner (x, y)
  # 2. The width (w)
  # 3. The height (h)
  # 4. The rgba values for the color and transparency (r, g, b, a)
  # [100, 100, 400, 500, 0, 255, 0, 180]
  # Whether the rect would be filled or not depends on if
  # it is added to args.outputs.solids or args.outputs.borders
  # (or its :primitive_marker if Hash is sent to args.outputs.primitives)
  def tick args
    args.outputs.labels << { x: 640,
                             y: 700,
                             text: "Sample app shows how to create solid squares and borders.",
                             size_px: 22,
                             anchor_x: 0.5,
                             anchor_y: 0.5 }

    # Render solids/borders using Arrays/Tuples
    # Using arrays is quick and dirty and it's recommended to use Hashes long term
    args.outputs.solids << [470, 520, 50, 50]
    args.outputs.solids << [530, 520, 50, 50, 0, 0, 0]
    args.outputs.solids << [590, 520, 50, 50, 255, 0, 0]
    args.outputs.solids << [650, 520, 50, 50, 255, 0, 0, 128]

    # using Hashes
    args.outputs.solids << { x: 710,
                             y: 520,
                             w: 50,
                             h: 50,
                             r: 0,
                             g: 80,
                             b: 40,
                             a: Kernel.tick_count % 255 }

    # primitives outputs requires a primitive_marker to differentiate
    # between a solid or a border
    args.outputs.primitives << { x: 770,
                                 y: 520,
                                 w: 50,
                                 h: 50,
                                 r: 0,
                                 g: 80,
                                 b: 40,
                                 a: Kernel.tick_count % 255,
                                 primitive_marker: :solid }

    # using :solid sprite
    args.outputs.sprites << { x: 710,
                              y: 460,
                              w: 50,
                              h: 50,
                              path: :solid,
                              r: 0,
                              g: 80,
                              b: 40,
                              a: Kernel.tick_count % 255 }

    # using :solid sprite does not require a primitive marker
    args.outputs.primitives << { x: 770,
                                 y: 460,
                                 w: 50,
                                 h: 50,
                                 path: :solid,
                                 r: 0,
                                 g: 80,
                                 b: 40,
                                 a: Kernel.tick_count % 255 }


    # you can also render a border
    # Using arrays is quick and dirty and it's recommended to use Hashes long term
    args.outputs.borders << [470, 320, 50, 50]
    args.outputs.borders << [530, 320, 50, 50, 0, 0, 0]
    args.outputs.borders << [590, 320, 50, 50, 255, 0, 0]
    args.outputs.borders << [650, 320, 50, 50, 255, 0, 0, 128]

    args.outputs.borders << { x: 710,
                              y: 320,
                              w: 50,
                              h: 50,
                              r: 0,
                              g: 80,
                              b: 40,
                              a: Kernel.tick_count % 255 }

    # primitives outputs requires a primitive_marker to differentiate
    # between a solid or a border
    args.outputs.borders << { x: 770,
                              y: 320,
                              w: 50,
                              h: 50,
                              r: 0,
                              g: 80,
                              b: 40,
                              a: Kernel.tick_count % 255,
                              primitive_marker: :border }
  end

```

### Sprites - main.rb
```ruby
  # ./samples/01_rendering_basics/04_sprites/app/main.rb
  =begin
  APIs listing that haven't been encountered in a previous sample apps:
  - args.outputs.sprites: Provided an Array or a Hash, a sprite will be
    rendered to the screen.

  Properties of a sprite:
  {
    # common properties
    x: 0,
    y: 0,
    w: 100,
    h: 100,
    path: "sprites/square/blue.png",
    angle: 90,
    a: 255,

    # anchoring (float value representing a percentage to offset w and h)
    anchor_x: 0,
    anchor_y: 0,
    angle_anchor_x: 0,
    angle_anchor_y: 0,

    # color saturation
    r: 255,
    g: 255,
    b: 255,

    # flip rendering
    flip_horizontally: false,
    flip_vertically: false

    # sprite sheet properties/clipped rect (using the top-left as the origin)
    tile_x: 0,
    tile_y: 0,
    tile_w: 20,
    tile_h: 20

    # sprite sheet properties/clipped rect (using the bottom-left as the origin)
    source_x: 0,
    source_y: 0,
    source_w: 20,
    source_h: 20,
  }
  =end
  def tick args
    args.outputs.labels << { x: 640,
                             y: 700,
                             text: "Sample app shows how to render a sprite.",
                             size_px: 22,
                             anchor_x: 0.5,
                             anchor_y: 0.5 }

    # ==================
    # ROW 1 Simple Rendering
    # ==================
    args.outputs.labels << { x: 460,
                             y: 600,
                             text: "Simple rendering." }

    # using quick and dirty Array (use Hashes for long term maintainability)
    args.outputs.sprites << [460, 470, 128, 101, 'dragonruby.png']

    # using Hashes
    args.outputs.sprites << { x: 610,
                              y: 470,
                              w: 128,
                              h: 101,
                              path: 'dragonruby.png',
                              a: Kernel.tick_count % 255 }

    args.outputs.sprites << { x: 760 + 64,
                              y: 470 + 50,
                              w: 128,
                              h: 101,
                              anchor_x: 0.5,
                              anchor_y: 0.5,
                              path: 'dragonruby.png',
                              flip_horizontally: true,
                              flip_vertically: true,
                              a: Kernel.tick_count % 255 }

    # ==================
    # ROW 2 Angle/Angle Anchors
    # ==================
    args.outputs.labels << { x: 460,
                             y: 400,
                             text: "Angle/Angle Anchors." }
    # rotation using angle (in degrees)
    args.outputs.sprites << { x: 460,
                              y: 270,
                              w: 128,
                              h: 101,
                              path: 'dragonruby.png',
                              angle: Kernel.tick_count % 360 }

    # rotation anchor using angle_anchor_x
    args.outputs.sprites << { x: 760,
                              y: 270,
                              w: 128,
                              h: 101,
                              path: 'dragonruby.png',
                              angle: Kernel.tick_count % 360,
                              angle_anchor_x: 0,
                              angle_anchor_y: 0 }

    # ==================
    # ROW 3 Sprite Cropping
    # ==================
    args.outputs.labels << { x: 460,
                             y: 200,
                             text: "Cropping (tile sheets)." }

    # tiling using top left as the origin
    args.outputs.sprites << { x: 460,
                              y: 90,
                              w: 80,
                              h: 80,
                              path: 'dragonruby.png',
                              tile_x: 0,
                              tile_y: 0,
                              tile_w: 80,
                              tile_h: 80 }

    # overlay to see how tile_* crops
    args.outputs.sprites << { x: 460,
                              y: 70,
                              w: 128,
                              h: 101,
                              path: 'dragonruby.png',
                              a: 80 }

    # tiling using bottom left as the origin
    args.outputs.sprites << { x: 610,
                              y: 70,
                              w: 80,
                              h: 80,
                              path: 'dragonruby.png',
                              source_x: 0,
                              source_y: 0,
                              source_w: 80,
                              source_h: 80 }

    # overlay to see how source_* crops
    args.outputs.sprites << { x: 610,
                              y: 70,
                              w: 128,
                              h: 101,
                              path: 'dragonruby.png',
                              a: 80 }
  end

```

### Sounds - main.rb
```ruby
  # ./samples/01_rendering_basics/05_sounds/app/main.rb
  =begin

   APIs Listing that haven't been encountered in previous sample apps:

   - sample: Chooses random element from array.
     In this sample app, the target note is set by taking a sample from the collection
     of available notes.

   - String interpolation: Uses #{} syntax; everything between the #{ and the } is evaluated
     as Ruby code, and the placeholder is replaced with its corresponding value or result.

   - Mouse click is provided through args.inputs.mouse.click (or args.inputs.mouse.key_down.left)

   - Mouse right click is provided through args.inputs.mouse.key_down.right
  =end
  def tick args
    args.outputs.labels << { x: 640, y: 360, text: "Click anywhere to play a random sound.", anchor_x: 0.5, anchor_y: 0.5 }
    args.outputs.labels << { x: 640, y: 360, text: "Right Click anywhere to play a random sound at 10% volume.", anchor_x: 0.5, anchor_y: 1.5 }
    args.state.notes ||= [:c3, :d3, :e3, :f3, :g3, :a3, :b3, :c4]

    if args.inputs.mouse.click
      # Play a sound by adding a string to args.outputs.sounds
      args.outputs.sounds << "sounds/#{args.state.notes.sample}.wav" # sound of target note is output
    elsif args.inputs.mouse.key_down.right
      # specifying volume of sound
      args.outputs.sounds << { path: "sounds/#{args.state.notes.sample}.wav", gain: 0.1 }
    end
  end

```
