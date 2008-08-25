require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/expected_values.rb'
require File.dirname(__FILE__) + '/amf_helpers.rb'

require 'date'
require 'rubygems'
require 'ruby-debug'

describe RubyAMF::Message do
  
  before do
    @message = RubyAMF::Message.new
  end
  
  describe "when serializing" do
    
    it "should be able to clear output stream" do
      @message.output_stream.should be_empty
      @message.write "foo"
      @message.output_stream.should_not be_empty
      @message.output_stream.clear!
      @message.output_stream.should be_empty
    end
    
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

      it "should serialize simple integers" do
        @message.write 1
        @message.output_stream.should == "#{ENCODED_INTEGER_MARKER}#{ENCODED_ONE}"
        
        @message.output_stream.clear!
        
        @message.write 10
        @message.output_stream.should == "#{ENCODED_INTEGER_MARKER}#{ENCODED_TEN}"
      end

      it "should serialize a floating point number" do
        @message.write 1.1
        @message.output_stream.should == "#{ENCODED_DOUBLE_MARKER}" << expected_double_value_for( 1.1 )
      end

      it "should serialize a negative floating point number" do
        @message.write -1.1
        @message.output_stream.should == "#{ENCODED_DOUBLE_MARKER}" << expected_double_value_for( -1.1 )
      end

      it "should serialize large integers" do
        # bigger integer
        big_positive_int = MAX_INTEGER + 1
        @message.write( big_positive_int )
        @message.output_stream.should == "#{ENCODED_DOUBLE_MARKER}" << expected_double_value_for( big_positive_int )
      end

      it "should serialize large negative integers" do
        # bigger negative integer
        big_negative_int = MIN_INTEGER - 1
        @message.write( big_negative_int )
        @message.output_stream.should == "#{ENCODED_DOUBLE_MARKER}" << expected_double_value_for( big_negative_int )
      end
      
      it "should serialize BigNums" do
        # this should be a Bignum. It certainly is big...
        bignum = 2**1000
        @message.write bignum
        @message.output_stream.should == "#{ENCODED_DOUBLE_MARKER}" << expected_double_value_for( bignum )
      end
      
      it "should serialize BigDecimals" do
        bigdec = BigDecimal.new("1.2")
        @message.write bigdec
        @message.output_stream.should == "#{ENCODED_DOUBLE_MARKER}" << expected_double_value_for( bigdec )
      end

      it "should serialize a simple string" do
        @message.write "Hello World!"
        @message.output_stream.should == "#{ENCODED_STRING_MARKER}Hello World!"
      end

      it "should serialize Dates and DateTimes" do
        # should be 0 in unix epoch time
        d = DateTime.parse "1/1/1970"
        expected_time_stamp = expected_double_value_for 0
        @message.write d
        @message.output_stream.should == "#{ENCODED_DATE_MARKER}" << expected_time_stamp
        
        @message.output_stream.clear!
        
        d = Date.today
        expected_time_stamp = expected_double_value_for( d.strftime('%s').to_i * 1000 )
        @message.write d
        @message.output_stream.should == "#{ENCODED_DATE_MARKER}" << expected_time_stamp
      end

      it "should serialize Times" do
        # should be 0 in unix epoch time
        t = Time.utc 1970, 1, 1, 0
        expected_time_stamp = expected_double_value_for 0
        @message.write t
        @message.output_stream.should == "#{ENCODED_DATE_MARKER}" << expected_time_stamp
        
        @message.output_stream.clear!
        
        t = Time.new
        @message.write t
        expected_time_stamp = expected_double_value_for t.utc.to_f
        @message.output_stream.should == "#{ENCODED_DATE_MARKER}" << expected_time_stamp
      end

      #BAH! Who sends XML over AMF?
      it "should serialize a REXML document"

      #BAH! Who sends XML over AMF?
      it "should serialize some Beautiful Soup"

    end

    describe "objects" do

      it "should serialize an unmapped object" do

        pending do
          obj = NonMappedObject.new
          obj.property_one = 'foo'
          obj.property_two = 1
        
          @message.write obj
          @message.output_stream.should == ""
        end 
      end
      
      it "should serialize a hash"
      it "should serialize an array"
      it "should serialize an ArrayCollection"
      it "should serialize a pre-mapped object"

    end

    describe "and implementing AMF Spec" do

      it "should reference strings"
      it "should reference objects"
      it "should reference dates"

    end

  end
  
  describe "when deserializing" do
    
    it "should be able to clear the input stream"
    
  end

end

