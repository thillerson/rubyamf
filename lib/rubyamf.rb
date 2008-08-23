$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
$:.unshift "#{File.expand_path(File.dirname(__FILE__))}/rubyamf/"

require "constants"
require "class_extensions"
require "io/serializer"
require "io/deserializer"

module RubyAMF
  
  class Message
    include Serializer
    include Deserializer
    
    def initialize input_stream=''
      self.input_stream = input_stream
      self.output_stream = ''
    end
    
  end
  
end