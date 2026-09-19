module SpriteKit
  # The animation module is fairly opinionated.
  # A typical sprite would look like this:
  # @example
  # sprite = {
  #    x: 0, y: 0, w: 0, h: 0,
  #    animations: {
  #      idle: {
  #        hold_for: 8, # fallback hold_for if hold_for not present on a frame. Default is 1.
  #        repeat: true,
  #        frames: [
  #          {source_x: 0, source_y: 0, source_h: 32, source_w: 32, path: "sprites/foo.png"},
  #          {source_x: 0, source_y: 0, source_h: 32, source_w: 32, hold_for: 4, path: "sprites/foo.png"},
  #        ]
  #      }
  #    }
  # }
  # args.outputs.sprites << ::SpriteKit::Animation.animate!(sprite, frame.animations.idle)
  #
  module Animation
    def self.animate!(sprite, animation)
      frame = current_frame(animation)

      sprite.source_x = frame.source_x
      sprite.source_y = frame.source_y
      sprite.source_w = frame.source_w
      sprite.source_h = frame.source_h
      sprite.path = frame.path
    end

    def self.frame_index(frames:,
                         start_at: 0,
                         repeat: false,
                         # repeat_index: 0,
                         hold_for: 1,
                         tick_count_override: Kernel.tick_count
                        )
      tick_count = tick_count_override
      frame_index = nil

      held_frames = 0
      frames.length.times do |index|
        frame = frames[index]
        held_frames += frame.hold_for || hold_for || 1
        if start_at + held_frames > tick_count
          frame_index = index
          break
        end
      end

      if !frame_index && repeat
        total_duration = held_frames
        elapsed = (tick_count - start_at) % total_duration
        held_frames = 0
        frames.length.times do |index|
          frame = frames[index]
          held_frames += frame.hold_for || hold_for || 1
          if held_frames > elapsed
            frame_index = index
            break
          end
        end
      end

      frame_index
    end

    def self.current_frame(animation, start_at: 0, tick_count_override: Kernel.tick_count)
      return if !animation

      frames = animation&.frames

      if frames.is_a?(Array)
        frame_index = self.frame_index(
          start_at: start_at,
          repeat: animation.repeat,
          hold_for: animation.hold_for,
          tick_count_override: tick_count_override,
          frames: frames
        )

        frames[frame_index] if frame_index
      else
        animation
      end
    end
  end
end
