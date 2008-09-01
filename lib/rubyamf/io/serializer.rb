require 'date'
require 'constants'
require 'io/stream'

module RubyAMF
  module Serializer
    include RubyAMF::Constants
    
    def output_stream
      @output_stream ||= Stream.new
    end
    
    def write value
      @integer_cache      ||= {}
      @floats_cache       ||= {}
      
      @string_counter     ||= -1
      @string_references  ||= {}
      value.write_amf self
    end
    
    def write_null
      output_stream << NULL_MARKER
    end
    
    def write_false
      output_stream << FALSE_MARKER
    end
    
    def write_true
      output_stream << TRUE_MARKER
    end
    
    # integers can be 29 bits wide in the AMF spec
    def write_number number
      if number >= MIN_INTEGER && number <= MAX_INTEGER #check valid range for 29 bits
        write_integer number
      else #overflow to a double
        write_double number 
      end
    end

    def write_integer number
      output_stream << INTEGER_MARKER << ( @integer_cache[number] ||= pack_int(number) )
    end
      
    def write_double double, include_marker=true
      output_stream << DOUBLE_MARKER if include_marker
      output_stream << ( @floats_cache[double] ||= [double].pack('G') )
    end
    
    def write_string string
      reference = reference_string(string) || string
      output_stream << STRING_MARKER << reference
    end
    
    def write_date datetime
      output_stream << DATE_MARKER << LOW_BIT_OF_1
      
      seconds = if datetime.is_a?(Time)
        datetime.utc unless datetime.utc?
        datetime.to_f
      elsif datetime.is_a?(Date) # this also handles the case for DateTime
        ((datetime.strftime("%s").to_i) * 1000).to_i
      end
      
      write_double seconds, false
    end
    
    def write_object obj
      output_stream << OBJECT_MARKER
      # Dynamic, Anonymous Object - very simple heuristics
      if obj.is_a? Hash
        output_stream << DYNAMIC_OBJECT << ANONYMOUS_OBJECT
        obj.each do |key, value|
          key.write_amf self # easy for both string and symbol keys
          value.write_amf self
        end
      else # unmapped object
        output_stream << DYNAMIC_OBJECT << ANONYMOUS_OBJECT
        # find all public methods belonging to this object alone
        obj.public_methods(false).each do |method_name|
          # and write them to the stream if they take no arguments
          method_def = obj.method(method_name)
          if method_def.arity == 0
            write_string method_name
            obj.send(method_name).write_amf self
          end
        end
      end
      output_stream << CLOSE_OBJECT
    end
    
    def write_array array
      output_stream << ARRAY_MARKER << LOW_BIT_OF_1
      output_stream << pack_int(array.size)
      # RubyAMF only encodes strict, dense arrays by the AMF spec
      # so the dynamic portion is empty
      output_stream << CLOSE_DYNAMIC_ARRAY
      array.each do |val|
        val.write_amf self
      end
      
    end
    
    def pack_int number
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
    
  protected
    
    def reference_string str
      return @string_references[str] if @string_references[str]
      
      @string_counter += 1
      @string_references[str] = pack_int( @string_counter )
      return nil
    end
    
  end
end
