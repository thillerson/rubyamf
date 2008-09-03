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
      
      @object_counter     ||= -1
      @object_references  ||= {}
      
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
      output_stream << STRING_MARKER
      output_stream << EMPTY_STRING and return if string == ''
      if index = reference_string(string)
        output_stream << header_for_reference( index )
      else
        output_stream << header_for_string( string ) << string
      end
    end
    
    def write_date datetime
      output_stream << DATE_MARKER
      
      seconds = if datetime.is_a?(Time)
        datetime.utc unless datetime.utc?
        datetime.to_f
      elsif datetime.is_a?(Date) # this also handles the case of a DateTime
        ((datetime.strftime("%s").to_i) * 1000).to_i
      end
      
      if index = reference_object(seconds)
        output_stream << header_for_reference(index)
      else
        output_stream << ONE
        write_double seconds, false
      end
      
    end
    
    def write_object obj
      output_stream << OBJECT_MARKER
      
      if index = reference_object( obj )
        output_stream << header_for_reference(index) and return
      end
      
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
            method_name.write_amf self
            obj.send(method_name).write_amf self
          end
        end
      end
      output_stream << CLOSE_DYNAMIC_OBJECT
    end
    
    def write_array array
      output_stream << ARRAY_MARKER

      if index = reference_object( array )
        output_stream << header_for_reference(index) and return
      end
      
      output_stream << header_for_array( array )
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
    
    # expects argument to be a non-empty string for which
    # there is no reference.
    # see 1.3.2 and 3.8 in the published AMF spec
    # header is a low bit of 1 with the length occupying
    # the remaining bits
    def header_for_string string
      header = string.length << 1 # make room for a low bit of 1
      header = header | 1 # set the low bit to 1
      pack_int header
    end
    
    # header is a low bit of 1 with the length occupying
    # the remaining bits
    def header_for_array array
      header = array.length << 1 # make room for a low bit of 1
      header = header | 1 # set the low bit to 1
      pack_int header
    end
    
    # references have a low bit of 0 with the remaining
    # bits being the reference
    def header_for_reference index
      header = index << 1 # shift value left to leave a low bit of 0
      pack_int header
    end
    
  protected
  
   def reference_string str
     return @string_references[str] if @string_references[str]
     
     @string_references[str] = @string_counter += 1
     return nil
   end
   
   def reference_object obj
     return @object_references[obj] if @object_references[obj]
     
     @object_references[obj] = @object_counter += 1
     return nil
   end
  
  end
end
