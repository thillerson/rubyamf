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
        s = "Hello World!"
        @message.write s
        expected_message = "#{ENCODED_STRING_MARKER}" << expected_encoded_header_for( s )
        expected_message << s
        @message.output_stream.should == expected_message
      end

      it "should serialize a symbol as a string" do
        @message.write :foo
        s = :foo.to_s
        expected_message = "#{ENCODED_STRING_MARKER}" << expected_encoded_header_for( s )
        expected_message << s
        @message.output_stream.should == expected_message
      end

      it "should serialize Dates and DateTimes" do
        d = DateTime.parse "1/1/1970" # should be 0 in unix epoch time
        expected_time_stamp = expected_double_value_for 0
        @message.write d
        @message.output_stream.should == "#{ENCODED_DATE_MARKER}#{ENCODED_LOW_BIT_OF_ONE}" << expected_time_stamp
        
        @message.output_stream.clear!
        
        d = Date.today
        expected_time_stamp = expected_double_value_for( d.strftime('%s').to_i * 1000 )
        @message.write d
        @message.output_stream.should == "#{ENCODED_DATE_MARKER}#{ENCODED_LOW_BIT_OF_ONE}" << expected_time_stamp
      end

      it "should serialize Times" do
        # should be 0 in unix epoch time
        t = Time.utc 1970, 1, 1, 0
        expected_time_stamp = expected_double_value_for 0
        @message.write t
        @message.output_stream.should == "#{ENCODED_DATE_MARKER}#{ENCODED_LOW_BIT_OF_ONE}" << expected_time_stamp
        
        @message.output_stream.clear!
        
        t = Time.new
        @message.write t
        expected_time_stamp = expected_double_value_for t.utc.to_f
        @message.output_stream.should == "#{ENCODED_DATE_MARKER}#{ENCODED_LOW_BIT_OF_ONE}" << expected_time_stamp
      end

      #BAH! Who sends XML over AMF?
      it "should serialize a REXML document"

      #BAH! Who sends XML over AMF?
      it "should serialize some Beautiful Soup"

    end

    describe "objects" do

      it "should serialize an unmapped object as a dynamic anonymous object" do
        # A non-mapped object is any object not explicitly mapped with a RubyAMF
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
      
        @message.write obj
        # can't depend on order, so match parts
        # open object
        @message.output_stream.should match(/^#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}.+/)
        # close object
        @message.output_stream.should match(/.*#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}$/)
        
        # encodable properties
        @message.output_stream.should match(/#{expected_encoded_string_for('property_one')}#{expected_encoded_string_for(obj.property_one)}/)
        @message.output_stream.should match(/#{expected_encoded_string_for('property_two')}#{ENCODED_INTEGER_MARKER}#{ENCODED_ONE}/)
        @message.output_stream.should match(/#{expected_encoded_string_for('another_public_property')}#{expected_encoded_string_for(obj.another_public_property)}/)
        @message.output_stream.should match(/#{expected_encoded_string_for('nil_property')}#{ENCODED_NULL_MARKER}/)
        
        # non-encodable properties
        @message.output_stream.should_not match(/#{expected_encoded_string_for('method_with_arg')}/)
        @message.output_stream.should_not match(/#{expected_encoded_string_for('read_only_prop')}/)
      end
      
      it "should serialize a hash as a dynamic anonymous object" do
        hash = {}
        hash[:foo] = "bar"
        hash[:answer] = 42
        
        @message.write hash
        # can't depend on order
        # open object
        @message.output_stream.should match(/^#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}.+/)
        # close object
        @message.output_stream.should match(/.*#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}$/)

        # encodable properties
        @message.output_stream.should match(/#{expected_encoded_string_for('foo')}#{expected_encoded_string_for(hash[:foo])}/)
        @message.output_stream.should match(/#{expected_encoded_string_for('answer')}#{ENCODED_INTEGER_MARKER}#{ENCODED_42}/)
      end
      
      it "should serialize an open struct as a dynamic anonymous object"
      
      it "should serialize an empty array" do
        a = []
        
        @message.write a
        encoded_array = "#{ENCODED_ARRAY_MARKER}"
        encoded_array << expected_encoded_header_for( a ) # U29A-value - a low byte of one and a 0 to denote the length of the array
        encoded_array << "#{ENCODED_NULL_MARKER}" #empty string ending dynamic portion (which is empty)
        
        @message.output_stream.should == encoded_array
      end
      
      it "should serialize an array of primatives" do
        a = [1, 2, 3, 4, 5]
        @message.write a
        encoded_array = "#{ENCODED_ARRAY_MARKER}"
        encoded_array << expected_encoded_header_for( a ) # U29A-value - a low byte of one and a 5 to denote the length of the array
        encoded_array << "#{ENCODED_NULL_MARKER}" #empty string ending dynamic portion (which is empty)
        # the encoded values of the array
        encoded_array << "#{ENCODED_INTEGER_MARKER}\001#{ENCODED_INTEGER_MARKER}\002#{ENCODED_INTEGER_MARKER}\003#{ENCODED_INTEGER_MARKER}\004#{ENCODED_INTEGER_MARKER}\005"

        @message.output_stream.should == encoded_array
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
        
        @message.write a
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
        
        @message.output_stream.should == encoded_array
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
        
        @message.write foo
        expected_message = expected_encoded_string_for( foo )

        @message.write bar
        expected_message << expected_encoded_string_for( bar )
        
        @message.write foo
        expected_message << expected_encoded_string_reference( 0 ) # first reference of Foo
        
        @message.write bar
        expected_message << expected_encoded_string_reference( 1 ) # first reference of Bar
        
        @message.write foo
        expected_message << expected_encoded_string_reference( 0 ) # second reference of Foo
        
        @message.write sc
        expected_message << "#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}"
        expected_message << "#{expected_encoded_string_for('str')}" << expected_encoded_string_reference( 0 ) # third reference of Foo
        expected_message << "#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}"
        
        @message.output_stream.should == expected_message
      end
      
      it "should not reference the empty string" do
        # AMF Spec 1.3.2: the empty string is never referenced
        empty = ""
        
        @message.write empty
        expected_message = "#{ENCODED_STRING_MARKER}#{ENCODED_EMPTY_STRING}"
        @message.write empty
        expected_message << "#{ENCODED_STRING_MARKER}#{ENCODED_EMPTY_STRING}"

        @message.output_stream.should == expected_message
      end
      
      it "should keep references of duplicate dates" do
        d = Date.today
        @message.write d
        expected_time_stamp = expected_double_value_for( d.strftime('%s').to_i * 1000 )
        expected_message = "#{ENCODED_DATE_MARKER}#{ENCODED_LOW_BIT_OF_ONE}" << expected_time_stamp
        @message.output_stream.should == expected_message
        
        @message.write d
        expected_message << "#{ENCODED_DATE_MARKER}" << expected_encoded_object_reference( 0 )
        @message.output_stream.should == expected_message

        d = Date.parse '12/31/1999'
        @message.write d
        expected_time_stamp = expected_double_value_for( d.strftime('%s').to_i * 1000 )
        expected_message << "#{ENCODED_DATE_MARKER}#{ENCODED_LOW_BIT_OF_ONE}" << expected_time_stamp
        @message.output_stream.should == expected_message
      end
      
      it "should keep reference of duplicate objects" do
        class SimpleReferenceableObj
          attr_accessor :foo
        end
        
        so1 = SimpleReferenceableObj.new
        so1.foo = 'bar'
        
        so2 = SimpleReferenceableObj.new
        so2.foo = 'baz'
        
        @message.write so1
        expected_message = "#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}"
        expected_message << "#{expected_encoded_string_for('foo')}#{expected_encoded_string_for('bar')}"
        expected_message << "#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}"
        
        @message.write so1
        expected_message << "#{ENCODED_OBJECT_MARKER}" << expected_encoded_object_reference( 0 ) # first reference of so1
        
        @message.write so2
        expected_message << "#{ENCODED_OBJECT_MARKER}#{ENCODED_DYNAMIC_OBJECT_MARKER}#{ENCODED_ANONYMOUS_OBJECT_MARKER}"
        expected_message << "#{expected_encoded_string_reference( 0 )}#{expected_encoded_string_for('baz')}" # foo is now a reference, the first
        expected_message << "#{ENCODED_CLOSE_DYNAMIC_OBJECT_MARKER}"

        @message.write so1
        expected_message << "#{ENCODED_OBJECT_MARKER}" << expected_encoded_object_reference( 0 ) # second reference of so1

        @message.write so2
        expected_message << "#{ENCODED_OBJECT_MARKER}" << expected_encoded_object_reference( 1 ) # first reference of so2

        @message.output_stream.should == expected_message
      end
      
      it "should keep references of duplicate arrays" do
        a = [1,2,3]
        b = %w{ a b c }
        
        @message.write a
        expected_message = "#{ENCODED_ARRAY_MARKER}"
        expected_message << expected_encoded_header_for( a ) # U29A-value - a low byte of one and a 3 to denote the length of the array
        expected_message << "#{ENCODED_NULL_MARKER}" #empty string ending dynamic portion (which is empty)
        # the encoded values of the array
        expected_message << "#{ENCODED_INTEGER_MARKER}\001#{ENCODED_INTEGER_MARKER}\002#{ENCODED_INTEGER_MARKER}\003"

        @message.write b
        expected_message << "#{ENCODED_ARRAY_MARKER}"
        expected_message << expected_encoded_header_for( b ) # U29A-value - a low byte of one and a 3 to denote the length of the array
        expected_message << "#{ENCODED_NULL_MARKER}" #empty string ending dynamic portion (which is empty)
        # the encoded values of the array
        expected_message << expected_encoded_string_for('a') << expected_encoded_string_for('b') << expected_encoded_string_for('c')
        
        @message.write a
        expected_message << "#{ENCODED_ARRAY_MARKER}" << expected_encoded_object_reference( 0 ) # first reference of a
        
        @message.write b
        expected_message << "#{ENCODED_ARRAY_MARKER}" << expected_encoded_object_reference( 1 ) # first reference of b
        
        @message.write a
        expected_message << "#{ENCODED_ARRAY_MARKER}" << expected_encoded_object_reference( 0 ) # second reference of a
        
        @message.output_stream.should == expected_message
      end
      
      it "should not keep references of duplicate empty arrays unless the object_id matches" do
        a = []
        b = []
        a.should == b
        a.object_id.should_not == b.object_id
      
        @message.write a
        expected_message = "#{ENCODED_ARRAY_MARKER}"
        expected_message << expected_encoded_header_for( a ) # U29A-value - a low byte of one and a 0 to denote the length of the array
        expected_message << "#{ENCODED_NULL_MARKER}" #empty string ending dynamic portion (which is empty)

        @message.write b
        expected_message << "#{ENCODED_ARRAY_MARKER}"
        expected_message << expected_encoded_header_for( b ) # U29A-value - a low byte of one and a 0 to denote the length of the array
        expected_message << "#{ENCODED_NULL_MARKER}" #empty string ending dynamic portion (which is empty)

        @message.write a
        expected_message << "#{ENCODED_ARRAY_MARKER}"
        expected_message << expected_encoded_object_reference( 0 ) # a reference to array a

        @message.write b
        expected_message << "#{ENCODED_ARRAY_MARKER}"
        expected_message << expected_encoded_object_reference( 1 ) # a reference to array b

        @message.output_stream.should == expected_message
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
        
        parent = GraphMember.new
        level_1_child_1 = parent.add_child GraphMember.new
        level_1_child_2 = parent.add_child GraphMember.new
        # level_2_child_1 = level_1_child_1.add_child GraphMember.new
        
        @message.write parent
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
          @message.output_stream.should == expected_message
        end
      end

    end
    
  end
  
end

