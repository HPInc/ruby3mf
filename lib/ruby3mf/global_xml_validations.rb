class GlobalXMLValidations

  def self.validate(document)
    Log3mf.context "global xml validations" do |l|
      if space_attribute_exists?(document)
        l.error "found an xml:space attribute when it is not allowed", page: 16
      end

      if xml_not_utf8_encoded?(document)
        l.error "found XML content that was not UTF8 encoded", page: 15
      end
    end
  end

  def self.space_attribute_exists?(document)
    # using double negation as it's O(1) rather than the O(n) of .any?
    !document.xpath('//*[@xml:space]').empty?
  end

  def self.xml_not_utf8_encoded?(document)
    if document.encoding == 'UTF-8'
      return false
    end
    true
  end

end





