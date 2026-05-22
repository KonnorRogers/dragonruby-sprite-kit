# coding: utf-8
# Copyright 2019 DragonRuby LLC
# MIT License
# tick.rb has been released under MIT (*only this file*).

module GTK
  class Runtime
    module Tick
      # will be invoked if Kernel.global_tick_count == 0
      def boot_core
        $main.boot @args if $main.respond_to? :boot
      end

      # will be invoked if DR.reset is invoked,
      # before internal reset is performed
      # Kernel.tick_count will be the frame reset was invoked
      def reset_core
        if $main.respond_to? :reset
          if $main.method(:reset).parameters.length == 1
            $main.reset @args
          else
            $main.reset
          end
        end
      end

      # will be invoked if DR.reset is invoked,
      # after internal reset is performed
      # Kernel.tick_count will be -1
      def did_reset_core
        if $main.respond_to? :did_reset
          if $main.method(:did_reset).parameters.length == 1
            $main.did_reset @args
          else
            $main.did_reset
          end
        end
      end

      # core tick function that invokes
      # tick in user code
      def tick_core
        @is_inside_tick = true
        $main.tick @args if Kernel.tick_count >= 0
        @is_inside_tick = false
      end

      def inside_tick?
        @is_inside_tick
      end
    end
  end
end

module GTK
  class Runtime
    include Tick
  end
end
