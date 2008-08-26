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

class NonMappedObject
  attr_accessor :property_one
  attr_accessor :property_two
  attr_accessor :nil_property
  attr_writer :read_only_prop
  
  def another_public_property
    'foo'
  end
  
  def method_with_arg arg='foo'
    arg
  end
end

