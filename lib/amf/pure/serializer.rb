require 'constants'
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
          
          @object_method_cache ||= {}
          configure opts
        end
        attr_accessor :integer_cache, 
                      :float_cache,
                      :string_counter,
                      :string_cache,
                      :object_counter,
                      :object_cache,
                      :empty_array_cache
        
        # if string has been referenced, returns the index of the reference
        # in the implicit string reference tabel. If no reference is found
        # sets the reference to the next index in the implicit strings table
        # and returns nil
        def string_cache(str)
          index = @string_cache.fetch(str.amf_id) { |amf_id|
            @string_cache[amf_id] = @string_counter += 1
            nil
          }
          header_for_cache(index) if index
        end
        
        # if object has been referenced, returns the index of the reference
        # in the implicit object reference table. If no reference is found
        # sets the reference to the next index in the implicit objects table
        # and returns nil.
        # if the object is an empty array, we need to make sure that we
        # don't return a reference unless the object ids are the same,
        # since eql? returns true if the contents of the array are the same
        # and hash uses eql? to compare keys, which would give false positives
        # in all cases.
        def object_cache(obj)
          index = @object_cache.fetch(obj.amf_id) { |amf_id|
            @object_cache[amf_id] = @object_counter += 1
            nil
          }
          header_for_cache(index) if index
        end
        
        def header_for_cache(index)
          header = index << 1 # shift value left to leave a low bit of 0
          AMF.pack_integer(header, self)
        end
        
        # Configure this State instance with the Hash _opts_, and return
        # itself.
        def configure(opts)
          #@check_circular = !!opts[:check_circular] if opts.key?(:check_circular)
          self
        end
        
        # Returns the configuration instance variables as a hash, that can be
        # passed to the configure method.
        def to_h
          result = {}
          #for iv in %w[check_circular]
          for iv in %w[]
            result[iv.intern] = instance_variable_get("@#{iv}")
          end
          result
        end
      end
                  
      module SerializerMethods 
        module NilClass
          def to_amf(*)
            NULL_MARKER
          end
        end
        
        module FalseClass
          def to_amf(*)
            FALSE_MARKER
          end
        end
        
        module TrueClass
          def to_amf(*)
            TRUE_MARKER
          end
        end
        
        module Bignum
          def to_amf(state = nil, *)
            self.to_f.to_amf(state)
          end
        end
        
        module Integer
          def to_amf(state = nil, *)
            if self >= MIN_INTEGER && self <= MAX_INTEGER #check valid range for 29 bits
              write_integer(self, state)
            else #overflow to a double
              self.to_f.to_amf(state)
            end
          end
          
          private
          
          def write_integer(integer, state = nil)
            output = ''
            output << INTEGER_MARKER
            output << AMF.pack_integer(integer)
          end
        end
        
        module Float
          def to_amf(state = nil, *)
            output = ''
            output << DOUBLE_MARKER
            output << AMF.pack_double(self, state)
          end
        end
        
        module BigDecimal
          def to_amf(state = nil, *)
            self.to_f.to_amf(state)
          end
        end
        
        module String
          def to_amf(state = nil, *)
            output = ''
            output << STRING_MARKER
            if self == ''
              output << EMPTY_STRING
            elsif state && (cache_header = state.string_cache(self))
              output << cache_header
            else
              output << header_for_string(state) 
              output << self
            end
          end
          
          def from_amf()
            self
          end
          
          private
          
          def header_for_string(state = nil)
            header = self.length << 1 # make room for a low bit of 1
            header = header | 1 # set the low bit to 1
            AMF.pack_integer(header, state)
          end
        end
        
        module Symbol
          def to_amf(state = nil, *)
            self.to_s.to_amf(state)
          end
        end
        
        module Array
          def to_amf(state = nil, *)
            output = ''
            output << ARRAY_MARKER
          
            if state && (cache_header =  state.object_cache(self))
              output << cache_header
            else
              state = AMF.state.from_state(state) 
              output << header_for_array(state)
              # AMF only encodes strict, dense arrays by the AMF spec
              # so the dynamic portion is empty
              output << CLOSE_DYNAMIC_ARRAY
              self.each do |val|
                output << val.to_amf(state)
              end
            end
            output
          end
          
          private
          
          def header_for_array(state = nil)
            header = self.length << 1 # make room for a low bit of 1
            header = header | 1 # set the low bit to 1
            AMF.pack_integer(header, state)
          end
        end
        
        module Hash
          
          private
          
          def serialize_properties(state = nil)
            output = ''
            self.each do |key, value|
              output << key.to_amf(state) # easy for both string and symbol keys
              output << value.to_amf(state)
            end
            output
          end
        end
        
        module Time
          def to_amf(state = nil, *)
            output = ''
            output << DATE_MARKER
            
            seconds = (self.utc?) ? self.to_f : self.utc
            
            if state && (cache_header = state.object_cache(self))
              output << cache_header
            else
              output << ONE
              output << AMF.pack_double(seconds, state)
            end
          end
        end
        
        module Date
          def to_amf(state = nil, *)
            output = ''
            output << DATE_MARKER
            
            seconds = ((self.strftime("%s").to_i) * 1000).to_i
            
            if state && (cache_header = state.object_cache(self))
              output << cache_header
            else
              output << ONE
              output << AMF.pack_double(seconds, state)
            end
          end
        end
        
        module Object
          def to_amf(state = nil, *)
            output = ''
            output << OBJECT_MARKER
            
            if state && (cache_header = state.object_cache(self))
              output << cache_header
            else
              state = AMF.state.from_state(state) 
              output << DYNAMIC_OBJECT << ANONYMOUS_OBJECT
              output << serialize_properties(state)
              output << CLOSE_DYNAMIC_OBJECT
            end
          end
          
          protected
          
          def amf_id
            object_id
          end
          
          private
            
          # unmapped object
          #OPTIMIZE: keep a hash of classes that come through here
          # and store in a hash keyed by obj.class
          # if the obj.class is in the hash, loop over the hash of
          # public methods
          # find all public methods belonging to this object alone
          def serialize_properties(state = nil)
            output = ''
            self.public_methods(false).each do |method_name|
              # and write them to the stream if they take no arguments
              method_def = self.method(method_name)
              if method_def.arity == 0
                output << method_name.to_amf(state)
                output << self.send(method_name).to_amf(state)
              end
            end
            output
          end
        end
        
        module REXML
          class Document
            def to_amf(state = nil, *)
              AMF.write_xml(self, state)
            end
          end
        end
      end 
    end
  end
  
  module_function
  
  def pack_integer(integer, state = nil)
    if state
      state.integer_cache[integer] ||= pack_integer_helper(integer)
    else
      pack_integer_helper(integer)
    end
  end
  
  def pack_integer_helper(integer)
    integer = integer & 0x1fffffff
    if(integer < 0x80)
      [integer].pack('c')
    elsif(integer < 0x4000)
      [integer >> 7 & 0x7f | 0x80].pack('c')+
        [integer & 0x7f].pack('c')
    elsif(integer < 0x200000)
      [integer >> 14 & 0x7f | 0x80].pack('c')+
        [integer >> 7 & 0x7f | 0x80].pack('c')+
        [integer & 0x7f].pack('c')
    else
      [integer >> 22 & 0x7f | 0x80].pack('c')+
        [integer >> 15 & 0x7f | 0x80].pack('c')+
        [integer >> 8 & 0x7f | 0x80].pack('c')+
        [integer & 0xff].pack('c')
    end
    integer
  end
  
  def pack_double(double, state = nil)
    if state
      (state.float_cache[double] ||= [double].pack('G'))
    else
      [double].pack('G')
    end
  end

end