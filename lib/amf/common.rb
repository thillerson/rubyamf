require 'amf/version'

module AMF
  class << self
    # Returns the AMF deserializer class, that is used by AMF. This might be either
    # AMF::Ext::Deserializer or AMF::Pure::Deserializer.
    attr_reader :deserializer

    # Set the AMF deserializer class _deserializer_ to be used by AMF.
    def deserializer=(deserializer) # :nodoc:
      @deserializer = deserializer
      remove_const :Deserializer if const_defined? :Deserializer
      const_set :Deserializer, deserializer
    end
    
    # Deserialize the AMF string _source_ into a Ruby data structure and return it.
    def deserialize(source, opts = {})
      AMF.deserializer.new(source, opts).deserialize
    end
    
    # Returns the AMF serializer modul, that is used by AMF. This might be
    # either AMF::Ext::Serializer or AMF::Pure::Serializer.
    attr_reader :serializer

    # Set the AMF serializer class _serializer_ to be used by AMF.
    def serializer=(serializer) # :nodoc:
      @serializer = serializer
      serializer_methods = serializer::SerializerMethods
      for const in serializer_methods.constants
        klass = deep_const_get(const)
        modul = serializer_methods.const_get(const)
        klass.class_eval do
          instance_methods(false).each do |m|
            m.to_s == 'to_amf' and remove_method m
          end
          include modul
        end
      end
      self.state = serializer::State
      const_set :State, self.state
    end
    
    # Serialize the Ruby data structure _obj_ into a single line AMF
    def serialize(obj, state = nil)
      if state
        state = State.from_state(state)
      else
        state = State.new
      end
      obj.to_amf(state)
    end
    
    # Return the constant located at _path_. The format of _path_ has to be
    # either ::A::B::C or A::B::C. In any case A has to be located at the top
    # level (absolute namespace path?). If there doesn't exist a constant at
    # the given path, an ArgumentError is raised.
    def deep_const_get(path) # :nodoc:
      path = path.to_s
      path.split(/::/).inject(Object) do |p, c|
        case
        when c.empty?             then p
        when p.const_defined?(c)  then p.const_get(c)
        else                      raise ArgumentError, "can't find const #{path}"
        end
      end
    end

    # Returns the JSON generator state class, that is used by JSON. This might
    # be either JSON::Ext::Generator::State or JSON::Pure::Generator::State.
    attr_accessor :state
    
    # This is create identifier, that is used to decide, if the _amf_create_
    # hook of a class should be called. It defaults to 'amf_class'.
    attr_accessor :create_id
  end
  
  self.create_id = 'amf_class'

  # The base exception for AMF errors.
  class AMFError < StandardError; end
end

class ::Class
  # Returns true, if this class can be used to create an instance
  # from a serialized AMF string. The class has to implement a class
  # method _amf_create_ that expects a hash as first parameter, which includes
  # the required data.
  def amf_creatable?
    respond_to?(:amf_create)
  end
end
