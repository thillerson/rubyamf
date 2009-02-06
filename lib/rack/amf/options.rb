require 'rack'
 
module Rack::AMF
  # Configuration options and utility methods for option access. Rack::AMF
  # uses the Rack Environment to store option values. All options documented
  # below are stored in the Rack Environment as "amf.<option>", where
  # <option> is the option name.
  #
  # The #set method can be used within an event or a top-level configuration
  # block to configure a option values. When #set is called at the top-level,
  # the value applies to all requests; when called from within an event, the
  # values applies only to the request being processed.
 
  module Options
    class << self
      private
      def option_accessor(key)
        define_method(key) { || read_option(key) }
        define_method("#{key}=") { |value| write_option(key, value) }
        define_method("#{key}?") { || !! read_option(key) }
      end
    end
 
    # Enable verbose trace logging. This option is currently enabled by
    # default but is likely to be disabled in a future release.
    option_accessor :verbose
 
    # The underlying options Hash. During initialization (or outside of a
    # request), this is a default values Hash. During a request, this is the
    # Rack environment Hash. The default values Hash is merged in underneath
    # the Rack environment before each request is processed.
    def options
      @env || @default_options
    end
 
    # Set multiple options.
    def options=(hash={})
      hash.each { |key,value| write_option(key, value) }
    end
 
    # Set an option. When +option+ is a Symbol, it is set in the Rack
    # Environment as "amf.option". When +option+ is a String, it
    # exactly as specified. The +option+ argument may also be a Hash in
    # which case each key/value pair is merged into the environment as if
    # the #set method were called on each.
    def set(option, value=self, &block)
      if block_given?
        write_option option, block
      elsif value == self
        self.options = option.to_hash
      else
        write_option option, value
      end
    end
 
  private
    def read_option(key)
      options[option_name(key)]
    end
 
    def write_option(key, value)
      options[option_name(key)] = value
    end
 
    def option_name(key)
      case key
      when Symbol ; "amf.#{key}"
      when String ; key
      else raise ArgumentError
      end
    end
 
  private
    def initialize_options(options={})
      @default_options = {
        'amf.verbose' => true,
      }
      self.options = options
    end
  end
end