# coding: utf-8
# Copyright 2019 DragonRuby LLC
# MIT License
# attr_gtk.rb has been released under MIT (*only this file*).

module AttrDR
  def args= value
    @args = value
  end

  def args
    @args
  end

  def keyboard
    @keyboard ||= @args.inputs.keyboard
  end

  def grid
    @grid ||= @args.grid
  end

  def state
    @state ||= @args.state
  end

  def temp_state
    @temp_state ||= @args.temp_state
  end

  def inputs
    @inputs ||= @args.inputs
  end

  def outputs
    @outputs ||= @args.outputs
  end

  def gtk
    @gtk ||= @args.gtk
  end

  def passes
    @passes ||= @args.passes
  end

  def pixel_arrays
    @pixel_arrays ||= @args.pixel_arrays
  end

  def geometry
    @geometry ||= @args.geometry
  end

  def layout
    @layout ||= @args.layout
  end

  def easing
    @easing ||= @args.easing
  end

  def audio
    @audio ||= @args.audio
  end

  def events
    @events ||= @args.events
  end

  def cvars
    @cvars ||= @args.cvars
  end

  def new_entity entity_type, init_hash = nil, &block
    self.state.new_entity entity_type, init_hash, &block
  end

  def new_entity_strict entity_type, init_hash = nil, &block
    self.state.new_entity_strict entity_type, init_hash, &block
  end

  def tick_count
    Kernel.tick_count
  end

  def global_tick_count
    Kernel.global_tick_count
  end
end

AttrGTK = AttrDR

class Module
  def attr_gtk
    include AttrDR
  end

  def attr_dr
    include AttrDR
  end
end

class Object
  def self.attr_gtk
    include AttrDR
  end

  def self.attr_dr
    include AttrDR
  end

  def attr_gtk
    return if self.is_a? AttrDR
    self.class.include AttrDR
  end

  def attr_dr
    return if self.is_a? AttrDR
    self.class.include AttrDR
  end
end
