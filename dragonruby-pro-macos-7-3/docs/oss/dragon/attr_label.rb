# coding: utf-8
# Copyright 2019 DragonRuby LLC
# MIT License
# attr_line.rb has been released under MIT (*only this file*).

module AttrLabel
  attr_accessor :x, :y, :z,
       :text,
       :size_enum, :alignment_enum,
       :vertical_alignment_enum,
       :r, :g, :b, :a,
       :font,
       :blendmode_enum,
       :anchor_x, :anchor_y, :size_px
end


class Object
  def self.attr_label
    include AttrLabel
  end

  def attr_label
    return if self.is_a? AttrLabel
    self.class.include AttrLabel
  end
end
