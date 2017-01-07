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
      l.error :has_xml_space_attribute if space_attribute_exists?(document)
      l.error :wrong_encoding if xml_not_utf8_encoded?(document)
      l.error :dtd_not_allowed if dtd_exists?(file)
    end
  end

  def self.space_attribute_exists?(document)
    !(document.xpath('//*[@xml:space]').empty?)
  end

  def self.xml_not_utf8_encoded?(document)
    !(document.encoding == 'UTF-8' || document.encoding == 'utf-8')
  end

  def self.dtd_exists?(file)
    found = file.get_input_stream.find { |line| line =~ /(!DOCTYPE\b)|(!ELEMENT\b)|(!ENTITY\b)|(!NOTATION\b)|(!ATTLIST\b)/ }
    !found.nil?
  end
end





