require 'set'
 
module Rack::AMF
  # Generic HTTP header helper methods. Provides access to headers that can be
  # included in requests and responses. This can be mixed into any object that
  # responds to #headers by returning a Hash.
  
  module Headers    
    APPLICATION_AMF = 'application/x-amf'.freeze
    
    def amf_content?
      headers['CONTENT_TYPE'] == APPLICATION_AMF
    end
  end
 
  module RequestHeaders
    include Rack::AMF::Headers
  end
 
  module ResponseHeaders
    include Rack::AMF::Headers
  end
 
end