### Basics - main.rb
```ruby
  # ./samples/12_c_extensions/01_basics/app/main.rb
  DR.ffi_misc.gtk_dlopen("ext")
  include FFI::CExt

  def tick args
    args.outputs.labels  << [640, 500, "mouse.x = #{args.mouse.x.to_i}", 5, 1]
    args.outputs.labels  << [640, 460, "square(mouse.x) = #{square(args.mouse.x.to_i)}", 5, 1]
    args.outputs.labels  << [640, 420, "mouse.y = #{args.mouse.y.to_i}", 5, 1]
    args.outputs.labels  << [640, 380, "square(mouse.y) = #{square(args.mouse.y.to_i)}", 5, 1]
  end


```

### Intermediate - main.rb
```ruby
  # ./samples/12_c_extensions/02_intermediate/app/main.rb
  DR.ffi_misc.gtk_dlopen("ext")
  include FFI::RE

  def split_words(input)
    words = []
    last = IntPointer.new
    re = re_compile("\\w+")
    first = re_matchp(re, input, last)
    while first != -1
      words << input.slice(first, last.value)
      input = input.slice(last.value + first, input.length)
      first = re_matchp(re, input, last)
    end
    words
  end

  def tick args
    args.outputs.labels  << [640, 500, split_words("hello, dragonriders!").join(' '), 5, 1]
  end

```

### Native Pixel Arrays - main.rb
```ruby
  # ./samples/12_c_extensions/03_native_pixel_arrays/app/main.rb
  DR.ffi_misc.gtk_dlopen("ext")
  include FFI::CExt

  def tick args
    args.state.rotation ||= 0

    update_scanner_texture   # this calls into a C extension!

    # New/changed pixel arrays get uploaded to the GPU before we render
    #  anything. At that point, they can be scaled, rotated, and otherwise
    #  used like any other sprite.
    w = 100
    h = 100
    x = (1280 - w) / 2
    y = (720 - h) / 2
    args.outputs.background_color = [64, 0, 128]
    args.outputs.primitives << [x, y, w, h, :scanner, args.state.rotation].sprite
    args.state.rotation += 1

    args.outputs.primitives << DR.current_framerate_primitives
  end


```

### Handcrafted Extension - main.rb
```ruby
  # ./samples/12_c_extensions/04_handcrafted_extension/app/main.rb
  DR.ffi_misc.gtk_dlopen("ext")
  include FFI::CExt

  puts Adder.new.add_all(1, 2, 3, [4, 5, 6.0])

  def tick args
  end

```

### Handcrafted Extension Advanced - main.rb
```ruby
  # ./samples/12_c_extensions/04_handcrafted_extension_advanced/app/main.rb
  def build_c_extension
    v = Time.now.to_i
    DR.exec("cd ./mygame && (env SUFFIX=#{v} sh ./pre.sh 2>&1 | tee ./build-results.txt)")
    build_output = DR.read_file("build-results.txt")
    {
      dll_name: "ext_#{v}",
      build_output: build_output
    }
  end

  def tick args
    # sets console command when sample app initially opens
    if Kernel.global_tick_count == 0
      results = build_c_extension
      dll = results.dll_name
      DR.dlopen(dll)
      puts ""
      puts ""
      puts "========================================================="
      puts "* INFO: Static Sprites, Classes, Draw Override"
      puts "* INFO: Please specify the number of sprites to render."
      DR.console.set_command "reset_with count: 100"
    end

    args.state.star_count ||= 0

    # init
    if Kernel.tick_count == 0
      args.state.stars = args.state.star_count.map { |i| Star.new }
      args.outputs.static_sprites << args.state.stars
    end

    # render framerate
    args.outputs.background_color = [0, 0, 0]
    args.outputs.primitives << DR.current_framerate_primitives
  end

  # resets game, and assigns star count given by user
  def reset_with count: count
    DR.reset
    DR.args.state.star_count = count
  end

  DR.reset

```

### Ios main.rb
```ruby
  # ./samples/12_c_extensions/05_ios_c_extensions/app/main.rb
  # NOTE: This is assumed to be executed with mygame as the root directory
  #       you'll need to copy this code over there to try it out.

  # Steps:
  # 1. Create ext.h and ext.m
  # 2. Create Info.plist file
  # 3. Add before_create_payload to IOSWizard (which does the following):
  #    a. run ./dragonruby-bind against C Extension and update implementation file
  #    b. create output location for iOS Framework
  #    c. compile C extension into Framework
  #    d. copy framework to Payload directory and Sign
  # 4. Run $wizards.ios.start env: (:prod|:dev|:hotload) to create ipa
  # 5. Invoke DR.dlopen giving the name of the C Extensions (~1s to load).
  # 6. Invoke methods as needed.

  # ===================================================
  # before_create_payload iOS Wizard
  # ===================================================
  class IOSWizard < Wizard
    def before_create_payload
      puts "* INFO - before_create_payload"

      # invoke ./dragonruby-bind
      sh "./dragonruby-bind --output=mygame/ext-bind.m mygame/ext.h"

      # update generated implementation file
      contents = DR.read_file "ext-bind.m"
      contents = contents.gsub("#include \"mygame/ext.h\"", "#include \"mygame/ext.h\"\n#include \"mygame/ext.m\"")
      puts contents

      DR.write_file "ext-bind.m", contents

      # create output location
      sh "rm -rf ./mygame/native/ios-device/ext.framework"
      sh "mkdir -p ./mygame/native/ios-device/ext.framework"

      # compile C extension into framework
      if @build_type == :sim
        sh <<-S
  clang -I. -I./mruby/include -I./include -o "./mygame/native/ios-device/ext.framework/ext" \\
        -arch x86_64 -dynamiclib -isysroot "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk" \\
        -install_name @rpath/ext.framework/ext \\
        -fembed-bitcode -Xlinker -rpath -Xlinker @loader_path/Frameworks -dead_strip -Xlinker -rpath -fobjc-arc -fobjc-link-runtime \\
        -F/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks \\
        -miphoneos-version-min=16.4 -Wl,-no_pie -licucore -stdlib=libc++ \\
        -framework CFNetwork -framework UIKit -framework Foundation \\
        ./mygame/ext-bind.m
  S
      else
        sh <<-S
  clang -I. -I./mruby/include -I./include -o "./mygame/native/ios-device/ext.framework/ext" \\
        -arch arm64 -dynamiclib -isysroot "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk" \\
        -install_name @rpath/ext.framework/ext \\
        -fembed-bitcode -Xlinker -rpath -Xlinker @loader_path/Frameworks -dead_strip -Xlinker -rpath -fobjc-arc -fobjc-link-runtime \\
        -F/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks \\
        -miphoneos-version-min=16.4 -Wl,-no_pie -licucore -stdlib=libc++ \\
        -framework CFNetwork -framework UIKit -framework Foundation \\
        ./mygame/ext-bind.m
  S
      end

      # stage extension
      puts "checking info.plist existsance"
      sh "find . -name '*Info.plist*'"
      sh "cp ./mygame/native/ios-device/Info.plist ./mygame/native/ios-device/ext.framework/Info.plist"
      sh "mkdir -p \"#{app_path}/Frameworks/ext.framework/\""
      sh "cp -r \"#{root_dir}/mygame/native/ios-device/ext.framework/\" \"#{app_path}/Frameworks/ext.framework/\""

      # sign
      sh <<-S
  CODESIGN_ALLOCATE=#{codesign_allocate_path} #{codesign_path} \\
                                              -f -s \"#{certificate_name}\" \\
                                              \"#{app_path}/Frameworks/ext.framework/ext\"
  S
    end
  end

  def tick args
    args.state.dir ||= DR.get_dlopen_path
    args.outputs.labels << { x: 640, y: 360, text: "#{args.state.dir}", anchor_x: 0.5, anchor_y: 0.5 }
    if Kernel.tick_count == 60 && DR.platform?(:ios)
      DR.dlopen 'ext'
      include FFI::CExt
      args.state.c_extension_output = hello_world()
    end

    if args.state.c_extension_output
      args.outputs.labels << { x: 640, y: 360, text: "the results of hello_world: #{args.state.c_extension_output}", anchor_x: 0.5, anchor_y: -1.5 }
    end
  end

```

### Handcrafted Mac Extension - main.rb
```ruby
  # ./samples/12_c_extensions/06_handcrafted_mac_extension/app/main.rb
  def boot args
    DR.dlopen 'ext'
  end

  def tick args
    if Kernel.tick_count == 0
      hello = Hello.new
      puts hello.get_message("John Doe")
      bye = Bye.new
      puts bye.get_message("John Doe")
    end
  end

```

### Handcrafted Steam Extensions - main.rb
```ruby
  # ./samples/12_c_extensions/07_handcrafted_steam_extensions/app/main.rb
  def boot args
    DR.dlopen 'ext'
    $steam = Steam.new
    $steam.init_api
  end

  def tick args
    if Kernel.tick_count == 0
      puts "Retrieving user name."
      puts $steam.get_user_name
    end
  end

```

### Handcrafted Android Extension - main.rb
```ruby
  # ./samples/12_c_extensions/08_handcrafted_android_extension/app/main.rb
  def boot args
  end

  def tick args
    if args.inputs.mouse.click && !@dl_opened
      DR.dlopen("ext")
      @dl_opened = true
    elsif args.inputs.mouse.click
      h = UserDefaults.new
      args.state.user_defaults_exist = true
    end

    if !args.state.user_defaults_exist
      args.outputs.labels << { x: 640, y: 360, text: "click to verify C extension", anchor_x: 0.5, anchor_y: 0.5 }
    else
      args.outputs.labels << { x: 640, y: 360, text: "C extension successfully created", anchor_x: 0.5, anchor_y: 0.5 }
    end
  end

```

### Handcrafted Threads - main.rb
```ruby
  # ./samples/12_c_extensions/09_handcrafted_threads/app/main.rb
  def boot args
    DR.dlopen "ext"
  end

  def tick args
    args.state.mode ||= :stopped

    if args.inputs.keyboard.key_down.enter
      if args.state.mode == :stopped
        args.state.mode = :running
        Worker.start_printing
      else
        args.state.mode = :stopped
        Worker.stop_printing
      end
    end

    args.outputs.labels << {
      x: 640,
      y: 680,
      text: "Press Enter to start/stop printing",
      anchor_x: 0.5,
      anchor_y: 0.5,
    }

    args.outputs.labels << {
      x: 640,
      y: 360,
      text: "Printing is #{args.state.mode}",
      anchor_x: 0.5,
      anchor_y: 0.5,
    }
  end

```

### Sqlite3 - main.rb
```ruby
  # ./samples/12_c_extensions/10_sqlite3/app/main.rb
  DR.dlopen "ext"

  def self.boot args
    args.state = {}
  end

  def self.tick args
    if Kernel.tick_count == 0
      DR.delete_file_if_exist "data/game.db"

      SQLite3.open "data/game.db"

      SQLite3.exec <<~S
                     create table if not exists enemies (
                       id   integer primary key autoincrement,
                       name text    not null,
                       hp   integer not null
                     );
                     S

      SQLite3.exec <<~S
                     insert into enemies (name, hp) values ('slime', 10);
                     insert into enemies (name, hp) values ('goblin', 20);
                     insert into enemies (name, hp) values ('dragon', 100);
                     S

      rows = SQLite3.query_json <<~S
                                 select json_object('id', id, 'name', name, 'hp', hp) from enemies;
                                 S

      json_rows = rows.map do |row|
        DR.parse_json row
      end

      pp json_rows
    end
  end

  DR.reset

```
