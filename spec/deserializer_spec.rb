require File.dirname(__FILE__) + '/spec_helper.rb'

describe AMF do
  describe "when deserializing" do 
    
    #Expected Values    
    null = nil
    max = AMF::MAX_INTEGER
    min = AMF::MIN_INTEGER
    largeMax = max + 1
    largeMin = min - 1
    bigNum = 2**1000
    string = "String . String"
    symbol = "foo"
    dateTime = DateTime.parse "1/1/1970"
    dynObject = {:property_one => 'foo', 
                 :property_two => 1, 
                 :nil_property => nil, 
                 :another_public_property => 'a_public_value'}
    hash = {:foo => "bar", :answer => 42}
    emptyArray = []
    primArray = [1,2,3,4,5]
    
    #Mixed Aray
    def mixedArray
      h1 = {:foo_one => "bar_one"}
      h2 = {:foo_two => ""}
      so1 = {:foo_three => 42}
      [h1, h2, so1, {:foo_three => nil}, {}, [h1, h2, so1], [], 42, "", [], "", {}, "bar_one", so1] 
    end
    
    #String Reference
    class StringCarrier
      attr_accessor :str
    end  
    def stringRef
      foo = "foo"
      bar = "str"
      sc = StringCarrier.new
      sc = {:str => foo}
      [foo, bar, foo, bar, foo, sc]
    end
    
    emptyStringRef = ["",""]
    datesRef = [dateTime, dateTime]
    
    #Object Reference
    def objRef
      obj1 = {:foo => "bar"}
      obj2 = {:foo => obj1[:foo]}
      [[obj1, obj2], "bar", [obj1, obj2]]
    end
    
    #Array Reference
    def arrayRef
      a = [1,2,3]
      b = %w{ a b c }
      [a, b, a, b]
    end
    
    #Empty Array Reference
    def emptyArrayRef
      a = []
      b = []
      [a,b,a,b]
    end
    
    #Graph Member
    def graphMember
      parent = Hash.new
      child1 = Hash.new
      child1[:parent] = parent
      child1[:children] = []
      child2 = Hash.new
      child2[:parent] = parent
      child2[:children] = []
      parent[:parent] = nil
      parent[:children] = [child1, child2]
      parent
    end
    
    #File Utilities
    def readBinaryObject(binary_path)
      File.open('spec/fixtures/objects/' + binary_path).read
    end
    
    def readBinaryRequest(binary_path)
      File.open('spec/fixtures/request/' + binary_path).read
    end
    
    describe "simple messages" do
      
      it "should deserialize a null" do  
        expected = null
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
        expected = max
        input = readBinaryObject("max.bin")
        output = AMF.deserialize(input)
        output.should == expected
        
        expected = 0
        input = readBinaryObject("0.bin")
        output = AMF.deserialize(input)
        output.should == expected
        
        expected = min
        input = readBinaryObject("min.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should deserialize large integers" do
        expected = largeMax
        input = readBinaryObject("largeMax.bin")
        output = AMF.deserialize(input)
        output.should == expected
        
        expected = largeMin
        input = readBinaryObject("largeMin.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should deserialize BigNums" do
        expected = bigNum
        input = readBinaryObject("bigNum.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end

      it "should deserialize a simple string" do
        expected = string
        input = readBinaryObject("string.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end

      it "should deserialize a symbol as a string" do
        expected = symbol
        input = readBinaryObject("symbol.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end

      it "should deserialize DateTimes" do
        expected = dateTime
        input = readBinaryObject("date.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end

      #BAH! Who sends XML over AMF?
      it "should deserialize a REXML document"
    end

    describe "objects" do

      it "should deserialize an unmapped object as a dynamic anonymous object" do      
        expected = dynObject
        input = readBinaryObject("dynObject.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should deserialize a hash as a dynamic anonymous object" do        
        #need to account for order
        expected = hash
        input = readBinaryObject("hash.bin")
        output = AMF.deserialize(input)
        output.should == expected     
      end
      
      it "should deserialize an open struct as a dynamic anonymous object"
      
      it "should deserialize an empty array" do
        expected = emptyArray
        input = readBinaryObject("emptyArray.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should deserialize an array of primatives" do
        expected = primArray
        input = readBinaryObject("primArray.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should deserialize an array of mixed objects" do
        expected = mixedArray  
        input = readBinaryObject("mixedArray.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end

      it "should deserialize a byte array"

    end

    describe "and implementing the AMF Spec" do

      it "should keep references of duplicate strings" do
        expected = stringRef
        input = readBinaryObject("stringRef.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should not reference the empty string" do
        expected = emptyStringRef
        input = readBinaryObject("emptyStringRef.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should keep references of duplicate dates" do
        expected = datesRef
        input = readBinaryObject("datesRef.bin")
        output = AMF.deserialize(input)
        
        output[0].should equal(output[1])
      end
      
      it "should keep reference of duplicate objects" do
        expected = objRef
        input = readBinaryObject("objRef.bin") 
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should keep references of duplicate arrays" do
        expected = arrayRef
        input = readBinaryObject("arrayRef.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should not keep references of duplicate empty arrays unless the object_id matches" do
        expected = emptyArrayRef
        input = readBinaryObject("emptyArrayRef.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
      
      it "should keep references of duplicate XML and XMLDocuments"
      it "should keep references of duplicate byte arrays"
      
      it "should deserialize a deep object graph with circular references" do
        expected = graphMember
        input = readBinaryObject("graphMember.bin")
        output = AMF.deserialize(input)
        output.should == expected
      end
    end

    describe "request" do
      it "should handle remoting message from remote object" do
        expected = true
        input = readBinaryRequest("remotingMessage.bin")
        output = AMF.deserializer.new().deserialize_request(input)
        output[:body][0].should == expected
      end
      
      it "should handle command message from remote object" do
        expected = true
        input = readBinaryRequest("commandMessage.bin")
        output = AMF.deserializer.new().deserialize_request(input)
        output[:body][0].should == nil
      end
    end

  end  
end

