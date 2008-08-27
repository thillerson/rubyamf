module RubyAMF
  module Constants
  
    # Standard Types Markers
    UNDEFINED_MARKER    = 0x00
    NULL_MARKER         = 0x01
    FALSE_MARKER        = 0x02
    TRUE_MARKER         = 0x03
    INTEGER_MARKER      = 0x04
    DOUBLE_MARKER       = 0x05
    STRING_MARKER       = 0x06
    XML_DOC_MARKER      = 0x07
    DATE_MARKER         = 0x08
    ARRAY_MARKER        = 0x09
    OBJECT_MARKER       = 0x0A
    XML_MARKER          = 0x0B
    BYTE_ARRAY_MARKER   = 0x0C
    
    # Other Markers, some reused
    LOW_BIT_OF_1        = NULL_MARKER
    DYNAMIC_OBJECT      = XML_MARKER
    ANONYMOUS_OBJECT    = NULL_MARKER
    CLOSE_OBJECT        = NULL_MARKER
    CLOSE_DYNAMIC_ARRAY = NULL_MARKER

    MAX_INTEGER         = 268435455
    MIN_INTEGER         = -268435456
  
  end
end