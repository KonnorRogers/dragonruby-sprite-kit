### 3d Cube - main.rb
```ruby
  # ./samples/99_genre_3d/01_3d_cube/app/main.rb
  STARTX             = 0.0
  STARTY             = 0.0
  ENDY               = 20.0
  ENDX               = 20.0
  SPINPOINT          = 10
  SPINDURATION       = 400
  POINTSIZE          = 8
  BOXDEPTH           = 40
  YAW                = 1
  DISTANCE           = 10

  def tick args
    args.outputs.background_color = [0, 0, 0]
    a = Math.sin(Kernel.tick_count / SPINDURATION) * Math.tan(Kernel.tick_count / SPINDURATION)
    s = Math.sin(a)
    c = Math.cos(a)
    x = STARTX
    y = STARTY
    offset_x = (1280 - (ENDX - STARTX)) / 2
    offset_y =  (360 - (ENDY - STARTY)) / 2

    srand(1)
    while y < ENDY do
      while x < ENDX do
        if (y == STARTY ||
            y == (ENDY / 0.5) * 2 ||
            y == (ENDY / 0.5) * 2 + 0.5 ||
            y == ENDY - 0.5 ||
            x == STARTX ||
            x == ENDX - 0.5)
          z = rand(BOXDEPTH)
          z *= Math.sin(a / 2)
          x -= SPINPOINT
          u = (x * c) - (z * s)
          v = (x * s) + (z * c)
          k = DISTANCE.fdiv(100) + (v / 500 * YAW)
          u = u / k
          v = y / k
          w = POINTSIZE / 10 / k
          args.outputs.sprites << { x: offset_x + u - w, y: offset_y + v - w, w: w, h: w, path: 'sprites/square-blue.png'}
          x += SPINPOINT
        end
        x += 0.5
      end
      y += 0.5
      x = STARTX
    end
  end

  DR.reset

```

### Wireframe - main.rb
```ruby
  # ./samples/99_genre_3d/02_wireframe/app/main.rb
  def tick args
    args.state.model   ||= Object3D.new('data/shuttle.off')
    args.state.mtx     ||= rotate3D(0, 0, 0)
    args.state.inv_mtx ||= rotate3D(0, 0, 0)
    delta_mtx          = rotate3D(args.inputs.up_down * 0.01, input_roll(args) * 0.01, args.inputs.left_right * 0.01)
    args.outputs.lines << args.state.model.edges
    args.state.model.fast_3x3_transform! args.state.inv_mtx
    args.state.inv_mtx = mtx_mul(delta_mtx.transpose, args.state.inv_mtx)
    args.state.mtx     = mtx_mul(args.state.mtx, delta_mtx)
    args.state.model.fast_3x3_transform! args.state.mtx
    args.outputs.background_color = [0, 0, 0]
    args.outputs.debug << DR.framerate_diagnostics_primitives
  end

  def input_roll args
    roll = 0
    roll += 1 if args.inputs.keyboard.e
    roll -= 1 if args.inputs.keyboard.q
    roll
  end

  def rotate3D(theta_x = 0.1, theta_y = 0.1, theta_z = 0.1)
    c_x, s_x = Math.cos(theta_x), Math.sin(theta_x)
    c_y, s_y = Math.cos(theta_y), Math.sin(theta_y)
    c_z, s_z = Math.cos(theta_z), Math.sin(theta_z)
    rot_x    = [[1, 0, 0], [0, c_x, -s_x], [0, s_x, c_x]]
    rot_y    = [[c_y, 0, s_y], [0, 1, 0], [-s_y, 0, c_y]]
    rot_z    = [[c_z, -s_z, 0], [s_z, c_z, 0], [0, 0, 1]]
    mtx_mul(mtx_mul(rot_x, rot_y), rot_z)
  end

  def mtx_mul(a, b)
    is = (0...a.length)
    js = (0...b[0].length)
    ks = (0...b.length)
    is.map do |i|
      js.map do |j|
        ks.map do |k|
          a[i][k] * b[k][j]
        end.reduce(&:plus)
      end
    end
  end

  class Object3D
    attr_reader :vert_count, :face_count, :edge_count, :verts, :faces, :edges

    def initialize(path)
      @vert_count = 0
      @face_count = 0
      @edge_count = 0
      @verts      = []
      @faces      = []
      @edges      = []
      _init_from_file path
    end

    def _init_from_file path
      file_lines = DR.read_file(path).split("\n")
                       .reject { |line| line.start_with?('#') || line.split(' ').length == 0 } # Strip out simple comments and blank lines
                       .map { |line| line.split('#')[0] } # Strip out end of line comments
                       .map { |line| line.split(' ') } # Tokenize by splitting on whitespace
      raise "OFF file did not start with OFF." if file_lines.shift != ["OFF"] # OFF meshes are supposed to begin with "OFF" as the first line.
      raise "<NVertices NFaces NEdges> line malformed" if file_lines[0].length != 3 # The second line needs to have 3 numbers. Raise an error if it doesn't.
      @vert_count, @face_count, @edge_count = file_lines.shift&.map(&:to_i) # Update the counts
      # Only the vertex and face counts need to be accurate. Raise an error if they are inaccurate.
      raise "Incorrect number of vertices and/or faces (Parsed VFE header: #{@vert_count} #{@face_count} #{@edge_count})" if file_lines.length != @vert_count + @face_count
      # Grab all the lines describing vertices.
      vert_lines = file_lines[0, @vert_count]
      # Grab all the lines describing faces.
      face_lines = file_lines[@vert_count, @face_count]
      # Create all the vertices
      @verts = vert_lines.map_with_index { |line, id| Vertex.new(line, id) }
      # Create all the faces
      @faces = face_lines.map { |line| Face.new(line, @verts) }
      # Create all the edges
      @edges = @faces.flat_map(&:edges).uniq do |edge|
        sorted = edge.sorted
        [sorted.point_a, sorted.point_b]
      end
    end

    def fast_3x3_transform! mtx
      @verts.each { |vert| vert.fast_3x3_transform! mtx }
    end
  end

  class Face

    attr_reader :verts, :edges

    def initialize(data, verts)
      vert_count = data[0].to_i
      vert_ids   = data[1, vert_count].map(&:to_i)
      @verts     = vert_ids.map { |i| verts[i] }
      @edges     = []
      (0...vert_count).each { |i| @edges[i] = Edge.new(verts[vert_ids[i - 1]], verts[vert_ids[i]]) }
      @edges.rotate! 1
    end
  end

  class Edge
    attr_reader :point_a, :point_b

    def initialize(point_a, point_b)
      @point_a = point_a
      @point_b = point_b
    end

    def sorted
      @point_a.id < @point_b.id ? self : Edge.new(@point_b, @point_a)
    end

    def draw_override ffi
      ffi.draw_line(@point_a.render_x, @point_a.render_y, @point_b.render_x, @point_b.render_y, 255, 0, 0, 128)
      ffi.draw_line(@point_a.render_x+1, @point_a.render_y, @point_b.render_x+1, @point_b.render_y, 255, 0, 0, 128)
      ffi.draw_line(@point_a.render_x, @point_a.render_y+1, @point_b.render_x, @point_b.render_y+1, 255, 0, 0, 128)
      ffi.draw_line(@point_a.render_x+1, @point_a.render_y+1, @point_b.render_x+1, @point_b.render_y+1, 255, 0, 0, 128)
    end

    def primitive_marker
      :line
    end
  end

  class Vertex
    attr_accessor :x, :y, :z, :id

    def initialize(data, id)
      @x  = data[0].to_f
      @y  = data[1].to_f
      @z  = data[2].to_f
      @id = id
    end

    def fast_3x3_transform! mtx
      _x, _y, _z = @x, @y, @z
      @x         = mtx[0][0] * _x + mtx[0][1] * _y + mtx[0][2] * _z
      @y         = mtx[1][0] * _x + mtx[1][1] * _y + mtx[1][2] * _z
      @z         = mtx[2][0] * _x + mtx[2][1] * _y + mtx[2][2] * _z
    end

    def render_x
      @x * (10 / (5 - @y)) * 170 + 640
    end

    def render_y
      @z * (10 / (5 - @y)) * 170 + 360
    end
  end
```

### Yaw Pitch Roll - main.rb
```ruby
  # ./samples/99_genre_3d/03_yaw_pitch_roll/app/main.rb
  class Game
    include MatrixFunctions

    attr_dr

    def tick
      defaults
      render
      input
    end

    def player_ship
      [
        # engine back
        (vec4  -1,  -1,  1,  0),
        (vec4  -1,   1,  1,  0),

        (vec4  -1,   1,  1,  0),
        (vec4   1,   1,  1,  0),

        (vec4   1,   1,  1,  0),
        (vec4   1,  -1,  1,  0),

        (vec4   1,  -1,  1,  0),
        (vec4  -1,  -1,  1,  0),

        # engine front
        (vec4  -1,  -1,  -1,  0),
        (vec4  -1,   1,  -1,  0),

        (vec4  -1,   1,  -1,  0),
        (vec4   1,   1,  -1,  0),

        (vec4   1,   1,  -1,  0),
        (vec4   1,  -1,  -1,  0),

        (vec4   1,  -1,  -1,  0),
        (vec4  -1,  -1,  -1,  0),

        # engine left
        (vec4  -1,   -1,  -1,  0),
        (vec4  -1,   -1,   1,  0),

        (vec4  -1,   -1,   1,  0),
        (vec4  -1,    1,   1,  0),

        (vec4  -1,    1,   1,  0),
        (vec4  -1,    1,  -1,  0),

        (vec4  -1,    1,  -1,  0),
        (vec4  -1,   -1,  -1,  0),

        # engine right
        (vec4   1,   -1,  -1,  0),
        (vec4   1,   -1,   1,  0),

        (vec4   1,   -1,   1,  0),
        (vec4   1,    1,   1,  0),

        (vec4   1,    1,   1,  0),
        (vec4   1,    1,  -1,  0),

        (vec4   1,    1,  -1,  0),
        (vec4   1,   -1,  -1,  0),

        # top front of engine to front of ship
        (vec4   1,    1,  1,  0),
        (vec4   0,   -1,  9,  0),

        (vec4   0,   -1,  9,  0),
        (vec4  -1,    1,  1,  0),

        # bottom front of engine
        (vec4   1,   -1,  1,  0),
        (vec4   0,   -1,  9,  0),

        (vec4  -1,   -1,  1,  0),
        (vec4   0,   -1,  9,  0),

        # right wing
        # front of wing
        (vec4  1,  0.10,   1,  0),
        (vec4  9,  0.10,  -1,  0),

        (vec4   9,  0.10,  -1,  0),
        (vec4  10,  0.10,  -2,  0),

        # back of wing
        (vec4  1,  0.10,  -1,  0),
        (vec4  9,  0.10,  -1,  0),

        (vec4  10,  0.10,  -2,  0),
        (vec4   8,  0.10,  -1,  0),

        # front of wing
        (vec4  1,  -0.10,   1,  0),
        (vec4  9,  -0.10,  -1,  0),

        (vec4   9,  -0.10,  -1,  0),
        (vec4  10,  -0.10,  -2,  0),

        # back of wing
        (vec4  1,  -0.10,  -1,  0),
        (vec4  9,  -0.10,  -1,  0),

        (vec4  10,  -0.10,  -2,  0),
        (vec4   8,  -0.10,  -1,  0),

        # left wing
        # front of wing
        (vec4  -1,  0.10,   1,  0),
        (vec4  -9,  0.10,  -1,  0),

        (vec4  -9,  0.10,  -1,  0),
        (vec4  -10,  0.10,  -2,  0),

        # back of wing
        (vec4  -1,  0.10,  -1,  0),
        (vec4  -9,  0.10,  -1,  0),

        (vec4  -10,  0.10,  -2,  0),
        (vec4  -8,  0.10,  -1,  0),

        # front of wing
        (vec4  -1,  -0.10,   1,  0),
        (vec4  -9,  -0.10,  -1,  0),

        (vec4  -9,  -0.10,  -1,  0),
        (vec4  -10,  -0.10,  -2,  0),

        # back of wing
        (vec4  -1,  -0.10,  -1,  0),
        (vec4  -9,  -0.10,  -1,  0),
        (vec4  -10,  -0.10,  -2,  0),
        (vec4   -8,  -0.10,  -1,  0),

        # left fin
        # top
        (vec4  -1,  0.10,  1,  0),
        (vec4  -1,  3,  -3,  0),

        (vec4  -1,  0.10,  -1,  0),
        (vec4  -1,  3,  -3,  0),

        (vec4  -1.1,  0.10,  1,  0),
        (vec4  -1.1,  3,  -3,  0),

        (vec4  -1.1,  0.10,  -1,  0),
        (vec4  -1.1,  3,  -3,  0),

        # bottom
        (vec4  -1,  -0.10,  1,  0),
        (vec4  -1,  -2,  -2,  0),

        (vec4  -1,  -0.10,  -1,  0),
        (vec4  -1,  -2,  -2,  0),

        (vec4  -1.1,  -0.10,  1,  0),
        (vec4  -1.1,  -2,  -2,  0),

        (vec4  -1.1,  -0.10,  -1,  0),
        (vec4  -1.1,  -2,  -2,  0),

        # right fin
        (vec4   1,  0.10,  1,  0),
        (vec4   1,  3,  -3,  0),

        (vec4   1,  0.10,  -1,  0),
        (vec4   1,  3,  -3,  0),

        (vec4   1.1,  0.10,  1,  0),
        (vec4   1.1,  3,  -3,  0),

        (vec4   1.1,  0.10,  -1,  0),
        (vec4   1.1,  3,  -3,  0),

        # bottom
        (vec4   1,  -0.10,  1,  0),
        (vec4   1,  -2,  -2,  0),

        (vec4   1,  -0.10,  -1,  0),
        (vec4   1,  -2,  -2,  0),

        (vec4   1.1,  -0.10,  1,  0),
        (vec4   1.1,  -2,  -2,  0),

        (vec4   1.1,  -0.10,  -1,  0),
        (vec4   1.1,  -2,  -2,  0),
      ]
    end

    def defaults
      state.points ||= player_ship
      state.shifted_points ||= state.points.map { |point| point }

      state.scale   ||= 1
      state.angle_x ||= 0
      state.angle_y ||= 0
      state.angle_z ||= 0
    end

    def angle_z_matrix degrees
      cos_t = Math.cos degrees.to_radians
      sin_t = Math.sin degrees.to_radians
      (mat4 cos_t, -sin_t, 0, 0,
            sin_t,  cos_t, 0, 0,
            0,      0,     1, 0,
            0,      0,     0, 1)
    end

    def angle_y_matrix degrees
      cos_t = Math.cos degrees.to_radians
      sin_t = Math.sin degrees.to_radians
      (mat4  cos_t,  0, sin_t, 0,
             0,      1, 0,     0,
             -sin_t, 0, cos_t, 0,
             0,      0, 0,     1)
    end

    def angle_x_matrix degrees
      cos_t = Math.cos degrees.to_radians
      sin_t = Math.sin degrees.to_radians
      (mat4  1,     0,      0, 0,
             0, cos_t, -sin_t, 0,
             0, sin_t,  cos_t, 0,
             0,     0,      0, 1)
    end

    def scale_matrix factor
      (mat4 factor,      0,      0, 0,
            0,      factor,      0, 0,
            0,           0, factor, 0,
            0,           0,      0, 1)
    end

    def input
      if (inputs.keyboard.shift && inputs.keyboard.p)
        state.scale -= 0.1
      elsif  inputs.keyboard.p
        state.scale += 0.1
      end

      if inputs.mouse.wheel
        state.scale += inputs.mouse.wheel.y
      end

      state.scale = state.scale.clamp(0.1, 1000)

      if (inputs.keyboard.shift && inputs.keyboard.y) || inputs.keyboard.right
        state.angle_y += 1
      elsif (inputs.keyboard.y) || inputs.keyboard.left
        state.angle_y -= 1
      end

      if (inputs.keyboard.shift && inputs.keyboard.x) || inputs.keyboard.down
        state.angle_x -= 1
      elsif (inputs.keyboard.x || inputs.keyboard.up)
        state.angle_x += 1
      end

      if inputs.keyboard.shift && inputs.keyboard.z
        state.angle_z += 1
      elsif inputs.keyboard.z
        state.angle_z -= 1
      end

      if inputs.keyboard.zero
        state.angle_x = 0
        state.angle_y = 0
        state.angle_z = 0
      end

      angle_x = state.angle_x
      angle_y = state.angle_y
      angle_z = state.angle_z
      scale   = state.scale

      s_matrix = scale_matrix state.scale
      x_matrix = angle_z_matrix angle_z
      y_matrix = angle_y_matrix angle_y
      z_matrix = angle_x_matrix angle_x

      state.shifted_points = state.points.map do |point|
        (mul point, y_matrix, x_matrix, z_matrix, s_matrix).merge(original: point)
      end
    end

    def thick_line line
      [
        line.merge(y: line.y - 1, y2: line.y2 - 1, r: 0, g: 0, b: 0),
        line.merge(x: line.x - 1, x2: line.x2 - 1, r: 0, g: 0, b: 0),
        line.merge(x: line.x - 0, x2: line.x2 - 0, r: 0, g: 0, b: 0),
        line.merge(y: line.y + 1, y2: line.y2 + 1, r: 0, g: 0, b: 0),
        line.merge(x: line.x + 1, x2: line.x2 + 1, r: 0, g: 0, b: 0)
      ]
    end

    def render
      outputs.lines << state.shifted_points.each_slice(2).map do |(p1, p2)|
        perc = 0
        thick_line({ x:  p1.x.*(10) + 640, y:  p1.y.*(10) + 320,
                     x2: p2.x.*(10) + 640, y2: p2.y.*(10) + 320,
                     r: 255 * perc,
                     g: 255 * perc,
                     b: 255 * perc })
      end

      outputs.labels << [ 10, 700, "angle_x: #{state.angle_x.to_sf}", 0]
      outputs.labels << [ 10, 670, "x, shift+x", 0]

      outputs.labels << [210, 700, "angle_y: #{state.angle_y.to_sf}", 0]
      outputs.labels << [210, 670, "y, shift+y", 0]

      outputs.labels << [410, 700, "angle_z: #{state.angle_z.to_sf}", 0]
      outputs.labels << [410, 670, "z, shift+z", 0]

      outputs.labels << [610, 700, "scale: #{state.scale.to_sf}", 0]
      outputs.labels << [610, 670, "p, shift+p", 0]
    end
  end

  $game = Game.new

  def tick args
    $game.args = args
    $game.tick
  end

  def set_angles x, y, z
    $game.state.angle_x = x
    $game.state.angle_y = y
    $game.state.angle_z = z
  end

  DR.reset

```

### Ray Caster - main.rb
```ruby
  # ./samples/99_genre_3d/04_ray_caster/app/main.rb
  # https://github.com/BrennerLittle/DragonRubyRaycast
  # https://github.com/3DSage/OpenGL-Raycaster_v1
  # https://www.youtube.com/watch?v=gYRrGTC7GtA&ab_channel=3DSage

  def tick args
    defaults args
    calc args
    render args
    args.outputs.sprites << { x: 0, y: 0, w: 1280 * 2.66, h: 720 * 2.25, path: :screen }
    args.outputs.labels  << { x: 30, y: 30.from_top, text: "FPS: #{DR.current_framerate.to_sf}" }
  end

  def defaults args
    args.state.stage ||= {
      w: 8,
      h: 8,
      sz: 64,
      layout: [
        1, 1, 1, 1, 1, 1, 1, 1,
        1, 0, 1, 0, 0, 0, 0, 1,
        1, 0, 1, 0, 0, 1, 0, 1,
        1, 0, 1, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 0, 0, 1, 0, 1,
        1, 0, 0, 0, 0, 0, 0, 1,
        1, 1, 1, 1, 1, 1, 1, 1,
      ]
    }

    args.state.player ||= {
      x: 250,
      y: 250,
      dx: 1,
      dy: 0,
      angle: 0
    }
  end

  def calc args
    xo = 0

    if args.state.player.dx < 0
      xo = -20
    else
      xo = 20
    end

    yo = 0

    if args.state.player.dy < 0
      yo = -20
    else
      yo = 20
    end

    ipx = args.state.player.x.idiv 64.0
    ipx_add_xo = (args.state.player.x + xo).idiv 64.0
    ipx_sub_xo = (args.state.player.x - xo).idiv 64.0

    ipy = args.state.player.y.idiv 64.0
    ipy_add_yo = (args.state.player.y + yo).idiv 64.0
    ipy_sub_yo = (args.state.player.y - yo).idiv 64.0

    if args.inputs.keyboard.right
      args.state.player.angle -= 5
      args.state.player.angle = args.state.player.angle % 360
      args.state.player.dx = args.state.player.angle.cos_d
      args.state.player.dy = -args.state.player.angle.sin_d
    end

    if args.inputs.keyboard.left
      args.state.player.angle += 5
      args.state.player.angle = args.state.player.angle % 360
      args.state.player.dx = args.state.player.angle.cos_d
      args.state.player.dy = -args.state.player.angle.sin_d
    end

    if args.inputs.keyboard.up
      if args.state.stage.layout[ipy * args.state.stage.w + ipx_add_xo] == 0
        args.state.player.x += args.state.player.dx * 5
      end

      if args.state.stage.layout[ipy_add_yo * args.state.stage.w + ipx] == 0
        args.state.player.y += args.state.player.dy * 5
      end
    end

    if args.inputs.keyboard.down
      if args.state.stage.layout[ipy * args.state.stage.w + ipx_sub_xo] == 0
        args.state.player.x -= args.state.player.dx * 5
      end

      if args.state.stage.layout[ipy_sub_yo * args.state.stage.w + ipx] == 0
        args.state.player.y -= args.state.player.dy * 5
      end
    end
  end

  def render args
    args.outputs[:screen].sprites << { x: 0,
                                       y: 160,
                                       w: 750,
                                       h: 160,
                                       path: :pixel,
                                       r: 89,
                                       g: 125,
                                       b: 206 }

    args.outputs[:screen].sprites << { x: 0,
                                       y: 0,
                                       w: 750,
                                       h: 160,
                                       path: :pixel,
                                       r: 117,
                                       g: 113,
                                       b: 97 }


    ra = (args.state.player.angle + 30) % 360

    60.times do |r|
      dof = 0
      side = 0
      dis_v = 100000
      ra_tan = ra.tan_d

      if ra.cos_d > 0.001
        rx = ((args.state.player.x >> 6) << 6) + 64
        ry = (args.state.player.x - rx) * ra_tan + args.state.player.y;
        xo = 64
        yo = -xo * ra_tan
      elsif ra.cos_d < -0.001
        rx = ((args.state.player.x >> 6) << 6) - 0.0001
        ry = (args.state.player.x - rx) * ra_tan + args.state.player.y
        xo = -64
        yo = -xo * ra_tan
      else
        rx = args.state.player.x
        ry = args.state.player.y
        dof = 8
      end

      while dof < 8
        mx = rx >> 6
        mx = mx.to_i
        my = ry >> 6
        my = my.to_i
        mp = my * args.state.stage.w + mx
        if mp > 0 && mp < args.state.stage.w * args.state.stage.h && args.state.stage.layout[mp] == 1
          dof = 8
          dis_v = ra.cos_d * (rx - args.state.player.x) - ra.sin_d * (ry - args.state.player.y)
        else
          rx += xo
          ry += yo
          dof += 1
        end
      end

      vx = rx
      vy = ry

      dof = 0
      dis_h = 100000
      ra_tan = 1.0 / ra_tan

      if ra.sin_d > 0.001
        ry = ((args.state.player.y >> 6) << 6) - 0.0001;
        rx = (args.state.player.y - ry) * ra_tan + args.state.player.x;
        yo = -64;
        xo = -yo * ra_tan;
      elsif ra.sin_d < -0.001
        ry = ((args.state.player.y >> 6) << 6) + 64;
        rx = (args.state.player.y - ry) * ra_tan + args.state.player.x;
        yo = 64;
        xo = -yo * ra_tan;
      else
        rx = args.state.player.x
        ry = args.state.player.y
        dof = 8
      end

      while dof < 8
        mx = (rx) >> 6
        my = (ry) >> 6
        mp = my * args.state.stage.w + mx
        if mp > 0 && mp < args.state.stage.w * args.state.stage.h && args.state.stage.layout[mp] == 1
          dof = 8
          dis_h = ra.cos_d * (rx - args.state.player.x) - ra.sin_d * (ry - args.state.player.y)
        else
          rx += xo
          ry += yo
          dof += 1
        end
      end

      color = { r: 52, g: 101, b: 36 }

      if dis_v < dis_h
        rx = vx
        ry = vy
        dis_h = dis_v
        color = { r: 109, g: 170, b: 44 }
      end

      ca = (args.state.player.angle - ra) % 360
      dis_h = dis_h * ca.cos_d
      line_h = (args.state.stage.sz * 320) / (dis_h)
      line_h = 320 if line_h > 320

      line_off = 160 - (line_h >> 1)

      args.outputs[:screen].sprites << {
        x: r * 8,
        y: line_off,
        w: 8,
        h: line_h,
        path: :pixel,
        **color
      }

      ra = (ra - 1) % 360
    end
  end

```

### Ray Caster Advanced - main.rb
```ruby
  # ./samples/99_genre_3d/04_ray_caster_advanced/app/main.rb
  # This sample is a more advanced example of raycasting that is based on the lodev raycasting articles.
  # Refer to the prior sample to to understand the fundamental raycasting algorithm.
  # This sample adds:
  #  * Variable number of rays, field of view, and canvas size.
  #  * Wall textures
  #  * Inverse square law "drop off" lighting
  #  * Weapon firing
  #  * Drawing of sprites within the level.

  # Contributors outside of DragonRuby who also hold Copyright:
  # - James Stocks: https://github.com/james-stocks
  # - Alex Mooney: https://github.com/AlexMooney

  # https://github.com/BrennerLittle/DragonRubyRaycast
  # https://lodev.org/cgtutor/raycasting.html
  # https://github.com/3DSage/OpenGL-Raycaster_v1
  # https://www.youtube.com/watch?v=gYRrGTC7GtA&ab_channel=3DSage

  # For a *really* advanced ray caster, check out https://github.com/sojastar/dr_raycaster

  def tick args
    defaults args
    update_player args
    update_missiles args
    update_enemies args
    render(args)

    w = args.state.camera[:screen_width]
    h = args.state.camera[:screen_height]
    args.outputs.sprites << { x: 0, y: 0, w: w, h: h, source_h: h, path: :screen }
    debug_text = <<~LABEL
      FPS: #{DR.current_framerate.to_sf}
      angle: #{args.state.player.angle.to_i}°
      X: #{args.state.player.x.to_sf}
      Y: #{args.state.player.y.to_sf}
      Screen Size (h/j/k/l): #{w}x#{h}
      FOV (u/i): #{args.state.camera[:field_of_view]}°
      Rays (o/p): #{args.state.camera[:number_of_rays]}
    LABEL
    args.outputs.labels << { x: 30, y: 30.from_top, text: debug_text }
  end

  def defaults args
    args.state.stage ||= {
      layout: [
        [1, 1, 1, 2, 1, 1, 2, 1, 1, 2, 1, 1, 2, 1],
        [1, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3],
        [1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 3],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 3],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0],
        [1, 3, 3, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0],
        [1, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0],
        [1, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 0, 3],
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 3],
        [1, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3],
        [1, 1, 1, 3, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1],
      ]
    }
    # 2d array layout means we can calculate width and height instead of having to specify them.
    args.state.stage[:w] ||= args.state.stage.layout[0].size
    args.state.stage[:h] ||= args.state.stage.layout.size

    args.state.player ||= {
      x: 5.5,
      y: 5,
      dx: -1,
      dy: 0,
      speed: 1.0 / 16.0,
      closest_allowed_to_wall: 0.5,
      angle: 180,
      angular_speed: 5,
      fire_cooldown_wait: 0,
      fire_cooldown_duration: 15
    }

    # Add an initial alien enemy.
    # The :bright property indicates that this entity doesn't produce light and should appear dimmer over distance.
    args.state.enemies ||= [
      { x: 2.5, y: 2.5, type: :alien, bright: false, expired: false },
      { x: 6.5, y: 5.5, type: :alien, bright: false, expired: false },
      { x: 2.5, y: 7.5, type: :alien, bright: false, expired: false }
    ]
    args.state.missiles ||= []
    args.state.splashes ||= []
    args.state.camera ||= {
      screen_width: 1280,
      screen_height: 720,
      number_of_rays: 160, # Number of rays to cast determines the resolution of the raycast view.
      field_of_view: 60 # Field of view in degrees
    }
  end

  # Update the player's input and movement
  def update_player args
    player = args.state.player

    if args.inputs.keyboard.right
      player.angle -= player.angular_speed
      player.angle = player.angle % 360
      player.dx = player.angle.cos_d.round(6)
      player.dy = -player.angle.sin_d.round(6)
    end

    if args.inputs.keyboard.left
      player.angle += player.angular_speed
      player.angle = player.angle % 360
      player.dx = player.angle.cos_d.round(6)
      player.dy = -player.angle.sin_d.round(6)
    end

    # Check to see if player will get within closest_allowed_to_wall distance to a wall by going forward or backward.
    grid_x = player.x.to_i
    delta_x = player.closest_allowed_to_wall * player.dx.sign
    grid_x_forward = (player.x + delta_x).to_i
    grid_x_backward = (player.x - delta_x).to_i

    grid_y = player.y.to_i
    delta_y = player.closest_allowed_to_wall * player.dy.sign
    grid_y_forward = (player.y + delta_y).to_i
    grid_y_backward = (player.y - delta_y).to_i

    stage = args.state.stage
    if args.inputs.keyboard.up
      player.x += player.dx * player.speed if stage.layout[grid_y][grid_x_forward] == 0
      player.y += player.dy * player.speed if stage.layout[grid_y_forward][grid_x] == 0
    end

    if args.inputs.keyboard.down
      player.x -= player.dx * player.speed if stage.layout[grid_y][grid_x_backward] == 0
      player.y -= player.dy * player.speed if stage.layout[grid_y_backward][grid_x] == 0
    end

    player.fire_cooldown_wait -= 1 if player.fire_cooldown_wait > 0
    if args.inputs.keyboard.key_down.space && player.fire_cooldown_wait == 0
      m = { x: player.x, y: player.y, angle: player.angle, speed: 1.0/12, type: :missile, bright: true, expired: false }
      # Immediately move the missile forward a frame so it spawns ahead of the player
      m.x += m.angle.cos_d * m.speed
      m.y -= m.angle.sin_d * m.speed
      args.state.missiles << m
      player.fire_cooldown_wait = player.fire_cooldown_duration
    end

    # Allow messing with camera settings here.
    if args.inputs.keyboard.key_down.u
      args.state.camera[:field_of_view] -= 5
    elsif args.inputs.keyboard.key_down.i
      args.state.camera[:field_of_view] += 5
    elsif args.inputs.keyboard.key_down.h
      args.state.camera[:screen_width] -= 40
    elsif args.inputs.keyboard.key_down.l
      args.state.camera[:screen_width] += 40
    elsif args.inputs.keyboard.key_down.j
      args.state.camera[:screen_height] -= 40
    elsif args.inputs.keyboard.key_down.k
      args.state.camera[:screen_height] += 40
    elsif args.inputs.keyboard.key_down.o
      args.state.camera[:number_of_rays] -= 10
    elsif args.inputs.keyboard.key_down.p
      args.state.camera[:number_of_rays] += 10
    end
    args.state.camera[:field_of_view] = args.state.camera[:field_of_view].clamp(15, 180)
    args.state.camera[:screen_width] = args.state.camera[:screen_width].clamp(20, 1280)
    args.state.camera[:screen_height] = args.state.camera[:screen_height].clamp(20, 720)
    args.state.camera[:number_of_rays] = args.state.camera[:number_of_rays].clamp(10, 1280)
  end

  def update_missiles args
    # Remove expired missiles by mapping expired missiles to `nil` and then calling `compact!` to
    # remove nil entries.
    args.state.missiles.map! { |m| m.expired ? nil : m }
    args.state.missiles.compact!

    args.state.missiles.each do |m|
      new_x = m.x + m.angle.cos_d * m.speed
      new_y = m.y - m.angle.sin_d * m.speed
      # Hit enemies
      args.state.enemies.each do |e|
        if (new_x - e.x).abs < 0.25 && (new_y - e.y).abs < 0.25
          e.expired = true
          m.expired = true
          args.state.splashes << { x: m.x, y: m.y, ttl: 5, type: :splash, bright: true }
          next
        end
      end
      # Hit walls
      if args.state.stage.layout[new_y.to_i][new_x.to_i] != 0
        m.expired = true
        args.state.splashes << { x: m.x, y: m.y, ttl: 5, type: :splash, bright: true }
      else
        m.x = new_x
        m.y = new_y
      end
    end
    args.state.splashes.map! { |s| ((s.ttl -= 1) < 0) ? nil : s }
    args.state.splashes.compact!
  end

  def update_enemies args
    args.state.enemies.map! { |e| e.expired ? nil : e }
    args.state.enemies.compact!
  end

  def render args
    screen_width = args.state.camera[:screen_width]
    screen_height = args.state.camera[:screen_height]
    number_of_rays = args.state.camera[:number_of_rays]
    max_draw_distance = 24 # How many tiles away until the ray stops drawing
    light_length = 10 # How many tiles away until brightness is 25%
    texture_width = 64 # Width of the wall textures in pixels

    player = args.state.player

    # Build a camera vector perpendicular to player's angle with magnitide set to get desired FOV.
    camera_scale = (args.state.camera[:field_of_view] / 2.0).tan_d
    player_dir_x = player.angle.cos_d
    player_dir_y = player.angle.sin_d
    camera_dir_x = camera_scale * (player.angle + 90.0).cos_d
    camera_dir_y = camera_scale * (player.angle + 90.0).sin_d

    slice_width = screen_width / number_of_rays

    # Render the sky
    args.outputs[:screen].sprites << { x: 0,
                                       y: screen_height / 2,
                                       w: screen_width,
                                       h: screen_height / 2,
                                       path: :pixel,
                                       r: 89,
                                       g: 125,
                                       b: 206 }

    # Render the floor
    args.outputs[:screen].sprites << { x: 0,
                                       y: 0,
                                       w: screen_width,
                                       h: screen_height / 2,
                                       path: :pixel,
                                       r: 117,
                                       g: 113,
                                       b: 97 }

    # Collect sprites for the raycast view into an array - these will all be rendered with a single draw call.
    # This gives a substantial performance improvement over the previous sample where there was one draw call
    # per sprite.
    sprites_to_draw = []

    # Save distances of each wall hit. This is used subsequently when drawing sprites.
    depths = []

    # Cast however many rays across the FOV evenly.
    number_of_rays.times do |ray_idx|
      camera_x = -2.0 * ray_idx / number_of_rays + 1.0 # Screen coordinate: -1 is left edge, +1 is right edge
      ray_dir_x = player_dir_x + camera_dir_x * camera_x
      ray_dir_y = -(player_dir_y + camera_dir_y * camera_x)

      # Are x and y moving in positive or negative direction?
      step_x = ray_dir_x.sign
      step_y = ray_dir_y.sign

      # Which map cell the ray is currently in.
      map_x = player.x.to_i
      # map_x += 1 if step_x.positive?
      map_y = player.y.to_i
      # map_y += 1 if step_y.negative?

      # Distance to go from one x or y grid line to the next. These will be used to step to the next map edge.
      delta_dist_x = (ray_dir_x == 0) ? Float::INFINITY : (1 / ray_dir_x).abs
      delta_dist_y = (ray_dir_y == 0) ? Float::INFINITY : (1 / ray_dir_y).abs

      # Distance the ray travels to cross the closest x or y grid line. Initialized based on player's position.
      side_dist_x = if ray_dir_x.negative?
                      (player.x - map_x) * delta_dist_x
                    else
                      (map_x + 1 - player.x) * delta_dist_x
                    end
      side_dist_y = if ray_dir_y.negative?
                      (player.y - map_y) * delta_dist_y
                    else
                      (map_y + 1 - player.y) * delta_dist_y
                    end

      # DDA: find the first wall hit by stepping through the map along the ray.
      hit = false
      hit_side = nil
      wall_texture = nil
      max_draw_distance.times do
        if side_dist_x < side_dist_y
          # Move to the next vertical grid line
          side_dist_x += delta_dist_x
          map_x += step_x
          hit_side = :vertical
        else
          # Move to the next horizontal grid line
          side_dist_y += delta_dist_y
          map_y += step_y
          hit_side = :horizontal
        end
        # Stop if we have gone out of bounds of the map.
        break if !(0...args.state.stage.w).cover?(map_x) || !(0...args.state.stage.h).cover?(map_y)

        # Check if the ray hit a wall
        if args.state.stage.layout[map_y][map_x] > 0
          wall_texture = args.state.stage.layout[map_y][map_x]
          hit = true
          break
        end
      end

      # Calculate the distance from the camera plane to the wall hit and the wall texture coordinates.
      camera_distance = Float::INFINITY
      texture_x = 0
      if hit && hit_side == :vertical
        camera_distance = side_dist_x - delta_dist_x
        texture_x = player.y + camera_distance * ray_dir_y
      elsif hit && hit_side == :horizontal
        camera_distance = side_dist_y - delta_dist_y
        texture_x = player.x + camera_distance * ray_dir_x
      end
      texture_x = ((texture_x % 1.0) * texture_width).to_i
      # If player is looking backwards towards a tile then flip the side of the texture to sample.
      # The sample wall textures have a diagonal stripe pattern - if you comment out these 2 lines,
      # you will see what goes wrong with texturing.
      if (hit_side == :vertical && step_x.positive?) || (hit_side == :horizontal && step_y.negative?)
        texture_x = 63 - texture_x
      end

      next if !hit

      # Determine the render height for the strip proportional to the display height
      line_height = (screen_height / camera_distance)
      line_offset = ((screen_height - line_height) / 2.0)

      # Tint the wall strip - the further away it is, the darker, following an inverse square law.
      euclidean_distance = (ray_dir_x**2 + ray_dir_y**2)**0.5 * camera_distance
      # Store the game world distance for a wall hit at this angle for sprite ordering later.
      depths << euclidean_distance

      tint = 1.0 - (euclidean_distance / light_length)**2

      sprites_to_draw << {
        x: ray_idx * slice_width,
        y: line_offset,
        w: slice_width,
        h: line_height,
        path: "sprites/wall_#{wall_texture}.png",
        source_x: texture_x,
        source_w: 1,
        r: 255 * tint,
        g: 255 * tint,
        b: 255 * tint
      }
    end

    # Render sprites
    # Use common render code for enemies, missiles and explosion splashes.
    # This works because they are all hashes with :x, :y, and :type fields.
    things_to_draw = []
    things_to_draw.push(*args.state.enemies)
    things_to_draw.push(*args.state.missiles)
    things_to_draw.push(*args.state.splashes)

    # Do a first-pass on the things to draw, calculate distance from player and then sort so more-distant things are drawn
    # first.  We are using this only to sort, so don't spend time calculating the square root.
    things_to_draw.each do |thing|
      thing[:dist_squared] = Geometry.distance_squared([args.state.player[:x], args.state.player[:y]], [thing[:x], thing[:y]]).abs
    end
    things_to_draw = things_to_draw.sort_by { |thing| thing[:dist_squared] }

    # Now draw everything, most distant entities first.
    things_to_draw.reverse_each do |thing|
      # The crux of drawing a sprite in a raycast view is to:
      #   1. rotate the enemy around the player's position and viewing angle to get a position relative to the view.
      #   2. Translate that position from "3D space" to screen pixels.
      thing_delta_x = thing[:x] - args.state.player.x
      thing_delta_y = thing[:y] - args.state.player.y

      rotated_delta_x = thing_delta_y * player_dir_x + thing_delta_x * player_dir_y
      # This is the euclidean distance to thing when thing's in front of us but it is negative when things's behind us.
      distance_to_thing = thing_delta_x * player_dir_x - thing_delta_y * player_dir_y
      next unless distance_to_thing.positive?

      # The next 4 lines determine the screen x and y of (the center of) the entity, and a scale
      next if distance_to_thing == 0 # Avoid invalid Infinity/NaN calculations if the projected Y is 0
      scale_y = screen_height / distance_to_thing
      scale_x = screen_width / (2 * distance_to_thing * camera_scale)
      screen_x = screen_width * rotated_delta_x / (2 * distance_to_thing * camera_scale) + screen_width / 2.0
      screen_y = screen_height / 2 - scale_y * 0.5
      tint = thing[:bright] ? 1.0 : 1.0 - (distance_to_thing / light_length)**2

      # Now we know the x and y on-screen for the entity, and its scale, we can draw it. Simply drawing the sprite on the
      # screen doesn't work in a raycast view because the entity might be partly obscured by a wall. Instead we draw the
      # entity in vertical strips, skipping strips if a wall is closer to the player on that strip of the screen. To do
      # this perfectly, you'd have to align the vertical strips with the raycast rays. This approach is a good
      # approximation

      # Since dx stores the center x of the enemy on-screen, we start half the scale of the enemy to the left of dx
      x = screen_x - scale_x / 2
      next if x > screen_width || (screen_x + scale_x / 2 <= 0) # Skip rendering if the X position is entirely off-screen
      strip = 0                    # Keep track of the number of strips we've drawn
      strip_width = scale_x / 64   # Draw the sprite in 64 strips
      sample_width = 1             # For each strip we will sample 1/64 of sprite image, here we assume 64x64 sprites

      while x < screen_x + scale_x / 2 do
        if (-strip_width..screen_width).cover?(x)
          # Here we get the distance to the wall for this strip on the screen
          wall_depth = depths[(x / (screen_width / number_of_rays)).round] || Float::INFINITY
          if distance_to_thing < wall_depth
            sprites_to_draw << {
              x: x,
              y: screen_y,
              w: strip_width,
              h: scale_y,
              path: "sprites/#{thing[:type]}.png",
              source_x: strip * sample_width,
              source_w: sample_width,
              r: 255 * tint,
              g: 255 * tint,
              b: 255 * tint
            }
          end
        end
        x += strip_width
        strip += 1
      end
    end

    # Draw all the sprites we collected in the array to the render target
    args.outputs[:screen].sprites << sprites_to_draw
  end

```

### Mode7 - main.rb
```ruby
  # ./samples/99_genre_3d/05_mode7/app/main.rb
  include Math

  # to use:
  # - put a 1024x1024 terrain png as sprites/map.png
  # - put four images (or as many as you want) in sprites/xxx.png
  # - set up the sprites you want to use in atlases_setup(): filename,width,height
  # - place the sprites on the map by modifying sprites_setup(): x,y,atlasid
  #   - note that 0,0 is the center of the map

  class Mode7
  	def atlas_add(img,w,h)
  		@atlasImg << img
  		@atlasW << w
  		@atlasH << h
  	end

  	def atlases_setup()
  		atlas_add("sprites/tree1.png",16,29)
  		atlas_add("sprites/tree2.png",16,28)
  		atlas_add("sprites/tree3.png",15,30)
  		atlas_add("sprites/tree4.png",32,32)
  	end

  	def camera_change(dx,dy,dz,dir,df)
  		@fov += df
  		if (dir != 0)
  			@angY += dir
  			# put the sprite in the center of the 2kx2k rendertarget, and rotate appropriately
  			@args.render_target(:land).sprites << {	x: 1024,
  													y: 1024,
  													anchor_x: 0.5,
  													anchor_y: 0.5,
  													scale_quality_enum: 0,
  													w: 1024,
  													h: 1024,
  													path: "sprites/map.png",
  													angle: @angY
  			}
  		end
  		# deg to rads
  		radX = @angX*0.01745329
  		radY = @angY*0.01745329
  		# update physical x/y of camera based on angle
  		@physX -= dx*cos(radY)-dy*sin(radY)
  		@physY += dx*sin(radY)+dy*cos(radY)
  		# rotate camera to match position on rendertarget
  		@camX = @physX*cos(radY)-@physY*sin(radY)+1024
  		@camY = @physX*sin(radY)+@physY*cos(radY)+1024
  		@camZ += dz
  		# set up other calcs for sprites etc
  		@camProjectionPlaneYCenter = (360*sin(radX))
  		@dirX = sin(radY)
  		@dirY = cos(radY)
  		@planeX = cos(radY)*@fov
  		@planeY = -sin(radY)*@fov
  	end

  	def floor_draw()
  		camX = @camX
  		camY = @camY
  		top = @camZ-360.0
  		for y in (0..359) do
  			zRatio = (top*100).fdiv(y-360.0)
  			if (zRatio)<2048
  				sx = camX-(zRatio/2)
  				sy = camY+(zRatio)
  				pixelStretch = (1280/zRatio)
  				sw = sx+zRatio
  				offset = ((sx-sx.floor()))*pixelStretch
  				lessWidth = (1-(zRatio-zRatio.floor()))*pixelStretch
  				@args.outputs.sprites << {	x: -offset,
  											y: y,
  											w: 1280+lessWidth+pixelStretch,
  											h: 1,
  											scale_quality_enum: 0,
  											path: :land,
  											source_x: sx,
  											source_y: sy,
  											source_w: zRatio+1,
  											source_h: 1 }
  			end
  		end
  	end

  	def initialize(args)
  		@args = args
  		args.gtk.enable_console
  		args.render_target(:land).w = 2048
  		args.render_target(:land).h = 2048
  		@physX = -430.0 # actual location in rectangular grid
  		@physY = -135.0
  		@camX = 0 # location on the rendertarget after rotation
  		@camY = 0
  		@camZ = 240
  		@fov = 0.5 #66
  		@angX = 0 # vertical up/down
  		@angY = 0 # angle of the rendertarget
  		@dirX = 0
  		@dirY = 0
  		@planeX = 0
  		@planeY = 0
  		@landY = 0
  		# temp test
  		@zMap = []
  		@zRatio = []
  		@minilength = 0
  		@screenX = []
  		@screenY = []
  		@screenZ = []
  		@scale = 5.0
  		@imgW = []
  		@imgH = []
  		@atlasImg = []
  		@atlasW = []
  		@atlasH = []
  		@renderX = []
  		@renderY = []
  		@renderZ = []
  		@renderPath = []
  		# camera setting has to be last
  		camera_change(0,0,0,0.1,0)
  		camera_change(0,0,0,-0.1,0)
  		atlases_setup()
  		sprites_setup()
  	end

  	def player_move()
  		camera_change( 2, 0, 0, 0, 0) if @args.inputs.keyboard.q
  		camera_change(-2, 0, 0, 0, 0) if @args.inputs.keyboard.e
  		camera_change( 0, 3, 0, 0, 0) if @args.inputs.keyboard.up
  		camera_change( 0,-3, 0, 0, 0) if @args.inputs.keyboard.down
  		camera_change( 0, 0, 0,-1, 0) if @args.inputs.keyboard.left
  		camera_change( 0, 0, 0, 1, 0) if @args.inputs.keyboard.right
  		camera_change( 0, 0,-2, 0, 0) if @args.inputs.keyboard.r
  		camera_change( 0, 0, 2, 0, 0) if @args.inputs.keyboard.f
  	end

  	def render_clear()
  		@args.outputs.static_sprites.clear
  		@minirender = []
  		@minilength = 0
  	end

  	def render_set()
  		@args.outputs.static_sprites << @minirender
  	end

  	def render_update()
  		# update the position of each sprite in the array.
  		# remember, this isn't doing any more calcs of movement or anything else, just updating for the camera movement.
  		# we could always do a smoothing between an old and new coordinate later if it's an issue.
  		invDet = 1.fdiv(@planeX*@dirY-@dirX*@planeY) #required for correct matrix multiplication regardless of frame
  		rs = @minirender.size
  		for index in 0...rs
  			spriteX = @minirender[index].sx-@physX
  			spriteY = @minirender[index].sy-@physY
  			transformY = invDet*(-@planeY*spriteX+@planeX*spriteY) #this is actually the depth inside the screen, that what Z is in 3D
  			if (transformY > 0)
  				transformX = invDet*(@dirY*spriteX-@dirX*spriteY)
  				spriteScreenX = ((1280/2)*(1+transformX/transformY))
  				spriteWidth = 720*(@minirender[index].imgw/(transformY))
  				# check if sprite is off screen
  				if ((spriteScreenX+spriteWidth) > 0) and ((spriteScreenX-spriteWidth) < 1280)
  					spriteHeight = 720*(@minirender[index].imgh/(transformY)) #using 'transformY' instead of the real distance prevents fisheye
  					drawStartY = (((@camZ-360)*100)/transformY)+360
  					drawStartX = spriteScreenX
  					@minirender[index].x = drawStartX
  					@minirender[index].y = drawStartY
  					@minirender[index].w = spriteWidth
  					@minirender[index].h = spriteHeight
  				else
  					@minirender[index].w = 0
  					@minirender[index].h = 0
  				end
  			else
  				@minirender[index].w = 0
  				@minirender[index].h = 0
  			end
  		end
  	end

  	def sprites_draw()
  		# draw sprites back to front
  		# every x frames, create the mini array of sprites and link it to the static sprite list
  		invDet = 1.fdiv(@planeX*@dirY-@dirX*@planeY) #required for correct matrix multiplication regardless of frame
  		rs = @renderX.size
  		for index in 0...rs
  			spriteX = @renderX[index]-@physX
  			spriteY = @renderY[index]-@physY
  			transformY = invDet*(-@planeY*spriteX+@planeX*spriteY) #this is actually the depth inside the screen, that what Z is in 3D
  			if (transformY > 0)
  				transformX = invDet*(@dirY*spriteX-@dirX*spriteY)
  				spriteScreenX = ((1280/2)*(1+transformX/transformY))
  				spriteWidth = 720*(@imgW[index]/(transformY))
  				# check if sprite is off screen
  				if ((spriteScreenX+spriteWidth) > -100) and ((spriteScreenX-spriteWidth) < 1380) # allow for a little overlap to cover sprites that come in view before next update
  					spriteHeight = 720*(@imgH[index]/(transformY)) #using 'transformY' instead of the real distance prevents fisheye
  					drawStartY = (((@camZ-360)*100)/transformY)+360
  					drawStartX = spriteScreenX
  					minisprite = {	x: drawStartX,
  									y: drawStartY,
  									sx: @renderX[index],
  									sy: @renderY[index],
  									z: transformY,
  									w: spriteWidth,
  									h: spriteHeight,
  									imgw: @imgW[index],
  									imgh: @imgH[index],
  									anchor_x: 0.5,
  									anchor_y: 0,
  									path: @renderPath[index]}
  					if (@minilength == 0)
  						@minirender << minisprite
  					else
  						# insert the element sorted
  						j = @minilength-1
  						# start from back end
  						while (j >= 0) and (@minirender[j].z < transformY)
  							@minirender[j+1] = @minirender[j] #shift element right
  							j -= 1
  						end
  						@minirender[j+1] = minisprite #insert element
  					end
  					@minilength += 1
  				end
  			end
  		end
  	end

  	def sprites_setup()
  		@renderX = []
  		@renderY = []
  		@renderZ = []
  		@renderPath = []
  		tx = -64
  		while tx < 64
  			sprites_setup_helper(tx,63,0)
  			sprites_setup_helper(63,tx,1)
  			sprites_setup_helper(tx,-64,2)
  			sprites_setup_helper(-64,tx,3)
  			tx += 2
  		end
  		sprites_setup_helper(-47,35,0)
  		sprites_setup_helper(-47,34,0)
  		sprites_setup_helper(-47,33,0)
  		sprites_setup_helper(-47,32,0)
  		sprites_setup_helper(-46,32,0)
  		sprites_setup_helper(-45,32,0)
  		sprites_setup_helper(-44,32,0)
  		sprites_setup_helper(-43,43,0)
  		sprites_setup_helper(-42,43,0)
  		sprites_setup_helper(-41,43,0)
  		sprites_setup_helper(-40,43,0)
  		sprites_setup_helper(-39,43,0)
  		sprites_setup_helper(-38,43,0)
  		sprites_setup_helper(-37,43,0)
  		sprites_setup_helper(-36,43,0)
  		sprites_setup_helper(-35,43,0)
  		sprites_setup_helper(-34,43,0)
  		sprites_setup_helper(-33,43,0)
  		sprites_setup_helper(-32,43,0)
  		sprites_setup_helper(-8,36,0)
  		sprites_setup_helper(-8,37,0)
  		sprites_setup_helper(-8,38,0)
  		sprites_setup_helper(-8,39,0)
  		sprites_setup_helper(-8,40,0)
  		sprites_setup_helper(-8,41,0)
  		sprites_setup_helper(-8,42,0)
  		sprites_setup_helper(-8,43,0)
  		sprites_setup_helper(-8,44,0)
  		sprites_setup_helper(-8,45,0)
  		sprites_setup_helper(-8,46,0)
  		sprites_setup_helper(-8,47,0)
  		sprites_setup_helper(-8,48,0)
  		sprites_setup_helper(-8,49,0)
  	end

  	def sprites_setup_helper(tx,ty,p)
  		@renderX << (tx*8)+4
  		@renderY << (ty*8)+4
  		@renderZ << 0
  		@imgW << @atlasW[p]
  		@imgH << @atlasH[p]
  		@renderPath << @atlasImg[p]
  	end
  end

  def tick(args)
  	args.state.game = Mode7.new(args) if (Kernel.tick_count == 0)
  	args.state.game.player_move()
  	args.state.game.floor_draw()
  	if (Kernel.tick_count.mod(10) == 0)
  		args.state.game.render_clear()
  		args.state.game.sprites_draw()
  		args.state.game.render_set()
  	else
  		args.state.game.render_update()
  	end
  	args.outputs.labels << [640, 540, "Keys: Q,W,E,A,S,D,R,F", 5, 1]
  end

```
