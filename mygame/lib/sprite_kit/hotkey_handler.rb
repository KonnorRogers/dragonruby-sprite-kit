module SpriteKit
  class HotkeyHandler
    attr_accessor :current_input
    def initialize(mappings, current_input: :keyboard)
      @mappings = mappings
      @current_input = current_input
    end

    # @example
    #     @input_mappings = {
    #       keyboard: {
      #       undo_change: {
      #         keybindings: [
      #           [:ctrl, :z],
      #           [:meta, :z]
      #         ],
      #         action: -> { undo_change }
      #       },
      #       redo_change: {
      #         keybindings: [
      #           [:ctrl, :shift, :z],
      #           [:meta, :shift, :z]
      #         ],
      #         action: -> { redo_change }
      #       },
      #       save: {
      #         keybindings: [
      #           [:ctrl, :s],
      #           [:meta, :s]
      #         ],
      #         action: -> { save }
      #       },
    #     },
    #     controller: {}
    #   }
    #   HotkeyHandler.new(@input_mappings).tick(args)
    #
    #
    def tick(args)
      @inputs = args.inputs
      # determine what the current input is based on what was last used
      if @inputs.last_active == :controller
        @current_input = :controller_one
      elsif @inputs.last_active == :keyboard
        @current_input = :keyboard
      end

      @mappings[@current_input].each_value do |config|
        config.keybindings.each do |keys|
          if !keys.is_a?(Array)
            keys = [keys]
          end

          keys.each_with_index do |key, index|
            if index == keys.length - 1
              # Convert symbol to string, add a "?" and then check.
              sym = ((config.on || :key_down).to_s + "?").to_sym

              if @inputs.send(@current_input).send(sym, key)
                # Yay. we did it!
                config.action.call
                # Now don't iterate more.
                # We could have multiple running at once?
                # return
              end

              break
            end

            # Just check the key is either down or held.
            break if !keyboard.send(key)
          end
        end
      end
    end
  end
end
