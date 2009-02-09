require 'bindata'

module AMF
  module Pure    
    class MetaString < BinData::SingleValue
      uint16be :len, :value => lambda { stream.length }
      string :stream, :read_length => :len
        
      def get
        self.stream
      end
 
      def set(value)
        self.stream = value
      end
    end
    
    class DataString < BinData::MultiValue
      uint32be :len, :value => lambda { stream.length }
      int8 :stream_type
      string :stream, :read_length => :len
    end
    
    class Header < BinData::MultiValue
      meta_string :name
      int8 :required
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
  end
end