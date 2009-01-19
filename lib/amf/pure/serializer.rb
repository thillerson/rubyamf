require 'date'
require 'bigdecimal'
require 'rexml/document'
module AMF  
  module Pure
    module Serializer
      class State
        def initialize(opts = {})
          @integer_cache  ||= {}
          @float_cache    ||= {}
          @string_counter ||= 0
          @string_cache   ||= {}
          @object_counter ||= 0
          @object_cache   ||= {}
          @empty_array_cache   ||= {}
        end
        attr_accessor :integer_cache, 
                      :floats_cache,
                      :string_counter,
                      :string_cache,
                      :object_counter,
                      :object_cache,
                      :empty_array_cache
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
          def to_amf(state = nil, *)
            #AMF.write_double self
            self.to_f.to_amf(state)
          end
        end
        
        module Integer
          def to_amf(state = nil, *)
            AMF.write_number(self, state)
          end
        end
        
        module Float
          def to_amf(state = nil, *)
            AMF.write_double(self, state)
          end
        end
        
        module BigDecimal
          def to_amf(state = nil, *)
            #AMF.write_double self
            self.to_f.to_amf(state)
          end
        end
        
        module String
          def to_amf(state = nil, *)
            AMF.write_string(self, state)
          end
        end
        
        module Symbol
          def to_amf(state = nil, *)
            self.to_s.to_amf(state)
          end
        end
        
        module Array
          def to_amf(state = nil, *)
            AMF.write_array(self, state)
          end
        end
        
        module Hash
          def to_amf(state = nil, *)
            AMF.write_object(self, state)
          end
        end
        
        module Time
          def to_amf(state = nil, *)
            AMF.write_date(self, state)
          end
        end
        
        module Date
          def to_amf(state = nil, *)
            AMF.write_date(self, state)
          end
        end
        
        module Object
          def to_amf(state = nil, *)
            AMF.write_object(self, state)
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
  
  require 'constants'
  
  module_function
  
  def write_null
    NULL_MARKER
  end
  
  def write_false
    FALSE_MARKER
  end
  
  def write_true
    TRUE_MARKER
  end
  
  # integers can be 29 bits wide in the AMF spec
  def write_number(number, state = nil)
    if number >= MIN_INTEGER && number <= MAX_INTEGER #check valid range for 29 bits
      write_integer(number, state)
    else #overflow to a double
      number.to_f.to_amf(state)
    end
  end
  
  def write_integer(number, state = nil)
    output = ''
    output << INTEGER_MARKER
    if state
      output << (state.integer_cache[number] ||= pack_int(number))
    else
      output << pack_int(number)
    end
    output
  end
    
  def write_double(double, state = nil, include_marker=true)
    output = ''
    output << DOUBLE_MARKER if include_marker
    if state
      output << (state.float_cache[double] ||= [double].pack('G'))
    else
      output << [double].pack('G')
    end
    output
  end
  
  def write_string(string, state = nil)
    output = ''
    output << STRING_MARKER
    output << EMPTY_STRING and return if string == ''
    if index = string_cache(string, state)
      output << header_for_cache( index )
    else
      output << header_for_string( string ) << string
    end
  end
  
  def write_date(datetime, state = nil)
    output = ''
    output << DATE_MARKER
    
    seconds = if datetime.is_a?(Time)
      datetime.utc unless datetime.utc?
      datetime.to_f
    elsif datetime.is_a?(Date) # this also handles the case of a DateTime
      ((datetime.strftime("%s").to_i) * 1000).to_i
    end
    
    if index = object_cache(seconds, state)
      output << header_for_cache(index)
    else
      output << ONE
      output << write_double(seconds, state, false)
    end
  end
  
  def write_object(obj, state = nil)
    output = ''
    output << OBJECT_MARKER
    
    if index = object_cache( obj, state )
      output << header_for_cache(index) and return
    end
    
    state ||= AMF::Pure::Serializer::State.new
    
    # Dynamic, Anonymous Object - very simple heuristics
    if obj.is_a? Hash
      output << DYNAMIC_OBJECT << ANONYMOUS_OBJECT
      obj.each do |key, value|
        output << key.to_amf(state) # easy for both string and symbol keys
        output << value.to_amf(state)
      end
    else # unmapped object
      output << DYNAMIC_OBJECT << ANONYMOUS_OBJECT
      # find all public methods belonging to this object alone
      obj.public_methods(false).each do |method_name|
        # and write them to the stream if they take no arguments
        method_def = obj.method(method_name)
        if method_def.arity == 0
          output << method_name.to_amf(state)
          output << obj.send(method_name).to_amf(state)
        end
      end
    end
    output << CLOSE_DYNAMIC_OBJECT
  end
  
  def write_array(array, state = nil)
    output = ''
    output << ARRAY_MARKER
  
    if index = object_cache( array, state )
      output << header_for_cache(index)
    else
      state ||= AMF::Pure::Serializer::State.new
      output << header_for_array( array )
      # AMF only encodes strict, dense arrays by the AMF spec
      # so the dynamic portion is empty
      output << CLOSE_DYNAMIC_ARRAY
      array.each do |val|
        output << val.to_amf(state)
      end
    end
    output
  end
  
  # expects argument to be a non-empty string for which
  # there is no reference.
  # see 1.3.2 and 3.8 in the published AMF spec
  # header is a low bit of 1 with the length occupying
  # the remaining bits
  def header_for_string string
    header = string.length << 1 # make room for a low bit of 1
    header = header | 1 # set the low bit to 1
    pack_int header
  end
  
  # header is a low bit of 1 with the length occupying
  # the remaining bits
  def header_for_array array
    header = array.length << 1 # make room for a low bit of 1
    header = header | 1 # set the low bit to 1
    pack_int header
  end
  
  # references have a low bit of 0 with the remaining
  # bits being the reference
  def header_for_cache index
    header = index << 1 # shift value left to leave a low bit of 0
    pack_int header
  end
  
  def pack_int number
    number = number & 0x1fffffff
    if(number < 0x80)
      [number].pack('c')
    elsif(number < 0x4000)
      [number >> 7 & 0x7f | 0x80].pack('c')+
        [number & 0x7f].pack('c')
    elsif(number < 0x200000)
      [number >> 14 & 0x7f | 0x80].pack('c')+
        [number >> 7 & 0x7f | 0x80].pack('c')+
        [number & 0x7f].pack('c')
    else
      [number >> 22 & 0x7f | 0x80].pack('c')+
        [number >> 15 & 0x7f | 0x80].pack('c')+
        [number >> 8 & 0x7f | 0x80].pack('c')+
        [number & 0xff].pack('c')
    end
    number
  end
   
  # if string has been referenced, returns the index of the reference
  # in the implicit string reference tabel. If no reference is found
  # sets the reference to the next index in the implicit strings table
  # and returns nil
  def string_cache(str, state = nil)
    #TODO: shorten if statement
    if state
      state.string_cache.fetch(str) do |missed_fetch|
        state.string_cache[missed_fetch] = state.string_counter += 1
        nil
      end
    else
      nil
    end
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
  def object_cache(obj, state = nil)
    #TODO: shorten if statement
    if state
      if obj == []
          state.empty_array_cache.fetch(obj.object_id) do |missed_fetch|
            state.empty_array_cache[missed_fetch] = state.object_counter += 1
            nil
          end
      else
        state.object_cache.fetch(obj) do |missed_fetch|
          state.object_cache[missed_fetch] = state.object_counter += 1
          nil
        end
      end
    else
      nil
    end
  end
end