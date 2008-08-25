require 'bigdecimal'

class NilClass
  def write_amf(message)
    message.write_null
  end
end

class FalseClass
  def write_amf(message)
    message.write_false
  end
end

class TrueClass
  def write_amf(message)
    message.write_true
  end
end

class Bignum
  def write_amf(message)
    message.write_double(self)
  end
end

class Integer
  def write_amf(message)
    message.write_number(self)
  end
end

class Float
  def write_amf(message)
    message.write_double(self)
  end
end

class BigDecimal
  def write_amf(message)
  	message.write_double(self.to_f)
  end
end

class String
  def write_amf(message)
    message.write_string(self)
  end
end

class Array
  def write_amf(message)
    message.write_array(self)
  end
end

class Hash
  def write_amf(message)
    message.write_object(self)
  end
end

class Time
  def write_amf(message)
    message.write_date(self)
  end
end

class Date
  def write_amf(message)
    message.write_date(self)
  end
end

class Object
  def write_amf(message)
    message.write_object(self)
  end
end

class BeautifulSoup
  def write_amf(message)
    message.output_stream << RubyAMF::Constants::XML
    message.write_xml(self)
  end
end

module REXML
  class Document
    def write_amf(message)
      message.output_stream << RubyAMF::Constants::XML
      message.write_xml(self)
    end
  end
end