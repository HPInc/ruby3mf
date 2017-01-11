require 'nokogiri'

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
      l.error :invalid_language_locale        if invalid_locale?(document) 
      l.error :has_xml_space_attribute        if space_attribute_exists?(document)
      l.error :wrong_encoding                 if xml_not_utf8_encoded?(document)
      l.error :dtd_not_allowed                if dtd_exists?(file)
      l.error :has_commas_for_floats          if bad_floating_numbers?(document)
    end
  end

  def self.invalid_locale?(document)
    !document.xpath('//@xml:lang').empty? && document.xpath('//@xml:lang').text != "en-US"
  end

  def self.bad_floating_numbers?(document)
    !document.xpath('.//*[find_with_regex(., "[0-9]+\,[0-9]+")]', Class.new {
      def find_with_regex node_set, regex
        node_set.find_all { |node| node.values.any? {|v| v =~ /#{regex}/  } }
      end
    }.new).empty?
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
