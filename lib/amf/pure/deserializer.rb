require 'bindata'

module AMF
  module Pure
    class Deserializer
      
      class MetaString < BinData::MultiValue        
        uint16be :len,  :value => lambda { data.length }
        string :data, :read_length => :len
      end
      
      class DataString < BinData::MultiValue
        uint32be :len,  :value => lambda { data.length }
        int8  :data_type
        string :data, :read_length => :len
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
          @request = Request.new()
          #@request.read(source)
      end 
      attr_accessor :request
    end
  end
end
