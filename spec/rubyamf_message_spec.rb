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

      it "should serialize a symbol as a string" do
        @message.write :foo
        @message.output_stream.should == "#{ENCODED_STRING_MARKER}foo"
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

      it "should serialize an unmapped object as a dynamic anonymous object" do

        # A non-mapped object is any object not explicitly mapped
        # it should be encoded as a dynamic anonymous object with 
        # dynamic properties for all "messages" (public methods)
        # that have an arity of 0, meaning that they take no arguments
        obj = NonMappedObject.new
        obj.property_one = 'foo'
        obj.property_two = 1
        obj.nil_property = nil
      
        @message.write obj
        # can't depend on order
        # open object
        @message.output_stream.should match(/^#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}.+/)
        # close object
        @message.output_stream.should match(/.*#{ENCODED_CLOSE_OBJECT_MARKER}$/)
        
        # encodable properties
        @message.output_stream.should match(/#{ENCODED_STRING_MARKER}property_one#{ENCODED_STRING_MARKER}foo/)
        @message.output_stream.should match(/#{ENCODED_STRING_MARKER}property_two#{ENCODED_INTEGER_MARKER}#{ENCODED_ONE}/)
        @message.output_stream.should match(/#{ENCODED_STRING_MARKER}another_public_property#{ENCODED_STRING_MARKER}foo/)
        @message.output_stream.should match(/#{ENCODED_STRING_MARKER}nil_property#{ENCODED_NULL_MARKER}/)
        
        # non-encodable properties
        @message.output_stream.should_not match(/#{ENCODED_STRING_MARKER}method_with_arg/)
        @message.output_stream.should_not match(/#{ENCODED_STRING_MARKER}read_only_prop/)
      end
      
      it "should serialize a shallow hash as a dynamic anonymous object" do
        hash = {}
        hash[:foo] = "bar"
        hash[:answer] = 42
        
        @message.write hash
        # can't depend on order
        # open object
        @message.output_stream.should match(/^#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}.+/)
        # close object
        @message.output_stream.should match(/.*#{ENCODED_CLOSE_OBJECT_MARKER}$/)

        # encodable properties
        @message.output_stream.should match(/#{ENCODED_STRING_MARKER}foo#{ENCODED_STRING_MARKER}bar/)
        @message.output_stream.should match(/#{ENCODED_STRING_MARKER}foo#{ENCODED_INTEGER_MARKER}#{ENCODED_42}/)
      end
      
      it "should serialize an open struct as a dynamic anonymous object"
      it "should serialize an array of primatives"
      it "should serialize a deep graph"
      it "should serialize a deep mixed graph"
      it "should serialize an array of objects"
      it "should serialize an ArrayCollection"

    end

    describe "and implementing AMF Spec" do

      it "should reference strings"
      it "should reference objects"
      it "should reference dates"

    end
    
    describe "and implementing special features" do
      
      it "should serialize a pre-mapped object"
      it "should camelize snake cased properties"
      
    end

  end
  
  describe "when deserializing" do
    
    it "should be able to clear the input stream"
    
  end

end

