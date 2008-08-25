def expected_double_value_for num
  [num].pack 'G'
end

class NonMappedObject
  attr_accessor :property_one
  attr_accessor :property_two
  attr_writer :read_only_prop
  
  def another_public_property
    'foo'
  end
  
  def method_with_arg arg='foo'
    
  end
end

