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
          
          @string_cache = {}
          @object_cache = {}
          @trait_cache  = {}
      end  
      
      def cache_string str
        @string_cache[@string_cache.length] = str
      end
      
      def cache_object obj
        @object_cache[@object_cache.length] = obj       
      end
      
      def cache_trait tra
        @trait_cache[@trait_cache.length] = tra
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
        source = BinData::IO.new(source) unless source.instance_of?(BinData::IO)
        type = read_int8 source unless type
        
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
            #read_xml_string
          when DATE_MARKER
            read_date source
          when ARRAY_MARKER
            read_array source
          when OBJECT_MARKER
            read_object source
          when XML_MARKER
            #read_amf3_xml
          when BYTE_ARRAY_MARKER
            #read_amf3_byte_array
        end
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
      
      #DOUBLE_MARKER
      def read_number source
        res = read_double source
        res.is_a?(Float)&&res.nan? ? nil : res # check for NaN and convert them to nil
      end
      
      #STRING_MARKER
      def read_string source
        type = read_integer source
        isReference = (type & 0x01) == 0
        
        if isReference
          reference = type >> 1
          return @string_cache[reference]
        else
          length = type >> 1
          #HACK needed for ['',''] array of empty strings
          #It may be better to take one more parameter that 
          #would specify whether or not they expect us to return
          #a string
          str = "" #if stringRequest
          if length > 0
            str = readn(source, length)
            cache_string(str)
          end
          return str
        end
      end
      
      #XML_DOC_MARKER
      
      #ARRAY_MARKER
      def read_array source
        type = read_integer source
        isReference = (type & 0x01) == 0
        
        if isReference
          reference = type >> 1
          return @object_cache[reference]
        else
          length = type >> 1
          propertyName = read_string source
          if propertyName != ""
            array = {}
            cache_object(array)
            begin
              while(propertyName.length)
                value = deserialize(source)
                array[propertyName] = value
                propertyName = read_string source
              end
            rescue Exception => e #end of object exception, because propertyName.length will be non existent
            end
            0.upto(length - 1) do |i|
              array["" + i.to_s] = deserialize(source)
            end
          else
            array = []
            cache_object(array)
            0.upto(length - 1) do
              array << deserialize(source)
            end
          end
          array
        end
      end
      
      #OBJECT_MARKER
     def read_object source
        type = read_integer source
        isReference = (type & 0x01) == 0
        
        if isReference
          reference = type >> 1
          return @object_cache[reference]
        else
          class_type = type >> 1
          class_is_reference = (class_type & 0x01) == 0
          
          if class_is_reference
            reference = class_type >> 1
            class_definition = @trait_cache[reference]
          else
            actionscript_class_name = read_string source
            externalizable = (class_type & 0x02) != 0
            dynamic = (class_type & 0x04) != 0
            attribute_count = class_type >> 3
            
            class_attributes = []
            attribute_count.times{class_attributes << read_string(source)} # Read class members
            
            class_definition = {"as_class_name" => actionscript_class_name, 
                                "members" => class_attributes, 
                                "externalizable" => externalizable, 
                                "dynamic" => dynamic}
            cache_trait(class_definition)
          end
          action_class_name = class_definition['as_class_name'] #get the className according to type

          obj = Hash.new()
            
          cache_object(obj)
          
          if class_definition['externalizable']
            if ['flex.messaging.io.ObjectProxy','flex.messaging.io.ArrayCollection'].include?(action_class_name)
              obj = deserialize(source)
            end         
          else            
            class_definition['members'].each do |key|
              value = deserialize(source)
              obj[key] = value
            end
            
            if class_definition['dynamic']
              while (key = read_string source) && key.length != 0  do # read next key
                value = deserialize(source)
                obj[key] = value
              end
            end
          end
          obj
        end
      end
      
      #DATE MARKER
      def read_date source
        type = read_integer source
        isReference = (type & 0x01) == 0
        if isReference
          reference = type >> 1
          return @object_cache[reference]
        else
          seconds = read_double(source).to_f/1000
          time = if (seconds < 0) # we can't use Time if its a negative second value
            DateTime.strptime(seconds.to_s, "%s")
          else 
            #Time.at(seconds)
            Time.at(seconds).utc
          end
          cache_object(time)
          time
        end
      end
      
      #IO HELPERS
      
      def read_int8 source
        source.readbytes(1).unpack('c').first
      end
      
      def read_word8 source
        source.readbytes(1).unpack('C').first
      end
      
      def read_double source
        source.readbytes(8).unpack('G').first
      end
      
      def readn(source, length)
        source.readbytes(length)
      end
      
    end
  end
end
