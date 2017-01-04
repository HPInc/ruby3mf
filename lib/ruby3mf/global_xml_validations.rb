require 'benchmark'

class GlobalXMLValidations

  def self.validate(document)
    Log3mf.context "global xml validations" do |l|
      if space_attribute_exists?(document)
        l.error "found an xml:space attribute when it is not allowed", page: 16
      end
    end
  end

  def self.space_attribute_exists?(document)
    # using double negation as it's O(1) rather than the O(n) of .any?
    !document.xpath('//*[@xml:space]').empty?
  end

end





