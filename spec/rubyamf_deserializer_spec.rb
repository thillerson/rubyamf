require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/expected_values.rb'
require File.dirname(__FILE__) + '/amf_helpers.rb'

require 'date'
require 'rubygems'
require 'ruby-debug'

describe AMF::Message do
  
  before do
    @message = AMF::Message.new
  end
  
  describe "when deserializing" do
    
  end
end

