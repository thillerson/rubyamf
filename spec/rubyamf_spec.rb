require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/constants.rb'
require File.dirname(__FILE__) + '/amf_helpers.rb'

require 'date'

describe RubyAMF::Message do
  
  before do
    @message = RubyAMF::Message.new
  end
  
  describe "when serializing" do
    
    describe "simple messages" do

      it "should serialize a null" do
        @message.write nil
        @message.output_stream.should == ENCODED_NULL_MARKER
      end

      it "should serialize a false" do
        @message.write false
        @message.output_stream.should == ENCODED_FALSE_MARKER
      end

      it "should serialize a true" do
        @message.write true
        @message.output_stream.should == ENCODED_TRUE_MARKER
      end

      it "should serialize a simple number" do
        @message.write 1
        @message.output_stream.should == "#{ENCODED_INTEGER_MARKER}\001"
      end

      it "should serialize a floating point number" do
        @message.write 1.1
        @message.output_stream.should == "#{ENCODED_DOUBLE_MARKER}#{[1.1].pack('G')}"
      end

      it "should serialize a negative floating point number" do
        @message.write -1.1
        @message.output_stream.should == "#{ENCODED_DOUBLE_MARKER}#{[-1.1].pack('G')}"
      end

      it "should serialize large numbers" do
        # bigger integer
        big_positive_int = MAX_INTEGER + 1
        @message.write( big_positive_int )
        @message.output_stream.should == "#{ENCODED_DOUBLE_MARKER}" << [big_positive_int].pack('G')
      end

      it "should serialize large negative numbers" do
        # bigger negative integer
        big_negative_int = MIN_INTEGER - 1
        @message.write( big_negative_int )
        @message.output_stream.should == "#{ENCODED_DOUBLE_MARKER}" << [big_negative_int].pack('G')
      end

      it "should serialize a simple string" do
        @message.write "Hello World!"
        @message.output_stream.should == "#{ENCODED_STRING_MARKER}Hello World!"
      end

      it "should serialize a Date" do
        pending do
          d = Date.parse "1/1/1971"
          @message.write d
          @message.output_stream.should == "#{ENCODED_DATE_MARKER}" << [0].pack('G')
        end
      end

      it "should serialize a Time"

      it "should serialize a DateTime"

      it "should serialize a REXML document"

      it "should serialize some Beautiful Soup"

    end

    describe "objects" do

      it "should serialize an object"
      it "should serialize an array"
      it "should serialize a hash"
      it "should serialize an ArrayCollection"

    end

    describe "and implementing AMF Spec" do

      it "should reference strings"
      it "should reference objects"
      it "should reference dates"

    end

  end
  

end

