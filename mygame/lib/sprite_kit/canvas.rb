require SpriteKit.to_load_path("camera")
require SpriteKit.to_load_path("primitives")
require SpriteKit.to_load_path("spritesheet_loader")
require SpriteKit.to_load_path(File.join("ui", "semantic_palette"))
require SpriteKit.to_load_path("serializer")

module SpriteKit
  class Canvas
    attr_accessor :camera

    def initialize(sprite_directory: "sprites")
      @camera = ::SpriteKit::Camera.new
      @spritesheet_loader = SpriteKit::SpritesheetLoader.new
      @spritesheets = @spritesheet_loader.load_directory(sprite_directory)
      @primitives = Primitives.new
      @max_width = 2000
      @rect_size = { w: 16, h: 16 }
    end

    def camera_speed
      3 + (12 / @camera.scale)
    end

    def tick(args)
      input(args)
      calc(args)
      render(args)
    end

    def input(args)
      move_camera(args)
    end

    def calc(args)
      calc_camera(args)
    end

    def render(args)
      render_camera(args)
      render_sprite_canvas(args)
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
      args.outputs[:scene].w = 1500
      args.outputs[:scene].h = 1500
      args.outputs.sprites << { **Camera.viewport, path: :scene }
      args.outputs.debug << "Scale: #{@camera.scale}"
    end

    def render_sprite_canvas(args)
      x = 0
      y = 0
      gap = 40
      current_width = 0

      current_row = []

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

          hover_rect = {}

          world_mouse = Camera.to_world_space(@camera, args.inputs.mouse)
          if Geometry.intersect_rect?(world_mouse, spritesheet_rect)
            rect_size = {
              w: @rect_size.w,
              h: @rect_size.h,
            }

            max_x = spritesheet_rect.x + spritesheet_rect.w - rect_size.w
            min_x = spritesheet_rect.x
            min_y = spritesheet_rect.y
            max_y = spritesheet_rect.y + spritesheet_rect.h - rect_size.h

            rect_x = (world_mouse.x).ifloor(rect_size.w)
            rect_y = (world_mouse.y).ifloor(rect_size.h)

            hover_rect = rect_size.merge!({
              x: rect_x.clamp(min_x, max_x),
              y: rect_y.clamp(min_y, max_y),
              path: :pixel,
              r: 255,
              g: 0,
              b: 0,
              a: 128
            })

            hover_rect = Camera.to_screen_space(@camera, hover_rect)

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
            args.outputs[:scene].primitives << [
              label_background,
              label,
            ]
          end

          args.outputs[:scene].sprites << [spritesheet_target, hover_rect]
        end
      end
    end
  end
end
