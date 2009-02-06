require 'rack/amf/request'
require 'rack/amf/response'
 
module Rack::AMF 
  # Raised when an attempt is made to transition to an event that can
  # not be transitioned from the current event 
  class IllegalTransition < Exception
  end

  module Core
 
    attr_reader :original_request
    attr_reader :original_response
    attr_reader :request
    attr_reader :response
    
    # Has the given event been performed at any time during the
    # request life-cycle? Useful for testing
    def performed?(event)
      @triggered.include?(event)
    end
    
    # Event handlers
    attr_reader :events
    private :events
 
  public
    # Attach custom logic to one or more events
    def on(*events, &block)
      events.each { |event| @events[event].unshift(block) }
      nil
    end
 
  private
    # Transitioning statements
 
    def receive!      ; throw(:transition, [:receive]) ; end
    def serialize!    ; throw(:transition, [:serialize]) ; end
    def pass!         ; throw(:transition, [:pass]) ; end
    def respond!      ; throw(:transition, [:respond]) ; end
    def deserialize!  ; throw(:transition, [:deserialize]) ; end
    def deliver!      ; throw(:transition, [:deliver]) ; end
      
    def error!(code=500, headers={}, body=nil)
      throw(:transition, [:error, code, headers, body])
    end
 
  private 
    def initialize_core
      @triggered = []
      @events = Hash.new { |h,k| h[k.to_sym] = [] }
      
      @request = nil
      @response = nil
      @original_request = nil
      @original_response = nil
    end
    
    # Process a request. This method is compatible with Rack's #call
    # interface.
    def process_request(env)
      @triggered = []
      @env = @default_options.merge(env)
      perform_receive
    end
    
    # Delegate the request to the backend and create the response.
    def fetch_from_backend
      status, headers, body = backend.call(request.env)
      response = Response.new(status, headers, body)
      @response = response.dup
      @original_response = response.freeze
    end
    
  private
    
    def perform_receive
      @original_request = Request.new(@env.dup.freeze)
      @request = Request.new(@env)
      transition(from=:receive, to=[:deserialize, :pass, :error])
    end
    
    def perform_deserialize
      # AMF.deserialize(source)
      # deserialize request body into hash
      transition(from=:deserialize, to=[:pass, :error])
    end
    
    def perform_pass
      fetch_from_backend
      transition(from=:pass, to=[:respond, :error])
    end
    
    def perform_respond
      transition(from=:respond, to=[:serialize, :deliver, :error])
    end
    
    def perform_serialize
      #AMF.serialize(source)
      #serialize response 
      transition(from=:serialize, to=[:deliver, :error])
    end
    
    def perform_deliver
      response.to_a
    end
    
    def perform_error(code=500, headers={}, body=nil)
      body, headers = headers, {} unless headers.is_a?(Hash)
      headers = {} if headers.nil?
      body = [] if body.nil? || body == ''
      @response = Rack::AMF::Response.new(code, headers, body)
      transition(from=:error, to=[:error, :serialize, :deliver]) do |event|
        if event == :error && @response.something 
          #we werent able to serialize the error message
          :deliver
        end
      end
    end
    
  private
    # Transition from the currently processing event to another event
    # after triggering event handlers.
    def transition(from, to)
      ev, *args = trigger(from)
      raise IllegalTransition, "No transition to :#{ev}" unless to.include?(ev)
      ev = yield ev if block_given?
      send "perform_#{ev}", *args
    end
 
    # Trigger processing of the event specified and return an array containing
    # the name of the next transition and any arguments provided to the
    # transitioning statement.
    def trigger(event)
      if @events.include? event
        @triggered << event
        catch(:transition) do
          @events[event].each { |block| instance_eval(&block) }
          nil
        end
      else
        raise NameError, "No such event: #{event}"
      end
    end
  end
end