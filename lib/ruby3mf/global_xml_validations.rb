class GlobalXMLValidations

  def self.validate_parse(file)
    doc = Nokogiri::XML(file.get_input_stream) do |config|
      config.strict.nonet.noblanks
    end
    validate(doc)
    doc
  end

  def self.validate(document)
    Log3mf.context "global xml validations" do |l|
      l.error "found an xml:space attribute when it is not allowed", page: 16 if space_attribute_exists?(document)
      l.error "found XML content that was not UTF8 encoded", page: 15 if xml_not_utf8_encoded?(document)
    end
  end

  def self.space_attribute_exists?(document)
    !(document.xpath('//*[@xml:space]').empty?)
  end

  def self.xml_not_utf8_encoded?(document)
    !(document.encoding == 'UTF-8' || document.encoding == 'utf-8')
  end
end





