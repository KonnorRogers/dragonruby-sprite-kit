module SpriteKit
  module HotkeyHandler
    def self.handle(keyboard, hotkeys)
      hotkeys.each_value do |config|
        config.keybindings.each do |keys|
          keys.each_with_index do |key, index|
            if index == keys.length - 1
              # Convert symbol to string, add a "?" and then check.
              sym = ((config.on || :key_down).to_s + "?").to_sym

              if keyboard.send(sym, key)
                puts "#{sym} #{key}"
                # Yay. we did it!
                config.action.call
                # Now don't iterate more.
                return
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
