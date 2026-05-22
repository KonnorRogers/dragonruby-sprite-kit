# coding: utf-8
# Copyright 2019 DragonRuby LLC
# MIT License
# notify.rb has been released under MIT (*only this file*).

module GTK
  class Runtime
    class Messages; class << self
      def messages_check_thermal_state
        <<-S
* WARNING: Your game (or some other process on the device) is causing the device to have high temps.
You can manually get the current thermal state of the device by calling ~gtk.get_thermal_state~

#+begin_src
  def tick args
    args.outputs.labels << { x: 30, y: 30.from_top, text: "thermal state: \#{$gtk.current_thermal_state}" }
  end
#+end_src

NOTE: ~$gtk.disable_console~ will also disable the CTRL+R reset behavior.
S
      end

      def messages_reset_via_ctrl_r
        <<-S
* INFO: You pressed CTRL+R which is a key combo reserved by DragonRuby.
Pressing CTRL+R invokes ~$gtk.reset_next_tick~ (safely resetting your game with a convenient key combo).

If you want to disable this behavior, add the following to the top of =main.rb=:

#+begin_src
  $gtk.disable_reset_via_ctrl_r

  def tick args
    ...
  end
#+end_src

NOTE: ~$gtk.disable_console~ will also disable the CTRL+R reset behavior.
S
      end

      def messages_stop_music_is_deprecated
        <<-S
* WARNING: ~Runtime#stop_music~ is deprecated and will be removed in future versions.

Sounds that loop are no longer supported via args.outputs.sounds:

1. Migrate over to ~args.audio~ (for more info see type ~args.docs_audio~ in the Console).
2. Delete the usage of ~stop_music~.

For details
S
      end

      def messages_production_errors_readme
        <<-S
* INFO: Getting production errors.
The last exception that occurred will be written to this directory (in
production releases and in dev for testing purposes). If a hard crash
occurs for your game, you can have that information sent to you by the
user by doing the following:

#+begin_src ruby
  def boot args
    # on game boot, see if "errors/last.txt" exists
    last_exception = GTK.read_file "errors/last.txt"

    # if it does, kick off the users default mail app
    if last_exception
      # delete the file (or perform whatever archiving you'd like) so
      # the email flow doesn't occur on next app open
      GTK.delete_file_if_exist "errors/last.txt"

      # construct an email and have it open in user's default email application
      GTK.mailto email: "email@example.com", subject: "\#{Cvars["game_metadata.gametitle"].value} v\#{Cvars["game_metadata.version"].value}", body: last_exception
    end
  end
#+end_src

If you want to disable (or override) this behavior. Add the following to the top of main.rb:
#+begin_src ruby
  class GTK::Runtime
    def export_error! exception_text
      # leave the function body blank to disable completely
      # or override the default behavior to your liking
      # GTK.write_file "custom-location/custom-file-name.txt", exception_text
    end
  end
#+end_src
S
      end
    end; end # end self
  end # end runtime class
end # end gtk
