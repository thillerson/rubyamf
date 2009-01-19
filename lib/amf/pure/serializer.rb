require 'pure/serializer_helper'
require 'date'
require 'bigdecimal'
require 'rexml/document'

module AMF  
  module Pure
    module Serializer
      class State
        def self.from_state(opts)
          case opts
          when self
            opts
          when Hash
            new(opts)
          else
            new
          end
        end

        def initialize(opts = {})
          @integer_cache  ||= {}
          @float_cache    ||= {}
          @string_counter ||= -1
          @string_cache   ||= {}
          @object_counter ||= -1
          @object_cache   ||= {}
          configure opts
        end
       
        attr_accessor :integer_cache
        attr_accessor :floats_cache
        attr_accessor :string_counter
        attr_accessor :string_cache
        attr_accessor :object_counter
        attr_accessor :object_cache

        def configure(opts)
          @integer_cache = opts[:integer_cache] if opts.key?(:integer_cache)
          @float_cache = opts[:float_cache] if opts.key?(:float_cache)
          @string_counter = opts[:string_counter] if opts.key?(:string_counter)
          @string_cache = opts[:string_cache] if opts.key?(:string_cache)
          @object_counter = opts[:object_counter] if opts.key?(:object_counter)
          @object_cache = opts[:object_cache] if opts.key?(:object_cache)
          self
        end

        def to_h
          result = {}
          for iv in %w[integer_cache float_cache string_counter string_cache object_counter object_cache]
            result[iv.intern] = instance_variable_get("@#{iv}")
          end
          result
        end
      end
                  
      module SerializerMethods 
        module NilClass
          def to_amf(*)
            AMF.write_null
          end
        end
        
        module FalseClass
          def to_amf(*)
            AMF.write_false
          end
        end
        
        module TrueClass
          def to_amf(*)
            AMF.write_true
          end
        end
        
        module Bignum
          def to_amf(*)
            #AMF.write_double self
            self.to_f.to_amf
          end
        end
        
        module Integer
          def to_amf(*)
            AMF.write_number self
          end
        end
        
        module Float
          def to_amf(*)
            AMF.write_double self
          end
        end
        
        module BigDecimal
          def to_amf(*)
            #AMF.write_double self
            self.to_f.to_amf
          end
        end
        
        module String
          def to_amf(*)
            AMF.write_string self
          end
        end
        
        module Symbol
          def to_amf(*)
            self.to_s.to_amf
          end
        end
        
        module Array
          def to_amf(*)
            AMF.write_array self
          end
        end
        
        module Hash
          def to_amf(*)
            AMF.write_object self
          end
        end
        
        module Time
          def to_amf(*)
            AMF.write_date self
          end
        end
        
        module Date
          def to_amf(*)
            AMF.write_date self
          end
        end
        
        module Object
          def to_amf(*)
            AMF.write_object self
          end
        end
        
        module REXML
          class Document
            def to_amf(*)
              AMF.write_xml self
            end
          end
        end
        
      end 
    end
  end
end