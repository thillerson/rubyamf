require 'fileutils'
require 'time'
require 'rack'
require 'amf'

module Rack
end

module Rack::AMF
  require 'rack/amf/request'
  require 'rack/amf/response'
  require 'rack/amf/context'
  
#  ##################################
#  # CONSTANTS
#  ##################################
#  APPLICATION_AMF = 'application/x-amf'.freeze 
#
#  POST_BODY = 'rack.input'.freeze
#  FORM_INPUT = 'rack.request.form_input'.freeze
#  FORM_HASH = 'rack.request.form_hash'.freeze
#    
#  def initialize app
#    @app = app
#  end
# 
#  def call env
#    ##################################
#    # REQUEST
#    ##################################
#    case env['CONTENT_TYPE']
#    when APPLICATION_AMF
#      env.update(FORM_HASH => ::AMF.deserialize(env[POST_BODY].read), FORM_INPUT => env[POST_BODY])
#    end
#    
#    @status, @headers, @body = @app.call(env)				
#    
#    ##################################
#    # RESPONSE
#    ##################################
#    case @headers['Content-Type']
#    when APPLICATION_AMF
#      @body = ::AMF.serialize @body
#    end
#    
#    [@status, @headers, @body]
#  end
  
  def self.new(backend, options={}, &b)
    Context.new(backend, options, &b)
  end
end