require 'nokogiri'

class XmlVal

  def self.validate_parse(xml_file, schema_name=nil)
    doc = Nokogiri::XML(xml_file.get_input_stream) do |config|
      config.strict.nonet.noblanks
    end
    validate(xml_file, doc, schema_name)
    doc
  end

  def self.validate(file, document, schema_filename=nil)
    Log3mf.context "validations" do |l|
      l.error   :has_xml_space_attribute        if space_attribute_exists?(document)
      l.error   :wrong_encoding                 if xml_not_utf8_encoded?(document)
      l.error   :dtd_not_allowed                if dtd_exists?(file)
      l.error   :has_commas_for_floats          if bad_floating_numbers?(document)
      l.warning :missing_object_reference       if objects_not_referenced?(document)

      # if schema_filename
      #   Log3mf.context "validating core schema" do |l|
      #     xsd = Nokogiri::XML::Schema(File.read(File.join(File.dirname(__FILE__), schema_filename)))
      #     puts "the schema is NIL!" if xsd.nil?
      #     core_schema_errors = xsd.validate(document)
      #     l.error :invalid_xml_core if core_schema_errors.size > 0
      #     core_schema_errors.each do |error|
      #       if error_involves_colorvalue?(error)
      #         l.error :has_improper_base_color
      #       else
      #         l.error error
      #       end
      #     end
      #   end
      # end
    end
  end

  def self.objects_not_referenced?(document)
    document.css('object').map{|x| x.attributes["id"].value} != document.css('item').map {|x| x.attributes["objectid"].value}
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
    !document.encoding.nil? && (document.encoding.to_s.downcase != 'utf-8')
  end

  def self.dtd_exists?(file)
    found = file.get_input_stream.find { |line| line =~ /(!DOCTYPE\b)|(!ELEMENT\b)|(!ENTITY\b)|(!NOTATION\b)|(!ATTLIST\b)/ }
    !found.nil?
  end

  def self.error_involves_colorvalue?(error)
    error.to_s.include?("ST_ColorValue") || error.to_s.include?("displaycolor")
  end
end
