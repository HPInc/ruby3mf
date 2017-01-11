require 'nokogiri'

class Parser < Nokogiri::XML::SAX::Document
  def start_element(name, attrs = [])
    attributes = Hash[*attrs.flatten]
    p attributes
    attributes.values.each do |value|
      raise "Wrong floating value" if GlobalXMLValidations.bad_floating_number?(value)
    end
  end

  def characters(string)
  end

  def end_element(name)
  end
end

parser = Nokogiri::XML::SAX::Parser.new(Parser.new)
parser.parse(File.open("ruby3mf-testfiles/realworld/Ear_Mug_Vulcan_Edition_keyboard/3D/3dmodel.model"))

class GlobalXMLValidations

  def self.validate_parse(file)
    doc = Nokogiri::XML(file.get_input_stream) do |config|
      config.strict.nonet.noblanks
    end
    validate(file, doc)
    doc
  end

  def self.validate(file, document)
    Log3mf.context "global xml validations" do |l|
      l.error "locale should be en-US or floating point formating is invalid"        if invalid_locale?(document) || bad_floating_numbers?(document)
      l.error :has_xml_space_attribute        if space_attribute_exists?(document)
      l.error :wrong_encoding                 if xml_not_utf8_encoded?(document)
      l.error :dtd_not_allowed                if dtd_exists?(file)
    end
  end

  def self.invalid_locale?(document)
    !document.xpath('//@xml:lang').empty? && document.xpath('//@xml:lang').text != "en-US"
  end

  def self.bad_floating_numbers?(document)
    vertices = document.at_css('vertices').to_s
    bad_decimal = /[0-9]+\,[0-9]+/i
    vertices =~ bad_decimal
  end

  def self.bad_floating_number?(value)
    bad_decimal = /[0-9]+\,[0-9]+/i
    value =~ bad_decimal
  end

  def self.space_attribute_exists?(document)
    !(document.xpath('//*[@xml:space]').empty?)
  end

  def self.xml_not_utf8_encoded?(document)
    document.encoding.to_s.downcase != 'utf-8'
  end

  def self.dtd_exists?(file)
    found = file.get_input_stream.find { |line| line =~ /(!DOCTYPE\b)|(!ELEMENT\b)|(!ENTITY\b)|(!NOTATION\b)|(!ATTLIST\b)/ }
    !found.nil?
  end
end
