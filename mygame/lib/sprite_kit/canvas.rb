require SpriteKit.to_load_path("camera")
require SpriteKit.to_load_path("primitives")
require SpriteKit.to_load_path("spritesheet_loader")
require SpriteKit.to_load_path(File.join("ui", "semantic_palette"))
require SpriteKit.to_load_path("serializer")

module SpriteKit
  class Canvas
    attr_accessor :camera, :hover_rect, :current_sprite

    def initialize(sprite_directory: "sprites")
      @camera = ::SpriteKit::Camera.new
      @spritesheet_loader = SpriteKit::SpritesheetLoader.new
      @spritesheets = @spritesheet_loader.load_directory(sprite_directory)
      @primitives = Primitives.new
      @max_width = 2000
      @rect_size = { w: 16, h: 16 }

      @hover_rect = nil
      @hover_rect_screen = nil
      @current_sprite = nil

      @show_grid = false
      @files = []
      @camera_path = :scene
    end

    def camera_render_target
      rt = @outputs[@camera_path]
      @outputs[@camera_path].w = 1500
      @outputs[@camera_path].h = 1500
      rt
    end

    def camera_speed
      3 + (12 / @camera.scale)
    end

    def tick(args)
      @args = args
      @state = args.state
      @outputs = args.outputs
      @inputs = args.inputs
      input(args)
      calc(args)
      render(args)
    end

    def input(args)
      move_camera(args)

      if args.inputs.keyboard.key_down.escape
        @current_sprite = nil
      end

      if args.inputs.keyboard.key_down.g
        @show_grid = !@show_grid
      end
    end

    def calc(args)
      calc_camera(args)

      @world_mouse = Camera.to_world_space(@camera, args.inputs.mouse)
    end

    def render(args)
      render_camera(args)
      render_sprite_canvas(args)
      render_grid_lines(args)
      render_current_sprite(args)

      if @hover_rect_screen
        camera_render_target.sprites << @hover_rect_screen
      end

      args.outputs.debug << @current_sprite.to_s
    end

    def move_camera(args)
      inputs = args.inputs

      speed = camera_speed

      # Movement
      if inputs.keyboard.left_arrow
        @camera.target_x -= speed
      elsif inputs.keyboard.right_arrow
        @camera.target_x += speed
      end

      if inputs.keyboard.down_arrow
        @camera.target_y -= speed
      elsif inputs.keyboard.up_arrow
        @camera.target_y += speed
      end

      # Zoom
      if args.inputs.keyboard.key_down.equal_sign || args.inputs.keyboard.key_down.plus
        @camera.target_scale += 0.25
      elsif args.inputs.keyboard.key_down.minus
        @camera.target_scale -= 0.25
        @camera.target_scale = 0.25 if @camera.target_scale < 0.25
      elsif args.inputs.keyboard.zero
        @camera.target_scale = 1
      end
    end

    def calc_camera(_args)
      ease = 0.1
      @camera.scale += (@camera.target_scale - @camera.scale) * ease

      @camera.x += (@camera.target_x - @camera.x) * ease
      @camera.y += (@camera.target_y - @camera.y) * ease
    end

    def render_camera(args)
      args.outputs.sprites << { **Camera.viewport, path: @camera_path }
      args.outputs.debug << "Scale: #{@camera.scale}"
    end

    def render_sprite_canvas(args)
      x = 0
      y = 0
      gap = 40
      current_width = 0

      current_row = []

      @hover_rect = nil
      @hover_rect_screen = nil

      @spritesheets.each_with_index do |spritesheet, index|
        current_width += spritesheet.file_width

        if index > 0
          prev_spritesheet = @spritesheets[index - 1]
          if current_width + gap + spritesheet.file_width > @max_width
            # move down a row
            current_width = spritesheet.file_width
            y -= current_row.max_by(&:h).h + gap
            x = 0
            current_row = []
          else
            x += prev_spritesheet.file_width + gap
          end
        end

        spritesheet_rect = {
          x: x,
          y: y - spritesheet.file_height,
          w: spritesheet.file_width,
          h: spritesheet.file_height,
          path: spritesheet.path
        }

        current_row << spritesheet_rect

        if Camera.intersect_viewport?(@camera, spritesheet_rect)
          spritesheet_target = Camera.to_screen_space(@camera, spritesheet_rect)

          if Geometry.intersect_rect?(@world_mouse, spritesheet_rect)
            rect_size = {
              w: @rect_size.w,
              h: @rect_size.h,
            }

            rect_x = (@world_mouse.x).ifloor(rect_size.w)
            rect_y = (@world_mouse.y).ifloor(rect_size.h)
            hover_rect_x = rect_x# .clamp(min_x, max_x)
            hover_rect_y = rect_y# .clamp(min_y, max_y)

            @hover_rect = rect_size.merge!({
              x: hover_rect_x,
              y: hover_rect_y,
              path: :pixel,
              r: 255,
              g: 0,
              b: 0,
              a: 128
            })

            if args.inputs.mouse.click
              # TODO: handle -source_x
              # source_x = (@hover_rect.x - spritesheet_rect.x).clamp(0, spritesheet_rect.w - rect_size.w)
              # source_y = (@hover_rect.y - spritesheet_rect.y - rect_size.h).clamp(0, spritesheet_rect.h - rect_size.h)
              source_x = (@hover_rect.x - spritesheet_rect.x)
              source_y = (@hover_rect.y - spritesheet_rect.y)

              # source_w and source_h need to be "clamped" because otherwise you get weird scaling.

              source_w = (rect_size.w).clamp(0, spritesheet.w - source_x)
              # w = 16, source_x = 72 = 88px, but file max is 80. need to chop 8px.
              # w = 16, source_x = 0 = 16px, file max is 80. use 16px.

              source_h = (rect_size.h).clamp(0, spritesheet.h - source_y)
              # h = 16, source_y = 72 = 88px, but file max is 80px. need to chop 8px.
              # h = 16, source_x = 0 = 16px, file max is 80. use 16px.

              @current_sprite = {
                w: rect_size.w,
                h: rect_size.h,
                source_x: source_x,
                source_y: source_y,
                source_w: source_w,
                source_h: source_h,
                path: spritesheet_rect.path
              }
            end

            @hover_rect_screen = Camera.to_screen_space(@camera, @hover_rect)

            label_size = 20
            label = {
              x: spritesheet_target.x + (spritesheet_target.w / 2),
              y: spritesheet_target.y + spritesheet_target.h + label_size,
              text: "#{spritesheet.path}",
              primitive_marker: :label,
              size_px: label_size,
              r: 255,
              b: 255,
              g: 255,
              a: 255,
              anchor_x: 0.5,
              anchor_y: 0.5,
            }
            label_w, label_h = GTK.calcstringbox(label.text, size_px: label_size)
            label_background = label.merge({
              w: label_w + 16,
              h: label_h + 8,
              anchor_x: 0.5,
              anchor_y: 0.5,
              primitive_marker: :solid,
              r: 0,
              b: 0,
              g: 0,
              a: 255
            })
            camera_render_target.primitives << [
              label_background,
              label,
            ]
          end

          camera_render_target.sprites << spritesheet_target
        end
      end
    end

    def render_current_sprite(args)
      if @current_sprite
        @current_sprite.w = @current_sprite.source_w
        @current_sprite.h = @current_sprite.source_h
        @current_sprite.x = @world_mouse.x - (@current_sprite.w / 2)
        @current_sprite.y = @world_mouse.y - (@current_sprite.h / 2)
        args.outputs.debug << { x: @camera.x, y: @camera.y }.to_s

        args.outputs.debug << @current_sprite.to_s
        camera_render_target.sprites << Camera.to_screen_space(@camera, @current_sprite)
      end
    end

    def render_grid_lines(args)
      grid_border_size = 1
      width = 1280
      height = 1280
      tile_size = 16
      if Kernel.tick_count == 0
        args.outputs[:grid].w = width
        args.outputs[:grid].h = height
        args.outputs[:grid].background_color = [0, 0, 0, 0]
        @grid = []
        height.idiv(tile_size).each do |x|
          width.idiv(tile_size).each do |y|
            @grid << { line_type: :horizontal, x: x * tile_size, y: y * tile_size, w: tile_size, h: grid_border_size, r: 200, g: 200, b: 200, a: 255, primitive_marker: :sprite, path: :pixel }
            @grid << { line_type: :vertical, x: x * tile_size, y: y * tile_size, w: grid_border_size, h: tile_size, r: 200, g: 200, b: 200, a: 255, primitive_marker: :sprite, path: :pixel  }
          end
        end
      end

      if !@show_grid
        return
      end

      if @camera.scale != @current_scale
        @current_scale = @camera.scale

        if @camera.scale < 1
          border_size = (grid_border_size / @camera.scale).ceil
        else
          border_size = grid_border_size
        end

        grid_border_size = border_size

        @grid.each do |line|
          line.w = grid_border_size if line[:line_type] == :vertical
          line.h = grid_border_size if line[:line_type] == :horizontal
        end

        # Update the grid with new widths.
        args.outputs[:grid].sprites << @grid
      end

      @grid_boxes ||= 10.flat_map do |x|
        10.map do |y|
          { x: (x - 5) * 1280, y: (y - 5) * 1280, w: 1280, h: 1280, path: :grid, r: 0, b: 0, g: 0, a: 64 }
        end
      end

      if @hover_rect_screen
        @hover_rect_screen.w += grid_border_size + 2
        @hover_rect_screen.h += grid_border_size + 2
      end

      camera_render_target.sprites << @grid_boxes.map do |rect|
        Camera.to_screen_space(@camera, rect)
      end
    end
  end
end
