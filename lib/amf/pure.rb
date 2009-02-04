require 'amf/constants'
require 'amf/pure/deserializer'
require 'amf/pure/serializer'

module AMF
  # This module holds all the modules/classes that implement AMF's
  # functionality in pure ruby.
  module Pure
    $DEBUG and warn "Using pure library for AMF."
    AMF.deserializer = Deserializer
    AMF.serializer = Serializer
  end
end
