require 'amf/common'

module AMF
  # This module holds all the modules/classes that implement AMF's
  # functionality as C extensions.
  module Ext
    require 'amf/ext/deserializer'
    require 'amf/ext/serializer'
    $DEBUG and warn "Using c extension for AMF."
    AMF.deserializer = Deserializer
    AMF.serializer = Serializer
  end
end
