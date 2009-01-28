require 'set'
require 'rack/amf/headers'

module Rack::AMF
  class Response
    include Rack::Response::Helpers
    include Rack::AMF::ResponseHeaders
 
    # The response's status code (integer).
    attr_accessor :status
 
    # The response body. See the Rack spec for information on the behavior
    # required by this object.
    attr_accessor :body
 
    # The response headers.
    attr_reader :headers
 
    # Create a Response instance given the response status code, header hash,
    # and body.
    def initialize(status, headers, body)
      @status = status
      @headers = Rack::Utils::HeaderHash.new(headers)
      @body = body
      @now = Time.now
      @headers['Date'] ||= now.httpdate
    end
 
    def initialize_copy(other)
      super
      @headers = other.headers.dup
    end
    
    # Return the value of the named response header.
    def [](header_name)
      headers[header_name]
    end
 
    # Set a response header value.
    def []=(header_name, header_value)
      headers[header_name] = header_value
    end

    # Return the status, headers, and body in a three-tuple.
    def to_a
      [status, headers.to_hash, body]
    end
    
    # Freezes
    def freeze
      @headers.freeze
      super
    end
  end
end