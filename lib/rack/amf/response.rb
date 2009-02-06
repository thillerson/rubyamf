require 'set'
require 'rack/amf/headers'

module Rack::AMF
  class Response < Rack::Request
    include Rack::AMF::ResponseHeaders

  end
end