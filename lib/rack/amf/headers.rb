require 'set'
require 'rack/utils/environment_headers'
 
module Rack::AMF
  # Generic HTTP header helper methods. Provides access to headers that can be
  # included in requests and responses. This can be mixed into any object that
  # responds to #headers by returning a Hash.
  
  module Headers
    
    APPLICATION_AMF = 'application/x-amf'.freeze
    
    # Determine if any of the header names exist:
    # if header?('Authorization', 'Cookie')
    # ...
    # end
    def header?(*names)
      names.any? { |name| headers.include?(name) }
    end
    
    def amf_content?
      headers['CONTENT_TYPE'] == APPLICATION_AMF
    end
  end
 
  # HTTP request header helpers. When included in Rack::AMF::Request, headers
  # may be accessed by their standard RFC 2616 names using the #headers Hash.
  module RequestHeaders
    include Rack::AMF::Headers
 
    # A Hash-like object providing access to HTTP request headers.
    def headers
      @headers ||= Rack::Utils::EnvironmentHeaders.new(env)
    end
  end
 
  # HTTP response header helper methods.
  module ResponseHeaders
    include Rack::AMF::Headers
 
  private
    def now
      @now ||= Time.now
    end
  end
 
end