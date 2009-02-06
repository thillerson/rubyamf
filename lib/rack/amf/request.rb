require 'rack/request'
require 'rack/amf/headers'
 
module Rack::AMF
  class Request < Rack::Request
    include Rack::AMF::RequestHeaders

  end
end