module App
  # https://gist.github.com/KonnorRogers/87543aed86e0c2dd888b554b85e0583e
  # Reference: https://www.stat.auckland.ac.nz/~paul/Reports/GraphicsEngine/compositing/compositing.html
  # Porter-Duff "Compositing Digital Images" paper.
  # https://keithp.com/~keithp/porterduff/p253-porter.pdf
  # https://www.w3.org/TR/compositing-1/#porterduffcompositingoperators
  # 12 common methods of compositing as defined by Porter-Duff
  module Blendmodes
    # This is the default of DragonRuby (equivalent to blendmode_enum: 1)
    def self.src_over
      @src_over ||= Numeric.compose_blendmode(
        # RGB blending
        # src                           dst                       operator
        BLENDFACTOR_SRC_ALPHA, BLENDFACTOR_ONE_MINUS_SRC_ALPHA, BLENDOPERATION_ADD,
        # Alpha blending
        # src                           dst                       operator
        BLENDFACTOR_ONE,       BLENDFACTOR_ONE_MINUS_SRC_ALPHA, BLENDOPERATION_ADD
      )
    end

    def self.clear
      @clear ||= Numeric.compose_blendmode(
        BLENDFACTOR_ZERO, BLENDFACTOR_ZERO, BLENDOPERATION_ADD,
        BLENDFACTOR_ZERO, BLENDFACTOR_ZERO, BLENDOPERATION_ADD,
      )
    end

    def self.src_only
      @src_only ||= Numeric.compose_blendmode(
        BLENDFACTOR_SRC_ALPHA, BLENDFACTOR_ZERO, BLENDOPERATION_ADD,
        BLENDFACTOR_ONE,       BLENDFACTOR_ZERO, BLENDOPERATION_ADD
      )
    end

    # Wherever "src" overlaps "dst", render "src".
    def self.src_in_dst
      @src_in_dst ||= Numeric.compose_blendmode(
        BLENDFACTOR_DST_ALPHA, BLENDFACTOR_ZERO, BLENDOPERATION_ADD,
        BLENDFACTOR_DST_ALPHA, BLENDFACTOR_ZERO, BLENDOPERATION_ADD
      )
    end

    def self.src_out
      @src_out ||= Numeric.compose_blendmode(
        BLENDFACTOR_ONE_MINUS_DST_ALPHA, BLENDFACTOR_ZERO, BLENDOPERATION_ADD,
        BLENDFACTOR_ONE_MINUS_DST_ALPHA, BLENDFACTOR_ZERO, BLENDOPERATION_ADD
      )
    end

    def self.dst_only
      @dst_only ||= Numeric.compose_blendmode(
        BLENDFACTOR_ZERO, BLENDFACTOR_ONE, BLENDOPERATION_ADD,
        BLENDFACTOR_ZERO, BLENDFACTOR_ONE, BLENDOPERATION_ADD
      )
    end

    def self.src_atop
      @src_atop ||= Numeric.compose_blendmode(
        BLENDFACTOR_DST_ALPHA, BLENDFACTOR_ONE_MINUS_SRC_ALPHA, BLENDOPERATION_ADD,
        BLENDFACTOR_DST_ALPHA, BLENDFACTOR_ONE_MINUS_SRC_ALPHA, BLENDOPERATION_ADD
      )
    end

    def self.dst_over
      @dst_over ||= Numeric.compose_blendmode(
        BLENDFACTOR_ONE_MINUS_DST_ALPHA, BLENDFACTOR_ONE, BLENDOPERATION_ADD,
        BLENDFACTOR_ONE_MINUS_DST_ALPHA, BLENDFACTOR_ONE, BLENDOPERATION_ADD
      )
    end

    def self.dst_in_src
      @dst_in_src ||= Numeric.compose_blendmode(
        BLENDFACTOR_ZERO, BLENDFACTOR_SRC_ALPHA, BLENDOPERATION_ADD,
        BLENDFACTOR_ZERO, BLENDFACTOR_SRC_ALPHA, BLENDOPERATION_ADD
      )
    end

    def self.dst_out
      @dst_out ||= Numeric.compose_blendmode(
        BLENDFACTOR_ZERO, BLENDFACTOR_ONE_MINUS_SRC_ALPHA, BLENDOPERATION_ADD,
        BLENDFACTOR_ZERO, BLENDFACTOR_ONE_MINUS_SRC_ALPHA, BLENDOPERATION_ADD
      )
    end

    def self.hole_punch
      self.dst_out
    end

    def self.dst_atop
      @dst_atop ||= Numeric.compose_blendmode(
        BLENDFACTOR_ONE_MINUS_DST_ALPHA, BLENDFACTOR_SRC_ALPHA, BLENDOPERATION_ADD,
        BLENDFACTOR_ONE_MINUS_DST_ALPHA, BLENDFACTOR_SRC_ALPHA, BLENDOPERATION_ADD
      )
    end

    def self.xor
      @xor ||= Numeric.compose_blendmode(
        BLENDFACTOR_ONE_MINUS_DST_ALPHA, BLENDFACTOR_ONE_MINUS_SRC_ALPHA, BLENDOPERATION_ADD,
        BLENDFACTOR_ONE_MINUS_DST_ALPHA, BLENDFACTOR_ONE_MINUS_SRC_ALPHA, BLENDOPERATION_ADD
      )
    end
  end
end
