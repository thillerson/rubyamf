module AMF
  # Standard Types Markers
  UNDEFINED_MARKER      = "\000" #0x00
  NULL_MARKER           = "\001" #0x01
  FALSE_MARKER          = "\002" #0x02
  TRUE_MARKER           = "\003" #0x03
  INTEGER_MARKER        = "\004" #0x04
  DOUBLE_MARKER         = "\005" #0x05
  STRING_MARKER         = "\006" #0x06
  XML_DOC_MARKER        = "\a" #0x07
  DATE_MARKER           = "\b" #0x08
  ARRAY_MARKER          = "\t" #0x09
  OBJECT_MARKER         = "\n" #0x0A
  XML_MARKER            = "\v" #0x0B
  BYTE_ARRAY_MARKER     = "\f" #0x0C
  
  AMF3_TYPE = 0x11
  AMF3_UNDEFINED = 0x00
  AMF3_NULL = 0x01
  AMF3_FALSE = 0x02
  AMF3_TRUE = 0x03
  AMF3_INTEGER = 0x04
  AMF3_NUMBER = 0x05
  AMF3_STRING = 0x06
  AMF3_XML = 0x07
  AMF3_DATE = 0x08
  AMF3_ARRAY = 0x09
  AMF3_OBJECT = 0x0A
  AMF3_XML_STRING = 0x0B
  AMF3_BYTE_ARRAY = 0x0C
  
  # Other Markers, some reused
  EMPTY_STRING          = NULL_MARKER
  ONE                   = NULL_MARKER
  ANONYMOUS_OBJECT      = NULL_MARKER
  DYNAMIC_OBJECT        = XML_MARKER
  CLOSE_DYNAMIC_OBJECT  = NULL_MARKER
  CLOSE_DYNAMIC_ARRAY   = NULL_MARKER

  MAX_INTEGER           = 268435455
  MIN_INTEGER           = -268435456
end