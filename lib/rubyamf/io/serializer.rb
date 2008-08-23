require 'constants'
module RubyAMF
  module Serializer
    include RubyAMF::Constants
    
    attr_accessor :output_stream
    
    def write value
      @output_stream ||= ''
      
      @integer_cache  = {}
      @floats_cache   = {}
      
      value.write_amf self
    end
    
    def write_null
      output_stream << NULL
    end
    
    def write_false
      output_stream << FALSE
    end
    
    def write_true
      output_stream << TRUE
    end
    
    # integers can be 29 bits wide in the AMF spec
    def write_number number
      if number >= INTEGER_MIN && number <= INTEGER_MAX #check valid range for 29 bits
        write_integer number
      else #overflow to a double
        write_double number 
      end
    end

    def write_integer number
      output_stream << INTEGER << ( @integer_cache[number] ||= pack_int(number) )
    end
      
    def write_double double
      output_stream << NUMBER << ( @floats_cache[double] ||= [double].pack('G') )
    end
    
    def write_string string
      output_stream << STRING << string
    end
    
    def write_date datetime
      seconds = if datetime.is_a?(Time)
        datetime.utc unless datetime.utc?
        datetime.to_f
      elsif datetime.is_a?(Date) # this also handles the case for DateTime
        datetime.strftime("%s").to_i
      end
      write_double( (seconds*1000).to_i )
    end
    
    #Here we have some High Magic
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
    
  end
end
