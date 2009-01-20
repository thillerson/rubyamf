require 'date'
require 'bigdecimal'
require 'rexml/document'
module AMF  
  module Pure
    module Serializer
      class State
        
        # Creates a State object from _opts_, which ought to be Hash to create
        # a new State instance configured by _opts_, something else to create
        # an unconfigured instance. If _opts_ is a State object, it is just
        # returned.
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
          @string_cache.fetch(str.amf_id) { |amf_id|
            @string_cache[amf_id] = @string_counter += 1
            nil
          }
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
          @object_cache.fetch(obj.amf_id) { |amf_id|
            @object_cache[amf_id] = @object_counter += 1
            nil
          }
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
          
          def amf_id
            object_id
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
  
  def write_integer(integer, state = nil)
    output = ''
    output << INTEGER_MARKER
    output << pack_integer(integer)
    output
  end
    
  def write_double(double, state = nil, include_marker=true)
    output = ''
    output << DOUBLE_MARKER if include_marker
    output << pack_double(double, state)
    output
  end
  
  def write_string(string, state = nil)
    output = ''
    output << STRING_MARKER
    if string == ''
      output << EMPTY_STRING
    elsif state && (index = state.string_cache(string))
      output << header_for_cache(index, state)
    else
      output << header_for_string(string, state) 
      output << string
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
    
    if state && (index = state.object_cache(datetime))
      output << header_for_cache(index, state)
    else
      output << ONE
      output << write_double(seconds, state, false)
    end
  end
  
  def write_object(obj, state = nil)
    output = ''
    output << OBJECT_MARKER
    
    if state && (index = state.object_cache(obj))
      output << header_for_cache(index, state)
    else
      state = AMF.state.from_state(state) 
      # Dynamic, Anonymous Object - very simple heuristics
      if obj.is_a? Hash
        output << DYNAMIC_OBJECT << ANONYMOUS_OBJECT
        obj.each do |key, value|
          output << key.to_amf(state) # easy for both string and symbol keys
          output << value.to_amf(state)
        end
      else# unmapped object
        #OPTIMIZE: keep a hash of classes that come through here
        # and store in a hash keyed by obj.class
        # if the obj.class is in the hash, loop over the hash of
        # public methods
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
    output
  end
  
  def write_array(array, state = nil)
    output = ''
    output << ARRAY_MARKER
  
    if state && (index = state.object_cache(array))
      output << header_for_cache(index, state)
    else
      state = AMF.state.from_state(state) 
      output << header_for_array(array, state)
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
  # there is no reference
  # see 1.3.2 and 3.8 in the published AMF spec
  # header is a low bit of 1 with the length occupying
  # the remaining bits
  def header_for_string(string, state = nil)
    header = string.length << 1 # make room for a low bit of 1
    header = header | 1 # set the low bit to 1
    pack_integer(header, state)
  end
  
  # header is a low bit of 1 with the length occupying
  # the remaining bits
  def header_for_array(array, state = nil)
    header = array.length << 1 # make room for a low bit of 1
    header = header | 1 # set the low bit to 1
    pack_integer(header, state)
  end
  
  # references have a low bit of 0 with the remaining
  # bits being the reference
  def header_for_cache(index, state = nil)
    header = index << 1 # shift value left to leave a low bit of 0
    pack_integer(header, state)
  end
  
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