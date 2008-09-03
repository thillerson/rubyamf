def expected_double_value_for num
  [num].pack 'G'
end

def expected_int_value_for number
  number = number & 0x1fffffff
  if(number < 0x80)
    [number].pack('c')
  elsif(number < 0x4000)
    [number >> 7 & 0x7f | 0x80].pack('c')+
      [number & 0x7f].pack('c')
  elsif(number < 0x200000)
    [number >> 14 & 0x7f | 0x80].pack('c')+
      [number >> 7 & 0x7f | 0x80].pack('c')+
      [number & 0x7f].pack('c')
  else
    [number >> 22 & 0x7f | 0x80].pack('c')+
      [number >> 15 & 0x7f | 0x80].pack('c')+
      [number >> 8 & 0x7f | 0x80].pack('c')+
      [number & 0xff].pack('c')
  end
  number
end

def expected_encoded_header_for obj_with_length
  header = obj_with_length.length
  header = header << 1
  header = header | 1
  expected_int_value_for header
end

# expects no references
def expected_encoded_string_for str
  "#{ENCODED_STRING_MARKER}" << expected_encoded_header_for( str ) << str
end

def expected_encoded_string_reference reference
  "#{ENCODED_STRING_MARKER}" << ( reference << 1 )
end

def expected_encoded_object_reference reference
  "" << ( reference << 1 )
end

