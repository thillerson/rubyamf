require 'bindata'

module AMF
  module Pure
    class Deserializer
      attr_accessor :dynamic,
              :string_counter,
              :string_cache,
              :object_counter,
              :object_cache,
              :trait_counter,
              :trait_cache

      def initialize()
          @dynamic = false
          
          @string_counter ||= 0
          @string_cache   ||= {}
          @object_counter ||= 0
          @object_cache   ||= {}
          @trait_counter ||= 0
          @trait_cache   ||= {}
      end  
      
      def cache_string str
        @string_cache[@string_counter] = str
        @string_counter += 1
      end
      
      def cache_object obj
        
      end
      
      def cache_trait tra
        
      end
      def deserialize_request()
          #request = Request.new()
          #request.read(source)
          #request.headers.each do |header|
          #  name = header.name
          #  requires = header.required
          #  stream_type = header.data.stream_type
          #  stream = header.data.stream
          #  value = deserialize(stream, stream_type)
          ###  store header 
          #end
          #request.bodies.each do |body|
          #  target = body.target
          #  response = body.response
          #  type = body.data.stream_type
          #  stream = body.data.stream
          #  value = deserialize(stream, stream_type)
          ###  store body
          #end         
      end

      def deserialize(source, type=nil)
        if(type == nil)
          source = BinData::IO.new(source)
          type = read_int8 source
        end
        
        case type
          when UNDEFINED_MARKER
            nil
          when NULL_MARKER
            nil
          when FALSE_MARKER
            false
          when TRUE_MARKER
            true
          when INTEGER_MARKER
            read_integer source
          when DOUBLE_MARKER
            read_number source
          when STRING_MARKER 
            read_string source
          when XML_DOC_MARKER
            #read_amf3_xml_string
          when DATE_MARKER
            #read_amf3_date
          when ARRAY_MARKER
            #read_amf3_array
          when OBJECT_MARKER
            #read_amf3_object
          when XML_MARKER
            #read_amf3_xml
          when BYTE_ARRAY_MARKER
            #read_amf3_byte_array
        end
      end  
      
      def read_int8 source
        source.readbytes(1).unpack('c').first
      end
      
      #INTEGER_MARKER
           
      def read_integer source
        n = 0
        b = read_word8(source) || 0
        result = 0
        
        while ((b & 0x80) != 0 && n < 3)
          result = result << 7
          result = result | (b & 0x7f)
          b = read_word8(source) || 0
          n = n + 1
        end
        
        if (n < 3)
          result = result << 7
          result = result | b
        else
          #Use all 8 bits from the 4th byte
          result = result << 8
          result = result | b
      
          #Check if the integer should be negative
          if (result > MAX_INTEGER)
            result -= (1 << 29)
          end
        end
        result
      end
      
      def read_word8 source
        source.readbytes(1).unpack('C').first
      end
      
      #DOUBLE_MARKER
      
      def read_number source
        res = read_double source
        res.is_a?(Float)&&res.nan? ? nil : res # check for NaN and convert them to nil
      end
      
      def read_double source
        source.readbytes(8).unpack('G').first
      end
      
    end
  end
end
