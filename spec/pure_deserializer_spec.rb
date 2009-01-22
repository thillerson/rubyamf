require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/expected_values.rb'
require File.dirname(__FILE__) + '/amf_helpers.rb'

require 'date'
require 'rubygems'
require 'ruby-debug'

describe AMF do
  describe "when deserializing" do
    describe "simple messages" do
  
      it "should deserialize a null" do
        expected = nil
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
  
      it "should deserialize a false" do
        expected = false
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
  
      it "should deserialize a true" do
        expected = true
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
  
      it "should deserialize simple integers" do
        expected = 1
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
        
        expected = 10
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
  
      it "should deserialize a floating point number" do
        expected = 1.1
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
  
      it "should deserialize a negative floating point number" do
        expected = -1.1
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
  
      it "should deserialize large integers" do
        expected = MAX_INTEGER + 1
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
  
      it "should deserialize large negative integers" do
        expected = MIN_INTEGER - 1
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
      
      it "should deserialize BigNums" do
        expected = 2**1000
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
      
      it "should deserialize BigDecimals" do
        expected = BigDecimal.new("1.2")
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
  
      it "should deserialize a simple string" do
        expected = "Hello World!"
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
  
      it "should deserialize a symbol as a string" do
        expected = :foo
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
  
      it "should deserialize Dates and DateTimes" do
        expected = DateTime.parse "1/1/1970"
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
  
        expected = Date.today
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
  
      it "should deserialize Times" do
        expected = Time.utc 1970, 1, 1, 0
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
  
        expected = Time.new
        input = expected.to_amf
        output = input.from_amf
        output.should == expected
      end
    end
  end
end

