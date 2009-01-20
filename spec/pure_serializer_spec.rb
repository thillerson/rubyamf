require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/expected_values.rb'
require File.dirname(__FILE__) + '/amf_helpers.rb'

require 'date'
require 'rexml/document'
require 'rubygems'
require 'ruby-debug'

describe AMF do
  describe "when serializing" do
    describe "simple messages" do

      it "should serialize a null" do
        output = nil.to_amf
        output.should == ENCODED_NULL_MARKER
      end

      it "should serialize a false" do
        output = false.to_amf
        output.should == ENCODED_FALSE_MARKER
      end

      it "should serialize a true" do
        output = true.to_amf
        output.should == ENCODED_TRUE_MARKER
      end

      it "should serialize simple integers" do
        one = 1.to_amf
        one.should == "#{ENCODED_INTEGER_MARKER}#{ENCODED_ONE}"
        
        ten = 10.to_amf
        ten.should == "#{ENCODED_INTEGER_MARKER}#{ENCODED_TEN}"
      end

      it "should serialize a floating point number" do
        positive_float = 1.1
        output = positive_float.to_amf
        output.should == "#{ENCODED_DOUBLE_MARKER}" << expected_double_value_for( 1.1 )
      end

      it "should serialize a negative floating point number" do
        negative_float = -1.1
        output = negative_float.to_amf
        output.should == "#{ENCODED_DOUBLE_MARKER}" << expected_double_value_for( -1.1 )
      end

      it "should serialize large integers" do
        big_positive_int = MAX_INTEGER + 1
        output = big_positive_int.to_amf
        output.should == "#{ENCODED_DOUBLE_MARKER}" << expected_double_value_for( big_positive_int )
      end

      it "should serialize large negative integers" do
        big_negative_int = MIN_INTEGER - 1
        output = big_negative_int.to_amf
        output.should == "#{ENCODED_DOUBLE_MARKER}" << expected_double_value_for( big_negative_int )
      end
      
      it "should serialize BigNums" do
        bignum = 2**1000
        output = bignum.to_amf
        output.should == "#{ENCODED_DOUBLE_MARKER}" << expected_double_value_for( bignum )
      end
      
      it "should serialize BigDecimals" do
        bigdec = BigDecimal.new("1.2")
        output = bigdec.to_amf
        output.should == "#{ENCODED_DOUBLE_MARKER}" << expected_double_value_for( bigdec )
      end

      it "should serialize a simple string" do
        s = "Hello World!"
        output = s.to_amf
        expected_message = "#{ENCODED_STRING_MARKER}" << expected_encoded_header_for( s )
        expected_message << s
        output.should == expected_message
      end

      it "should serialize a symbol as a string" do
        output = :foo.to_amf
        s = :foo.to_s
        expected_message = "#{ENCODED_STRING_MARKER}" << expected_encoded_header_for( s )
        expected_message << s
        output.should == expected_message
      end

      it "should serialize Dates and DateTimes" do
        d = DateTime.parse "1/1/1970" # should be 0 in unix epoch time
        expected_time_stamp = expected_double_value_for 0
        first_date = d.to_amf
        first_date.should == "#{ENCODED_DATE_MARKER}#{ENCODED_LOW_BIT_OF_ONE}" << expected_time_stamp

        d = Date.today
        expected_time_stamp = expected_double_value_for( d.strftime('%s').to_i * 1000 )
        second_date = d.to_amf
        second_date.should == "#{ENCODED_DATE_MARKER}#{ENCODED_LOW_BIT_OF_ONE}" << expected_time_stamp
      end

      it "should serialize Times" do
        # should be 0 in unix epoch time
        t = Time.utc 1970, 1, 1, 0
        expected_time_stamp = expected_double_value_for 0
        first_time = t.to_amf
        first_time.should == "#{ENCODED_DATE_MARKER}#{ENCODED_LOW_BIT_OF_ONE}" << expected_time_stamp

        t = Time.new
        second_time = t.to_amf
        expected_time_stamp = expected_double_value_for t.utc.to_f
        second_time.should == "#{ENCODED_DATE_MARKER}#{ENCODED_LOW_BIT_OF_ONE}" << expected_time_stamp
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
      
        output = obj.to_amf
        # can't depend on order, so match parts
        # open object
        output.should match(/^#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}.+/)
        # close object
        output.should match(/.*#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}$/)
        
        # encodable properties
        output.should match(/#{expected_encoded_string_for('property_one')}#{expected_encoded_string_for(obj.property_one)}/)
        output.should match(/#{expected_encoded_string_for('property_two')}#{ENCODED_INTEGER_MARKER}#{ENCODED_ONE}/)
        output.should match(/#{expected_encoded_string_for('another_public_property')}#{expected_encoded_string_for(obj.another_public_property)}/)
        output.should match(/#{expected_encoded_string_for('nil_property')}#{ENCODED_NULL_MARKER}/)
        
        # non-encodable properties
        output.should_not match(/#{expected_encoded_string_for('method_with_arg')}/)
        output.should_not match(/#{expected_encoded_string_for('read_only_prop')}/)
      end
      
      it "should serialize a hash as a dynamic anonymous object" do
        hash = {}
        hash[:foo] = "bar"
        hash[:answer] = 42
        
        output = hash.to_amf
        # can't depend on order
        # open object
        output.should match(/^#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}.+/)
        # close object
        output.should match(/.*#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}$/)

        # encodable properties
        output.should match(/#{expected_encoded_string_for('foo')}#{expected_encoded_string_for(hash[:foo])}/)
        output.should match(/#{expected_encoded_string_for('answer')}#{ENCODED_INTEGER_MARKER}#{ENCODED_42}/)
      end
      
      it "should serialize an open struct as a dynamic anonymous object"
      
      it "should serialize an empty array" do
        a = []
        
        output = a.to_amf
        encoded_array = "#{ENCODED_ARRAY_MARKER}"
        encoded_array << expected_encoded_header_for( a ) # U29A-value - a low byte of one and a 0 to denote the length of the array
        encoded_array << "#{ENCODED_NULL_MARKER}" #empty string ending dynamic portion (which is empty)
        
        output.should == encoded_array
      end
      
      it "should serialize an array of primatives" do
        a = [1, 2, 3, 4, 5]
        output = a.to_amf
        encoded_array = "#{ENCODED_ARRAY_MARKER}"
        encoded_array << expected_encoded_header_for( a ) # U29A-value - a low byte of one and a 5 to denote the length of the array
        encoded_array << "#{ENCODED_NULL_MARKER}" #empty string ending dynamic portion (which is empty)
        # the encoded values of the array
        encoded_array << "#{ENCODED_INTEGER_MARKER}\001#{ENCODED_INTEGER_MARKER}\002#{ENCODED_INTEGER_MARKER}\003#{ENCODED_INTEGER_MARKER}\004#{ENCODED_INTEGER_MARKER}\005"

        output.should == encoded_array
      end
      
      it "should serialize an array of mixed objects" do
        
        h1 = {:foo_one => "bar_one"}
        h2 = {:foo_two => "bar_two"}
        class SimpleObj
          attr_accessor :foo_three
        end
        so = SimpleObj.new
        so.foo_three = 42
        a = [h1, h2, so]
        
        output = a.to_amf
        encoded_array = "#{ENCODED_ARRAY_MARKER}"
        encoded_array << expected_encoded_header_for( a ) # U29A-value - a low byte of one and a 3 to denote the length of the array
        encoded_array << "#{ENCODED_NULL_MARKER}" #empty string ending dynamic portion (which is empty)
        # the encoded values of the array
        # h1
        encoded_array << "#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}"
        encoded_array << "#{expected_encoded_string_for('foo_one')}#{expected_encoded_string_for('bar_one')}"
        encoded_array << "#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}"
        # h2
        encoded_array << "#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}"
        encoded_array << "#{expected_encoded_string_for('foo_two')}#{expected_encoded_string_for('bar_two')}"
        encoded_array << "#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}"
        # so
        encoded_array << "#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}"
        encoded_array << "#{expected_encoded_string_for('foo_three')}#{ENCODED_INTEGER_MARKER}#{ENCODED_42}"
        encoded_array << "#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}"
        
        output.should == encoded_array
      end

      it "should serialize a byte array"

    end

    describe "and implementing the AMF Spec" do

      it "should keep references of duplicate strings" do
        class StringCarrier
          attr_accessor :str
        end
        
        foo = "Foo"
        bar = "Bar"
        sc = StringCarrier.new
        sc.str = foo
        
        state = AMF::Pure::Serializer::State.new
        
        output = foo.to_amf(state)
        expected_message = expected_encoded_string_for( foo )

        output << bar.to_amf(state)
        expected_message << expected_encoded_string_for( bar )
        
        output << foo.to_amf(state)
        expected_message << expected_encoded_string_reference( 0 ) # first reference of Foo
        
        output << bar.to_amf(state)
        expected_message << expected_encoded_string_reference( 1 ) # first reference of Bar
        
        output << foo.to_amf(state)
        expected_message << expected_encoded_string_reference( 0 ) # second reference of Foo
        
        output << sc.to_amf(state)
        expected_message << "#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}"
        expected_message << "#{expected_encoded_string_for('str')}" << expected_encoded_string_reference( 0 ) # third reference of Foo
        expected_message << "#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}"
        
        output.should == expected_message
      end
      
      it "should not reference the empty string" do
        # AMF Spec 1.3.2: the empty string is never referenced
        empty = ""
        
        state = AMF::Pure::Serializer::State.new
        
        output = empty.to_amf(state)
        expected_message = "#{ENCODED_STRING_MARKER}#{ENCODED_EMPTY_STRING}"
        output << empty.to_amf(state)
        expected_message << "#{ENCODED_STRING_MARKER}#{ENCODED_EMPTY_STRING}"

        output.should == expected_message
      end
      
      it "should keep references of duplicate dates" do
        d = Date.today
        state = AMF::Pure::Serializer::State.new
        
        output = d.to_amf(state)
        expected_time_stamp = expected_double_value_for( d.strftime('%s').to_i * 1000 )
        expected_message = "#{ENCODED_DATE_MARKER}#{ENCODED_LOW_BIT_OF_ONE}" << expected_time_stamp
        output.should == expected_message
        
        output << d.to_amf(state)
        expected_message << "#{ENCODED_DATE_MARKER}" << expected_encoded_object_reference( 0 )
        output.should == expected_message

        d = Date.parse '12/31/1999'
        output << d.to_amf(state)
        expected_time_stamp = expected_double_value_for( d.strftime('%s').to_i * 1000 )
        expected_message << "#{ENCODED_DATE_MARKER}#{ENCODED_LOW_BIT_OF_ONE}" << expected_time_stamp
        output.should == expected_message
      end
      
      it "should keep reference of duplicate objects" do
        class SimpleReferenceableObj
          attr_accessor :foo
        end
        
        so1 = SimpleReferenceableObj.new
        so1.foo = 'bar'
        
        so2 = SimpleReferenceableObj.new
        so2.foo = 'baz'
        
        state = AMF::Pure::Serializer::State.new
        
        output = so1.to_amf(state)
        expected_message = "#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}"
        expected_message << "#{expected_encoded_string_for('foo')}#{expected_encoded_string_for('bar')}"
        expected_message << "#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}"
        
        output << so1.to_amf(state)
        expected_message << "#{ENCODED_OBJECT_MARKER}" << expected_encoded_object_reference( 0 ) # first reference of so1
        
        output << so2.to_amf(state)
        expected_message << "#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}"
        expected_message << "#{expected_encoded_string_for('foo')}#{expected_encoded_string_for('baz')}" # foo is now a reference, the first
        expected_message << "#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}"

        output << so1.to_amf(state)
        expected_message << "#{ENCODED_OBJECT_MARKER}" << expected_encoded_object_reference( 0 ) # second reference of so1

        output << so2.to_amf(state)
        expected_message << "#{ENCODED_OBJECT_MARKER}" << expected_encoded_object_reference( 1 ) # first reference of so2

        output.should == expected_message
      end
      
      it "should keep references of duplicate arrays" do
        a = [1,2,3]
        b = %w{ a b c }
        
        state = AMF::Pure::Serializer::State.new
        
        output = a.to_amf(state)
        expected_message = "#{ENCODED_ARRAY_MARKER}"
        expected_message << expected_encoded_header_for( a ) # U29A-value - a low byte of one and a 3 to denote the length of the array
        expected_message << "#{ENCODED_NULL_MARKER}" #empty string ending dynamic portion (which is empty)
        # the encoded values of the array
        expected_message << "#{ENCODED_INTEGER_MARKER}\001#{ENCODED_INTEGER_MARKER}\002#{ENCODED_INTEGER_MARKER}\003"

        output << b.to_amf(state)
        expected_message << "#{ENCODED_ARRAY_MARKER}"
        expected_message << expected_encoded_header_for( b ) # U29A-value - a low byte of one and a 3 to denote the length of the array
        expected_message << "#{ENCODED_NULL_MARKER}" #empty string ending dynamic portion (which is empty)
        # the encoded values of the array
        expected_message << expected_encoded_string_for('a') << expected_encoded_string_for('b') << expected_encoded_string_for('c')
        
        output << a.to_amf(state)
        expected_message << "#{ENCODED_ARRAY_MARKER}" << expected_encoded_object_reference( 0 ) # first reference of a
        
        output << b.to_amf(state)
        expected_message << "#{ENCODED_ARRAY_MARKER}" << expected_encoded_object_reference( 1 ) # first reference of b
        
        output << a.to_amf(state)
        expected_message << "#{ENCODED_ARRAY_MARKER}" << expected_encoded_object_reference( 0 ) # second reference of a
        
        output.should == expected_message
      end
      
      it "should not keep references of duplicate empty arrays unless the object_id matches" do
        a = []
        b = []
        a.should == b
        a.object_id.should_not == b.object_id
      
        state = AMF::Pure::Serializer::State.new
      
        output = a.to_amf(state)
        expected_message = "#{ENCODED_ARRAY_MARKER}"
        expected_message << expected_encoded_header_for( a ) # U29A-value - a low byte of one and a 0 to denote the length of the array
        expected_message << "#{ENCODED_NULL_MARKER}" #empty string ending dynamic portion (which is empty)

        output << b.to_amf(state)
        expected_message << "#{ENCODED_ARRAY_MARKER}"
        expected_message << expected_encoded_header_for( b ) # U29A-value - a low byte of one and a 0 to denote the length of the array
        expected_message << "#{ENCODED_NULL_MARKER}" #empty string ending dynamic portion (which is empty)

        output << a.to_amf(state)
        expected_message << "#{ENCODED_ARRAY_MARKER}"
        expected_message << expected_encoded_object_reference( 0 ) # a reference to array a

        output << b.to_amf(state)
        expected_message << "#{ENCODED_ARRAY_MARKER}"
        expected_message << expected_encoded_object_reference( 1 ) # a reference to array b

        output.should == expected_message
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
        
        state = AMF::Pure::Serializer::State.new
        
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

