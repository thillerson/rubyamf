require 'fileutils'
require 'time'
require 'rack'
require 'amf'

module Rack
  class AMF  
    require 'rack/amf/request'
    require 'rack/amf/response'
    require 'rack/amf/context'
    
    def self.new(backend, options={}, &b)
      Context.new(backend, options, &b)
    end
  
#    ##################################
#    # CONSTANTS
#    ##################################
#    APPLICATION_AMF = 'application/x-amf'.freeze 
#      
#    def initialize app
#      @app = app
#    end
#   
#    def call env
#      ##################################
#      # REQUEST
#      ##################################
#      @original_request = Request.new(env.dup.freeze)
#      @request = Request.new(env)

#      case @request.content_type
#      when APPLICATION_AMF
#        @request.body = ::AMF.deserialize @request.body
#      end
#      
#      status, headers, body = @app.call(request.env)
#      
#      response = Response.new(status, headers, body)
#      @response = response.dup
#      @original_response = response.freeze
#      
#      case @response.content_type
#      when APPLICATION_AMF
#        @response.body = ::AMF.serialize @response.body
#      end
#      
#      @response.to_a
#    end
  end
end