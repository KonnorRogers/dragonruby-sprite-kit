module SpriteKit
  module Mixins
    # Adds support for :animations, :animation_state, :animation_start
    module AnimationMixin
      def self.included(base)
        base.prepend(PrependedMethods)
      end

      module PrependedMethods
        attr_accessor :animation_state, :animations, :animation_start

        def initialize(...)
          super(...)
          @animation_state ||= :idle
          @animations ||= {}
          @animation_start ||= 0
          @animation_prefab = nil
        end
      end


      def initialize(...)
        super(...)
        @animations ||= {}
        # update_sprite
      end


      def update_sprite(sprite = current_frame)
        return if !sprite
        return if !@w || !@h || !@x || !@y

        if sprite&.prefab
          @animation_prefab = sprite.prefab if sprite.prefab.is_a?(Array)
          if sprite.prefab.is_a?(Hash)
            @animation_prefab = sprite.prefab.values
            @animation_prefab.map do |val|
              offset_x = if val.offset_x.is_a?(Proc)
                          val.offset_x.call(self) || 0
                        else
                          val.offset_x || 0
                        end

              offset_y = if val.offset_y.is_a?(Proc)
                          val.offset_y.call(self) || 0
                        else
                          val.offset_y || 0
                        end

              val.x = @x + offset_x
              val.y = @y + offset_y
              val.w = @w
              val.h = @h
            end
          end
        else
          @animation_prefab = nil
          @source_x = sprite.source_x
          @source_y = sprite.source_y
          @source_w = sprite.source_w
          @source_h = sprite.source_h
          @path = sprite.path
        end
      end

      def to_a
        @animation_prefab || self
      end

      def current_frame(action = @animations[@animation_state])
        return if !action

        frames = action&.frames

        if frames.is_a?(Array)
          frame_index = __frame_index(
            start_at: @animation_start,
            repeat: action.repeat,
            tick_count_override: @engine.tick_count,
            frames: frames
          )

          frames[frame_index] if frame_index
        else
          action
        end
      end

      def __frame_index(frames:, start_at: 0, repeat: false, repeat_index: 0, tick_count_override: Kernel.tick_count)
        tick_count = tick_count_override
        held_frames = 0
        frame_index = nil

        frames.length.times do |index|
          frame = frames[index]
          held_frames += (frame.hold_for || 1)
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
            held_frames += (frame.hold_for || 1)
            if held_frames > elapsed
              frame_index = index
              break
            end
          end
        end

        frame_index
      end
    end
  end
end
