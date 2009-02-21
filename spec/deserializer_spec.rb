require File.dirname(__FILE__) + '/spec_helper.rb'

require 'date'
require 'rexml/document'

describe AMF do
  describe "when deserializing" do
    
    def readBinaryObject(binary_path)
      File.open('spec/fixtures/objects/' + binary_path).read
    end

    def readBinaryRequest(binary_path)
      File.open('spec/fixtures/request/' + binary_path).read
    end
    
    describe "simple messages" do
      
      it "should deserialize a null" do  
        expected = nil
        input = readBinaryObject("null.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end

      it "should deserialize a false" do
        expected = false
        input = readBinaryObject("false.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end

      it "should deserialize a true" do
        expected = true
        input = readBinaryObject("true.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end

      it "should deserialize integers" do
        expected = AMF::MAX_INTEGER
        input = readBinaryObject("max.bin")
        output = AMF.deserialize(input)
        output.should == expected
        
        expected = 0
        input = readBinaryObject("0.bin")
        output = AMF.deserialize(input)
        output.should == expected
        
        expected = AMF::MIN_INTEGER
        input = readBinaryObject("min.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should deserialize large integers" do
        expected = AMF::MAX_INTEGER + 1
        input = readBinaryObject("largeMax.bin")
        output = AMF.deserialize(input)
        output.should == expected
        
        expected = AMF::MIN_INTEGER - 1
        input = readBinaryObject("largeMin.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should deserialize BigNums" do
        expected = 2**1000
        input = readBinaryObject("bigNum.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end

      it "should deserialize a simple string" do
        expected = "String . String"
        input = readBinaryObject("string.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end

      it "should deserialize a symbol as a string" do
        expected = "foo"
        input = readBinaryObject("symbol.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end

      it "should deserialize DateTimes" do
        expected = DateTime.parse "1/1/1970"
        input = readBinaryObject("date.bin")
        output = AMF.deserialize(input)
        output.should == expected
        
        #expected = DateTime.new
        #output = input.to_amf
        #output.should == expected
      end
      
      it "should deserialize Dates" do
        expected = Date.parse "1/1/1970"
        input = readBinaryObject("date.bin")
        output = AMF.deserialize(input)
        output.should == expected
        
        #expected = Date.new
        #output = input.to_amf
        #output.should == expected
      end

      it "should deserialize Times" do
        expected = Time.utc 1970, 1, 1, 0
        input = readBinaryObject("date.bin")
        output = AMF.deserialize(input)
        output.should == expected

        #expected = Time.new
        #output = input.to_amf
        #output.should == expected
      end

      #BAH! Who sends XML over AMF?
      it "should deserialize a REXML document"
    end

    describe "objects" do

      it "should deserialize an unmapped object as a dynamic anonymous object" do

        obj = {:property_one => 'foo', 
               :property_two => 1, 
               :nil_property => nil, 
               :another_public_property => 'a_public_value'}
      
        expected = obj
        input = readBinaryObject("dynObject.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should deserialize a hash as a dynamic anonymous object" do
        hash = {}
        hash[:foo] = "bar"
        hash[:answer] = 42
        
        #need to account for order
        expected = hash
        input = readBinaryObject("hash.bin")
        output = AMF.deserialize(input)
        output.should == expected     
      end
      
      it "should deserialize an open struct as a dynamic anonymous object"
      
      it "should deserialize an empty array" do
        expected = []
        input = readBinaryObject("emptyArray.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should deserialize an array of primatives" do
        expected = [1, 2, 3, 4, 5]
        input = readBinaryObject("primArray.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should deserialize an array of mixed objects" do
        h1 = {:foo_one => "bar_one"}
        h2 = {:foo_two => ""}
        so1 = {:foo_three => 42}
                
        expected = [h1, h2, so1, {:foo_three => nil}, {}, [h1, h2, so1], [], 42, "", [], "", {}, "bar_one", so1]    
        input = readBinaryObject("mixedArray.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end

      it "should deserialize a byte array"

    end

    describe "and implementing the AMF Spec" do

      it "should keep references of duplicate strings" do
        class StringCarrier
          attr_accessor :str
        end       
        foo = "foo"
        bar = "str"
        sc = StringCarrier.new
        sc = {bar => foo}
        
        expected = [foo, bar, foo, bar, foo, sc]
        input = readBinaryObject("stringRef.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should not reference the empty string" do
        expected = ["", ""]
        input = readBinaryObject("emptyStringRef.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should keep references of duplicate dates" do
        date = Date.parse "1/1/1970"
        expected = [date, date]
        input = readBinaryObject("datesRef.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should keep reference of duplicate objects" do
#        class SimpleReferenceableObj
#          attr_accessor :foo
#        end
#        obj1 = SimpleReferenceableObj.new
#        obj1.foo = :foo
#        obj2 = SimpleReferenceableObj.new
#        obj2.foo = obj1.foo

        obj1 = {:foo => :bar}
        obj2 = {:foo => obj1[:foo]}
        
        expected = [[obj1, obj2], "bar", [obj1, obj2]]
        input = readBinaryObject("objRef.bin") 
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should keep references of duplicate arrays" do
        a = [1,2,3]
        b = %w{ a b c }

        expected = [a, b, a, b]
        input = readBinaryObject("arrayRef.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should not keep references of duplicate empty arrays unless the object_id matches" do
        a = []
        b = []
        a.should == b
        a.object_id.should_not == b.object_id
     
        expected = [a,b,a,b]
        input = readBinaryObject("emptyArrayRef.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should keep references of duplicate XML and XMLDocuments"
      it "should keep references of duplicate byte arrays"
      
      it "should deserialize a deep object graph with circular references" do
        parent = Hash.new
        child1 = Hash.new
        child1[:parent] = parent
        child1[:children] = []
        child2 = Hash.new
        child2[:parent] = parent
        child2[:children] = []
        parent[:parent] = nil
        parent[:children] = [child1, child2]
        
        expected = parent
        input = readBinaryObject("graphMember.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end

  end

  describe "request" do
    it "should handle requests from remote object" do
      expected = true
      input = readBinaryRequest("true.bin")
      output = AMF.deserializer.new().deserialize_request(input)
      output.should == expected
    end
  end
    
  end
  
end

