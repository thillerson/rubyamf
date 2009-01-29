require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/expected_values.rb'
require File.dirname(__FILE__) + '/amf_helpers.rb'

require 'date'
require 'rexml/document'
require 'rubygems'
require 'ruby-debug'

describe AMF do
  describe "when serializing" do
    
    def readBinary(binary_path)
      File.open('spec/fixtures/objects/' + binary_path).read
    end
    
    describe "simple messages" do
      
      it "should serialize a null" do
        expected = readBinary("null.bin")
        output = nil.to_amf
        output.should == expected
      end

      it "should serialize a false" do
        expected = readBinary("false.bin")
        output = false.to_amf
        output.should == expected
      end

      it "should serialize a true" do
        expected = readBinary("true.bin")
        output = true.to_amf
        output.should == expected
      end

      it "should serialize integers" do
        expected = readBinary("max.bin")
        input = MAX_INTEGER
        output = input.to_amf
        output.should == expected
        
        expected = readBinary("0.bin")
        output = 0.to_amf
        output.should == expected
        
        expected = readBinary("min.bin")
        input = MIN_INTEGER
        output = input.to_amf
        output.should == expected
      end
      
      it "should serialize large integers" do
        expected = readBinary("largeMax.bin")
        input = MAX_INTEGER + 1
        output = input.to_amf
        output.should == expected
        
        expected = readBinary("largeMin.bin")
        input = MIN_INTEGER - 1
        output = input.to_amf
        output.should == expected
      end
      
      it "should serialize BigNums" do
        expected = readBinary("bigNum.bin")
        input = 2**1000
        output = input.to_amf
        output.should == expected
      end

      it "should serialize a simple string" do
        expected = readBinary("string.bin")
        input = "String . String"
        output = input.to_amf
        output.should == expected
      end

      it "should serialize a symbol as a string" do
        expected = readBinary("symbol.bin")
        output = :foo.to_amf
        output.should == expected
      end

      it "should serialize DateTimes" do
        expected = readBinary("date.bin")
        input = DateTime.parse "1/1/1970"
        output = input.to_amf
        output.should == expected
        
        #input = DateTime.new
        #output = input.to_amf
        #output.should == expected
      end
      
      it "should serialize Dates" do
        expected = readBinary("date.bin")
        input = Date.parse "1/1/1970"
        output = input.to_amf
        output.should == expected
        
        #input = Date.new
        #output = input.to_amf
        #output.should == expected
      end

      it "should serialize Times" do
        expected = readBinary("date.bin")
        input = Time.utc 1970, 1, 1, 0
        output = input.to_amf
        output.should == expected

        #input = Time.new
        #output = input.to_amf
        #output.should == expected
      end

      #BAH! Who sends XML over AMF?
      it "should serialize a REXML document"
    end

    describe "objects" do

      it "should serialize an unmapped object as a dynamic anonymous object" do
        # A non-mapped object is any object not explicitly mapped with a AMF
        # mapping. It should be encoded as a dynamic anonymous object with 
        # dynamic properties for all "messages" (public methods)
        # that have an arity of 0 - meaning that they take no arguments
        class NonMappedObject
          attr_accessor :property_one
          attr_accessor :property_two
          attr_accessor :nil_property
          attr_writer :read_only_prop

          def another_public_property
            'a_public_value'
          end

          def method_with_arg arg='foo'
            arg
          end
        end
        obj = NonMappedObject.new
        obj.property_one = 'foo'
        obj.property_two = 1
        obj.nil_property = nil
        
        #expected = readBinary("dynObject.bin")
        
        output = obj.to_amf
        # can't depend on order, so match parts
        # open object
        output.should match(/^#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}.+/)
        # close object
        output.should match(/.*#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}$/)
        
        # encodable properties
        output.should match(/#{expected_encoded_string_for('property_one', false)}#{expected_encoded_string_for(obj.property_one)}/)
        output.should match(/#{expected_encoded_string_for('property_two', false)}#{ENCODED_INTEGER_MARKER}#{ENCODED_ONE}/)
        output.should match(/#{expected_encoded_string_for('another_public_property', false)}#{expected_encoded_string_for(obj.another_public_property)}/)
        output.should match(/#{expected_encoded_string_for('nil_property', false)}#{ENCODED_NULL_MARKER}/)
        
        # non-encodable properties
        output.should_not match(/#{expected_encoded_string_for('method_with_arg')}/)
        output.should_not match(/#{expected_encoded_string_for('read_only_prop')}/)
      end
      
      it "should serialize a hash as a dynamic anonymous object" do
        hash = {}
        hash[:foo] = "bar"
        hash[:answer] = 42
        
        #expected = readBinary("hash.bin")
        
        output = hash.to_amf
        # can't depend on order
        # open object
        output.should match(/^#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}.+/)
        # close object
        output.should match(/.*#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}$/)

        # encodable properties
        output.should match(/#{expected_encoded_string_for('foo', false)}#{expected_encoded_string_for(hash[:foo])}/)
        output.should match(/#{expected_encoded_string_for('answer', false)}#{ENCODED_INTEGER_MARKER}#{ENCODED_42}/)
      end
      
      it "should serialize an open struct as a dynamic anonymous object"
      
      it "should serialize an empty array" do
        expected = readBinary("emptyArray.bin")
        input = []
        output = input.to_amf
        output.should == expected
      end
      
      it "should serialize an array of primatives" do
        expected = readBinary("primArray.bin")
        input = [1, 2, 3, 4, 5]
        output = input.to_amf
        output.should == expected
      end
      
      it "should serialize an array of mixed objects" do
        h1 = {:foo_one => "bar_one"}
        h2 = {:foo_two => ""}
        class SimpleObj
          attr_accessor :foo_three
        end
        so1 = SimpleObj.new
        so1.foo_three = 42
        
        expected = readBinary("mixedArray.bin")
        input = [h1, h2, so1, SimpleObj.new, {}, [h1, h2, so1], [], 42, "", [], "", {}, "bar_one", so1]    
        output = input.to_amf
        output.should == expected
      end

      it "should serialize a byte array"

    end

    describe "and implementing the AMF Spec" do

      it "should keep references of duplicate strings" do
        class StringCarrier
          attr_accessor :str
        end       
        foo = "foo"
        bar = "str"
        sc = StringCarrier.new
        sc.str = foo
        
        expected = readBinary("stringRef.bin")
        input = [foo, bar, foo, bar, foo, sc]
        output = input.to_amf
        output.should == expected
      end
      
      it "should not reference the empty string" do
        expected = readBinary("emptyStringRef.bin")
        input = ""
        output = [input,input].to_amf
        output.should == expected
      end
      
      it "should keep references of duplicate dates" do
        expected = readBinary("datesRef.bin")
        input = Date.parse "1/1/1970"
        output = [input,input].to_amf
        output.should == expected
      end
      
      it "should keep reference of duplicate objects" do
        class SimpleReferenceableObj
          attr_accessor :foo
        end
        obj1 = SimpleReferenceableObj.new
        obj1.foo = :foo
        obj2 = SimpleReferenceableObj.new
        obj2.foo = obj1.foo
        
        expected = readBinary("objRef.bin") 
        input = [[obj1, obj2], "bar", [obj1, obj2]]
        output = input.to_amf
        output.should == expected
      end
      
      it "should keep references of duplicate arrays" do
        a = [1,2,3]
        b = %w{ a b c }

        expected = readBinary("arrayRef.bin")
        input = [a, b, a, b]
        output = input.to_amf
        output.should == expected
      end
      
      it "should not keep references of duplicate empty arrays unless the object_id matches" do
        a = []
        b = []
        a.should == b
        a.object_id.should_not == b.object_id
     
        expected = readBinary("emptyArrayRef.bin")
        input = [a,b,a,b]
        output = input.to_amf
        output.should == expected
      end
      
      it "should keep references of duplicate XML and XMLDocuments"
      it "should keep references of duplicate byte arrays"
      
      it "should serialize a deep object graph with circular references" do
        
        class GraphMember
          attr_accessor :parent
          attr_accessor :children
          
          def initialize
            self.children = []
          end
          
          def add_child child
            children << child
            child.parent = self
            child
          end
          
        end
        
        #expected = readBinary("graphMember.bin")
        
        state = AMF.state.new
        
        parent = GraphMember.new
        level_1_child_1 = parent.add_child GraphMember.new
        level_1_child_2 = parent.add_child GraphMember.new
        # level_2_child_1 = level_1_child_1.add_child GraphMember.new
        
        output = parent.to_amf(state)
        expected_message = "#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}" # parent, obj ref 0
        expected_message << expected_encoded_string_for('children') << ENCODED_ARRAY_MARKER # obj ref 1
        expected_message << expected_encoded_header_for( parent.children ) << ENCODED_NULL_MARKER # header and empty dynamic portion
          # start of level_1_child_1
          expected_message << "#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}" # obj ref 2
          expected_message << expected_encoded_string_reference( 0 ) << ENCODED_ARRAY_MARKER # reference to 'children' which is an array, obj ref 3
          expected_message << expected_encoded_header_for( level_1_child_1.children ) << ENCODED_NULL_MARKER # header and empty dynamic portion
          expected_message << expected_encoded_string_for( 'parent' )
          expected_message << ENCODED_OBJECT_MARKER << expected_encoded_object_reference( 0 ) # first reference of parent object
          expected_message << ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER

          # start of level_1_child_2
          expected_message << "#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}" # obj ref 4
          expected_message << expected_encoded_string_reference( 0 ) << ENCODED_ARRAY_MARKER # reference to 'children' which is an array, obj ref 5
          expected_message << expected_encoded_header_for( level_1_child_2.children ) << ENCODED_NULL_MARKER # header and empty dynamic portion
          expected_message << expected_encoded_string_reference( 1 ) # reference to 'parent'
          expected_message << ENCODED_OBJECT_MARKER << expected_encoded_object_reference( 0 ) # reference to parent object
          expected_message << ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER
          
        expected_message << expected_encoded_string_reference( 1 ) << ENCODED_NULL_MARKER # reference to 'parent', which is null
        expected_message << ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER # end of parent object
        
        pending do
          violated "need to account for inconsistent ordering of object attributes by ruby in test"
          output.should == expected_message
        end
      end

    end
    
  end
  
end

