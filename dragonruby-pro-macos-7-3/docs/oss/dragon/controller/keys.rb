# coding: utf-8
# Copyright 2019 DragonRuby LLC
# MIT License
# controller/keys.rb has been released under MIT (*only this file*).

module GTK
  class Controller
    class Keys
      attr :last_directional_vector

      include Serialize

      LABELS = [
        :up, :down, :left, :right,
        :a, :b, :x, :y,
        :l1, :r1,
        :l2, :r2,
        :l3, :r3,
        :start, :select, :home,
        :directional_up, :directional_down, :directional_left, :directional_right
      ].freeze

      LABELS.each do |label|
        attr label
      end

      alias_method :dpad_up, :directional_up
      alias_method :dpad_down, :directional_down
      alias_method :dpad_left, :directional_left
      alias_method :dpad_right, :directional_right

      alias_method :up_dpad, :directional_up
      alias_method :down_dpad, :directional_down
      alias_method :left_dpad, :directional_left
      alias_method :right_dpad, :directional_right

      def back
        @select
      end

      def back= value
        @select = value
      end

      def guide
        @home
      end

      def guide= value
        @home = value
      end

      # Activate a key.
      #
      # @return [void]
      def activate key
        instance_variable_set("@#{key}", Kernel.tick_count)
      end

      # Deactivate a key.
      #
      # @return [void]
      def deactivate key
        instance_variable_set("@#{key}", nil)
      end

      # Clear all key inputs.
      #
      # @return [void]
      def clear
        LABELS.each { |label| deactivate(label) }
      end

      def truthy_keys
        LABELS.select { |label| send(label) }
      end

      def directional_vector
        l = self.left
        r = self.right
        u = self.up
        d = self.down

        lr = if l && r && last_left_right != 0
               last_left_right
             elsif l
               -1
             elsif r
               1
             else
               0
             end

        ud = if u && d && last_up_down != 0
               last_up_down
             elsif u
               1
             elsif d
               -1
             else
               0
             end

        if lr == 0 && ud == 0
          return nil
        elsif lr.abs == ud.abs
          return { x: 45.vector_x * lr.sign, y: 45.vector_y * ud.sign }
        else
          return { x: lr, y: ud }
        end
      end

      def left_right
        directional_vector&.x&.sign || 0
      end

      def last_left_right
        last_directional_vector&.x&.sign || 0
      end

      def up_down
        directional_vector&.y&.sign || 0
      end

      def last_up_down
        last_directional_vector&.y&.sign || 0
      end

      def directional_angle
        return nil unless directional_vector

        Math.atan2(up_down, left_right).to_degrees
      end
    end
  end
end
