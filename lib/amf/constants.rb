module AMF
  # Standard Types Markers
  UNDEFINED_MARKER      =  0x00 #"\000"
  NULL_MARKER           =  0x01 #"\001"
  FALSE_MARKER          =  0x02 #"\002"
  TRUE_MARKER           =  0x03 #"\003" 
  INTEGER_MARKER        =  0x04 #"\004" 
  DOUBLE_MARKER         =  0x05 #"\005" 
  STRING_MARKER         =  0x06 #"\006"
  XML_DOC_MARKER        =  0x07 #"\a" 
  DATE_MARKER           =  0x08 #"\b" 
  ARRAY_MARKER          =  0x09 #"\t" 
  OBJECT_MARKER         =  0x0A #"\n" 
  XML_MARKER            =  0x0B #"\v" 
  BYTE_ARRAY_MARKER     =  0x0C #"\f" 
  
  # Other Markers, some reused
  EMPTY_STRING          = NULL_MARKER
  ANONYMOUS_OBJECT      = NULL_MARKER
  DYNAMIC_OBJECT        = XML_MARKER
  CLOSE_DYNAMIC_OBJECT  = NULL_MARKER
  CLOSE_DYNAMIC_ARRAY   = NULL_MARKER

  MAX_INTEGER           = 268435455
  MIN_INTEGER           = -268435456
end