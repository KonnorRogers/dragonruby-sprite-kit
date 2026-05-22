# coding: utf-8
# Copyright 2019 DragonRuby LLC
# MIT License
# hotload.rb has been released under MIT (*only this file*).

module GTK
  class KeyboardKeys
    include Serialize

    def initialize
      @keycodes = {}
    end

    def self.alias_method from, to
      @aliases ||= {}
      @aliases[from] = to
      super from, to
    end

    def self.aliases
      @aliases
    end

    attr_accessor :tilde, :underscore, :double_quotation_mark,
                  :exclamation_point, :at, :hash, :dollar,
                  :percent, :caret, :ampersand, :asterisk,
                  :open_round_brace, :close_round_brace,
                  :open_curly_brace, :close_curly_brace, :colon,
                  :plus, :pipe, :question_mark, :less_than,
                  :greater_than, :keycodes

    attr_accessor :section, :ordinal_indicator, :superscript_two

    attr_accessor :raw_key, :char

    attr_accessor :zero, :one, :two, :three, :four,
                  :five, :six, :seven, :eight, :nine,
                  :backspace, :delete, :escape, :enter, :tab,
                  :open_square_brace, :close_square_brace,
                  :semicolon, :equal,
                  :hyphen, :space,
                  :single_quotation_mark,
                  :backtick,
                  :period, :comma,
                  :a, :b, :c, :d, :e, :f, :g, :h,
                  :i, :j, :k, :l, :m, :n, :o, :p,
                  :q, :r, :s, :t, :u, :v, :w, :x,
                  :y, :z,
                  :forward_slash, :back_slash

    attr_accessor :caps_lock,
                  :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10, :f11, :f12,
                  :print_screen, :scroll_lock, :pause,
                  :insert, :home, :page_up,
                  :delete, :end, :page_down,
                  :left_arrow, :right_arrow, :up_arrow, :down_arrow

    attr_accessor :num_lock, :kp_divide, :kp_multiply, :kp_minus, :kp_plus, :kp_enter,
                  :kp_one, :kp_two, :kp_three, :kp_four, :kp_five,
                  :kp_six, :kp_seven, :kp_eight, :kp_nine, :kp_zero,
                  :kp_period, :kp_equals

    attr_accessor :shift, :control, :alt, :meta,
                  :shift_left, :shift_right,
                  :control_left, :control_right,
                  :alt_left, :alt_right,
                  :meta_left, :meta_right

    attr_accessor :ac_search, :ac_home, :ac_back, :ac_forward, :ac_stop, :ac_refresh, :ac_bookmarks

    attr_accessor :w_scancode, :a_scancode, :s_scancode, :d_scancode

    alias_method :section_sign, :section
    alias_method :equal_sign, :equal
    alias_method :dollar_sign, :dollar
    alias_method :percent_sign, :percent
    alias_method :circumflex, :caret
    alias_method :less_than_sign, :less_than
    alias_method :greater_than_sign, :greater_than
    alias_method :left_shift, :shift_left
    alias_method :right_shift, :shift_right
    alias_method :section_sign=, :section=
    alias_method :equal_sign=, :equal=
    alias_method :dollar_sign=, :dollar=
    alias_method :percent_sign=, :percent=
    alias_method :circumflex=, :caret=
    alias_method :less_than_sign=, :less_than=
    alias_method :greater_than_sign=, :greater_than=
    alias_method :left_shift=, :shift_left=
    alias_method :right_shift=, :shift_right=

    alias_method :option, :alt
    alias_method :option_left, :alt_left
    alias_method :option_right, :alt_right
    alias_method :left_alt, :alt_left
    alias_method :right_alt, :alt_right
    alias_method :left_option, :alt_left
    alias_method :right_option, :alt_right
    alias_method :option=, :alt=
    alias_method :option_left=, :alt_left=
    alias_method :option_right=, :alt_right=
    alias_method :left_alt=, :alt_left=
    alias_method :right_alt=, :alt_right=
    alias_method :left_option=, :alt_left=
    alias_method :right_option=, :alt_right=

    alias_method :command, :meta
    alias_method :command_left, :meta_left
    alias_method :command_right, :meta_right
    alias_method :left_meta, :meta_left
    alias_method :right_meta, :meta_right
    alias_method :left_command, :meta_left
    alias_method :right_command, :meta_right
    alias_method :command=, :meta=
    alias_method :command_left=, :meta_left=
    alias_method :command_right=, :meta_right=
    alias_method :left_meta=, :meta_left=
    alias_method :right_meta=, :meta_right=
    alias_method :left_command=, :meta_left=
    alias_method :right_command=, :meta_right=

    alias_method :ctrl, :control
    alias_method :left_control, :control_left
    alias_method :right_control, :control_right
    alias_method :left_ctrl, :control_left
    alias_method :right_ctrl, :control_right
    alias_method :ctrl=, :control=
    alias_method :left_control=, :control_left=
    alias_method :right_control=, :control_right=
    alias_method :left_ctrl=, :control_left=
    alias_method :right_ctrl=, :control_right=

    alias_method :minus, :hyphen
    alias_method :dash, :hyphen
    alias_method :pageup, :page_up
    alias_method :pagedown, :page_down
    alias_method :backslash, :back_slash
    alias_method :forwardslash, :forward_slash
    alias_method :capslock, :caps_lock
    alias_method :scrolllock, :scroll_lock
    alias_method :numlock, :num_lock
    alias_method :printscreen, :print_screen
    alias_method :break, :pause
    alias_method :minus=, :hyphen=
    alias_method :dash=, :hyphen=
    alias_method :pageup=, :page_up=
    alias_method :pagedown=, :page_down=
    alias_method :backslash=, :back_slash=
    alias_method :forwardslash=, :forward_slash=
    alias_method :capslock=, :caps_lock=
    alias_method :scrolllock=, :scroll_lock=
    alias_method :numlock=, :num_lock=
    alias_method :printscreen=, :print_screen=
    alias_method :break=, :pause=

    alias_method :left, :left_arrow
    alias_method :right, :right_arrow
    alias_method :up, :up_arrow
    alias_method :down, :down_arrow
    alias_method :left=, :left_arrow=
    alias_method :right=, :right_arrow=
    alias_method :up=, :up_arrow=
    alias_method :down=, :down_arrow=
  end
end
