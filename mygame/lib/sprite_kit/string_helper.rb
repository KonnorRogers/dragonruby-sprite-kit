module StringHelper
  ELLIPSIS = "...".freeze

  def self.truncate(text, size_enum: nil, size_px: nil, font: nil, max_width: nil)
    if !max_width
      return text
    end

    cur_width, = GTK.calcstringbox(text, size_px: size_px, size_enum: size_enum, font: font)

    if cur_width <= max_width
      return text
    end

    (text.length - 1).downto 0 do |i|
      truncated = "#{text[0..i]}#{ELLIPSIS}"
      cur_width, = GTK.calcstringbox(truncated, size_px: size_px, size_enum: size_enum, font: font)
      return truncated if cur_width <= max_width
    end

    ""
  end
end
