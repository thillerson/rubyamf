require 'bindata'

module AMF
  module Pure
    class Deserializer
      
      class MetaString < BinData::SingleValue        
        uint16be :len,  :value => lambda { stream.length }
        string :stream, :read_length => :len
        
        def get
          self.stream
        end

        def set(value)
          self.stream = value
        end
      end
      
      class DataString < BinData::MultiValue
        uint32be :len,  :value => lambda { stream.length }
        int8  :stream_type
        string :stream, :read_length => :len
      end
      
      class Header < BinData::MultiValue
        meta_string :name
        int8        :required
        data_string :data
      end
      
      class Body < BinData::MultiValue
        meta_string :target
        meta_string :response
        data_string :data 
      end
      
      class Request < BinData::MultiValue
        int8 :amf_version
        int8 :client_version
        uint16be :header_count
        array :headers, :type => :header, :initial_length => :header_count
        uint16be :body_count
        array :bodies, :type => :body, :initial_length => :body_count
      end

      def initialize(source, opts = {})
          #request = Request.new()
          #request.read(source)
          #request.headers.each do |header|
          #  name = header.name
          #  requires = header.required
          #  stream_type = header.data.stream_type
          #  stream = header.data.stream
          #  value = deserialize(stream, stream_type)
          #  store header 
          #end
          #request.bodies.each do |body|
          #  target = body.target
          #  response = body.response
          #  type = body.data.stream_type
          #  stream = body.data.stream
          #  value = deserialize(stream, stream_type)
          #  store body
          #end        
      end
      
      def deserialize(source)
          read source 
      end  
     
      def read(source, type = nil)
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
            #read_integer source
            #read_amf3_integer
          when DOUBLE_MARKER
            #read_number #read standard AMF0 number, a double
          when STRING_MARKER 
            #read_amf3_string
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
        d = source[0,1].unpack('c').first
        source = source[1,source.length - 1]
        d
      end
    end
  end
end
