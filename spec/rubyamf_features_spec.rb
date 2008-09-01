require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/expected_values.rb'
require File.dirname(__FILE__) + '/amf_helpers.rb'

require 'date'
require 'rubygems'
require 'ruby-debug'

describe RubyAMF do
  
  before do
    @message = RubyAMF::Message.new
  end
  
  describe "when implementing RubyAMF features" do
    
    it "should serialize an array as an ArrayCollection"
    it "should serialize a pre-mapped object"
    it "should optionally camelize snake_cased properties"
    
  end

end

