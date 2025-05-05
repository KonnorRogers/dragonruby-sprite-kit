require SpriteKit.to_load_path("camera")

module SpriteKit
  class Canvas
    attr_accessor :camera

    def initialize
      @camera = ::SpriteKit::Camera.new
    end

    def tick(args)
      calc_camera
      move_camera(args)
      render_sprite_canvas(args)

      args.outputs.sprites << { **Camera.viewport, path: :scene }

      args.outputs[:scene].w = 1500
      args.outputs[:scene].h = 1500
    end

    def move_camera(args)
      inputs = args.inputs

      speed = 3 + (3 / @camera.scale)

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

    def calc_camera
      ease = 0.1
      @camera.scale += (@camera.target_scale - @camera.scale) * ease

      @camera.x += (@camera.target_x - @camera.x) * ease
      @camera.y += (@camera.target_y - @camera.y) * ease
    end

    def render_sprite_canvas(args)
      to_render_target = ->(index) { ("__spritesheet_canvas__#{index}").to_sym }

      @spritesheet_tiles = []

      if !@sprites
        @spritesheet_target = []

        @spritesheets.each_with_index do |spritesheet, index|
          render_target = to_render_target.call(index)
          args.outputs[render_target].w = spritesheet.w
          args.outputs[render_target].h = spritesheet.h
          args.outputs[render_target].background_color = [0, 0, 0, 0]
          args.outputs[render_target].sprites << spritesheet.tiles.map do |sprite|
            sprite.x = sprite.source_x
            sprite.y = sprite.source_y
            sprite.w = sprite.source_w
            sprite.h = sprite.source_h
            sprite.dup
          end
        end
      end

      prev_x = ((Camera::SCREEN_WIDTH / -4)).ifloor(TILE_SIZE)

      y = 0 # (Camera::SCREEN_HEIGHT / -4)
      gap = TILE_SIZE

      # @rendered_spritesheets = []
      @spritesheets.each_with_index do |spritesheet, index|
        render_target = to_render_target.call(index)

        if index > 0
          prev_x += @spritesheets[index - 1].file_width + gap
        end

        spritesheet_rect = {
          x: prev_x,
          y: y,
          w: spritesheet.file_width,
          h: spritesheet.file_height,
          path: render_target
        }

        if Camera.intersect_viewport?(@camera, spritesheet_rect)
          spritesheet_target = Camera.to_screen_space(@camera, spritesheet_rect)

          label = {
            x: spritesheet_target.x,
            y: spritesheet_target.y - (8 * @camera.scale).ceil,
            text: "#{spritesheet.name}",
            primitive_marker: :label,
            size_px: (16 * @camera.scale).ceil
          }

          normalized_tiles = spritesheet.tiles.map do |sprite|
            sprite = sprite.dup
            sprite.x = spritesheet_rect.x + (sprite.x)
            sprite.y = spritesheet_rect.y + (sprite.y)
            sprite
          end
          @spritesheet_tiles.concat(normalized_tiles)

          args.outputs[:scene].sprites << [
            spritesheet_target,
            @primitives.create_borders(spritesheet_target, border_width: 1, color: {r: 0, b: 0, g: 0, a: 255}).values
          ]
          args.outputs[:scene].labels << label
        end
      end
    end
  end
end
