require 'rack/request'
require 'rack/amf/headers'
require 'rack/utils/environment_headers'
 
module Rack::AMF
  class Request < Rack::Request
    include Rack::AMF::Headers
    include Rack::AMF::RequestHeaders
 
  end
end