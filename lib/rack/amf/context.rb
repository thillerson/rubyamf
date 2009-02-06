require 'rack/amf/config'
require 'rack/amf/options'
require 'rack/amf/core'
require 'rack/amf/request'
require 'rack/amf/response'
 
module Rack::AMF
  class Context
    include Rack::AMF::Options
    include Rack::AMF::Config
    include Rack::AMF::Core
 
    # The Rack application object immediately downstream.
    attr_reader :backend
 
    def initialize(backend, options={}, &block)
      @errors = nil
      @env = nil
      @backend = backend
      initialize_options options
      initialize_core
      initialize_config(&block)
    end
 
    # The call! method is invoked on the duplicate context instance.
    # process_request is defined in Core.
    alias_method :call!, :process_request
    protected :call!
 
    # The Rack call interface. The receiver acts as a prototype and runs each
    # request in a duplicate object, unless the +rack.run_once+ variable is set
    # in the environment.
    def call(env)
      if env['rack.run_once']
        call! env
      else
        clone.call! env
      end
    end
  
  public
  
    # IO-like object that receives log, warning, and error messages;
    # defaults to the rack.errors environment variable.
    def errors
      @errors || (@env && (@errors = @env['rack.errors'])) || STDERR
    end
 
    # Set the output stream for log messages, warnings, and errors.
    def errors=(ioish)
      fail "stream must respond to :write" if ! ioish.respond_to?(:write)
      @errors = ioish
    end
 
  protected
  
    # Write a log message to the errors stream. +level+ is a symbol
    # such as :error, :warn, :info, or :trace.
    def log(level, message=nil, *params)
      errors.write("[amf] #{level}: #{message}\n" % params)
      errors.flush
    end
 
    def info(*message, &bk)
      log :info, *message, &bk
    end
 
    def warn(*message, &bk)
      log :warn, *message, &bk
    end
 
    def trace(*message, &bk)
      return unless verbose?
      log :trace, *message, &bk
    end
  end
end