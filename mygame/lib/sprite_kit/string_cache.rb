module StringCache
  CACHE = {}

  def self.get(str, size_enum: nil, font: nil)
    size_enum_key = size_enum
    if !size_enum
      size_enum_key = :default
    end

    font_key = font
    if !font
      font_key = :default
    end

    size_enum_cache = CACHE[size_enum_key] ||= {}
    font_cache = size_enum_cache[font_key] ||= {}

    if !font_cache[str]
      font_cache[str] = GTK.calcstringbox(str, size_enum: size_enum, font: font)
    end

    font_cache[str]
  end
end
