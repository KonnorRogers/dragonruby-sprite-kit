### Retrieve Images - main.rb
```ruby
  # ./samples/11_http/01_retrieve_images/app/main.rb
  DR.register_cvar 'app.warn_seconds', "seconds to wait before starting", :uint, 6

  def tick args
    args.outputs.background_color = [0, 0, 0]

    args.state.download_debounce ||= 0   # start immediately, reset to non zero later.
    args.state.photos ||= []
    if args.state.photos.length > 300
      args.state.photos.pop_front
    end

    # Show a warning at the start.
    args.state.warning_debounce ||= args.cvars['app.warn_seconds'].value * 60
    if args.state.warning_debounce > 0
      args.state.warning_debounce -= 1
      args.outputs.labels << { x: 640, y: 600, text: "This app shows random images from the Internet.", size_enum: 10, alignment_enum: 1, r: 255, g: 255, b: 255 }
      args.outputs.labels << { x: 640, y: 500, text: "Quit in the next few seconds if this is a problem.", size_enum: 10, alignment_enum: 1, r: 255, g: 255, b: 255 }
      args.outputs.labels << { x: 640, y: 350, text: "#{(args.state.warning_debounce / 60.0).to_i}", size_enum: 10, alignment_enum: 1, r: 255, g: 255, b: 255 }
      return
    end

    # Put a little pause between each download.
    if args.state.download.nil?
      if args.state.download_debounce > 0
        args.state.download_debounce -= 1
      else
        args.state.download = DR.http_get 'https://picsum.photos/200/300.jpg'
      end
    end

    if !args.state.download.nil?
      if args.state.download[:complete]
        if args.state.download[:http_response_code] == 200
          fname = "sprites/#{args.state.photos.length}.jpg"
          DR.write_file fname, args.state.download[:response_data]
          args.state.photos << { x: Numeric.rand(100..1180),
                                 y: Numeric.rand(150..570),
                                 path: fname,
                                 angle: Numeric.rand(-40..40) }
        end
        args.state.download = nil
        args.state.download_debounce = Numeric.rand(30..90)
      end
    end

    # draw any downloaded photos...
    args.state.photos.each { |i|
      args.outputs.primitives << { x: i.x, y: i.y, w: 200, h: 300, path: i.path, angle: i.angle, anchor_x: 0.5, anchor_y: 0.5 }
    }

    # Draw a download progress bar...
    args.outputs.primitives << { x: 0, y: 0, w: 1280, h: 30, r: 0, g: 0, b: 0, a: 255, path: :solid }
    if !args.state.download.nil?
      br = args.state.download[:response_read]
      total = args.state.download[:response_total]
      if total != 0
        pct = br.to_f / total.to_f
        args.outputs.primitives << { x: 0, y: 0, w: 1280 * pct, h: 30, r: 0, g: 0, b: 255, a: 255, path: :solid }
      end
    end
  end

```

### In Game Web Server Http Get - main.rb
```ruby
  # ./samples/11_http/02_in_game_web_server_http_get/app/main.rb
  def tick args
    args.state.reqnum ||= 0
    # by default the embedded webserver is disabled in a production build
    # to enable the http server in a production build you need to:
    # - update metadata/cvars.txt
    # - manually start the server up with enable_in_prod set to true:
    DR.start_server! port: 3000, enable_in_prod: true
    args.outputs.background_color = [0, 0, 0]
    args.outputs.labels << { x: 640,
                             y: 360,
                             text: "Point your web browser at http://localhost:#{args.state.port}/",
                             size_px: 30,
                             anchor_x: 0.5,
                             anchor_y: 0.5 }

    args.outputs.labels << { x: 640,
                             y: 360,
                             text: "See metadata/cvars.txt for webserer configuration requirements.",
                             size_px: 30,
                             anchor_x: 0.5,
                             anchor_y: 1.5 }

    if Kernel.tick_count == 1
      DR.openurl "http://localhost:3000"
    end

    args.inputs.http_requests.each { |req|
      puts("METHOD: #{req.method}");
      puts("URI: #{req.uri}");
      puts("HEADERS:");
      req.headers.each { |k,v| puts("  #{k}: #{v}") }

      if (req.uri == '/')
        # headers and body can be nil if you don't care about them.
        # If you don't set the Content-Type, it will default to
        #  "text/html; charset=utf-8".
        # Don't set Content-Length; we'll ignore it and calculate it for you
        args.state.reqnum += 1
        req.respond 200, "<html><head><title>hello</title></head><body><h1>This #{req.method} was request number #{args.state.reqnum}!</h1></body></html>\n", { 'X-DRDR-header' => 'Powered by DragonRuby!' }
      else
        req.reject
      end
    }
  end

```

### In Game Web Server Http Post - main.rb
```ruby
  # ./samples/11_http/03_in_game_web_server_http_post/app/main.rb
  def tick args
    # by default the embedded webserver is disabled in a production build
    # to enable the http server in a production build you need to:
    # - update metadata/cvars.txt
    # - manually start the server up with enable_in_prod set to true:
    DR.start_server! port: $cvars["webserver.port"].value, enable_in_prod: true

    # defaults
    args.state.post_button      = Layout.rect(row: 0, col: 0, w: 5, h: 1).merge(text: "execute http_post")
    args.state.post_body_button = Layout.rect(row: 1, col: 0, w: 5, h: 1).merge(text: "execute http_post_body")
    args.state.request_to_s ||= ""
    args.state.request_body ||= ""

    # render
    args.state.post_button.yield_self do |b|
      args.outputs.borders << b
      args.outputs.labels  << b.merge(text: b.text,
                                      y:    b.y + 30,
                                      x:    b.x + 10)
    end

    args.state.post_body_button.yield_self do |b|
      args.outputs.borders << b
      args.outputs.labels  << b.merge(text: b.text,
                                      y:    b.y + 30,
                                      x:    b.x + 10)
    end

    draw_label args, 0,  6, "Request:", args.state.request_to_s
    draw_label args, 0, 14, "Request Body Unaltered:", args.state.request_body

    # input
    if args.inputs.mouse.click
      # ============= HTTP_POST =============
      if (args.inputs.mouse.inside_rect? args.state.post_button)
        # ========= DATA TO SEND ===========
        form_fields = { "userId" => "#{Time.now.to_i}" }
        # ==================================

        DR.http_post "http://localhost:9001/testing",
                           form_fields,
                           ["Content-Type: application/x-www-form-urlencoded"]

        DR.notify! "http_post"
      end

      # ============= HTTP_POST_BODY =============
      if (args.inputs.mouse.inside_rect? args.state.post_body_button)
        # =========== DATA TO SEND ==============
        json = "{ \"userId\": \"#{Time.now.to_i}\"}"
        # ==================================

        DR.http_post_body "http://localhost:9001/testing",
                                json,
                                ["Content-Type: application/json", "Content-Length: #{json.length}"]

        DR.notify! "http_post_body"
      end
    end

    # calc
    args.inputs.http_requests.each do |r|
      puts "#{r}"
      if r.uri == "/testing"
        puts r
        args.state.request_to_s = "#{r}"
        args.state.request_body = r.raw_body
        r.respond 200, "ok"
      end
    end
  end

  def draw_label args, row, col, header, text
    label_pos = Layout.rect(row: row, col: col, w: 0, h: 0)
    args.outputs.labels << "#{header}\n\n#{text}".wrapped_lines(80).map_with_index do |l, i|
      { x: label_pos.x, y: label_pos.y - (i * 15), text: l, size_enum: -2 }
    end
  end

```

### Http Post External Server - main.rb
```ruby
  # ./samples/11_http/04_http_post_external_server/app/main.rb
  def tick args
    if Kernel.tick_count == 60
      DR.notify("Performing HTTP/POST to https://httpbin.org/anything")
      url = "https://httpbin.org/anything"
      content = '{ "message": "hello world" }'
      args.state.auth_result ||= DR.http_post_body(url, content,
                                                    [
                                                      "Content-Type: application/json",
                                                      "Content-Length: #{content.length.to_i}"
                                                    ])
    end

    if Kernel.tick_count > 120
      if args.state.auth_result.complete
        args.state.auth_result.response_data.to_s.wrapped_lines(80).each_with_index do |l, i|
          args.outputs.labels << { x: 8,
                                   y: 700,
                                   text: l,
                                   anchor_x: 0,
                                   anchor_y: 0.5 + (i * 1) }
        end
      end
    end
  end

```
