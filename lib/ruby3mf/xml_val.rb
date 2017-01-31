require 'nokogiri'

class XmlVal

  def self.validate_parse(xml_file, schema_name = nil)
    doc = Nokogiri::XML(xml_file.get_input_stream) do |config|
      config.strict.nonet.noblanks
    end
    validate(xml_file, doc, schema_name)
    doc
  end

  def self.validate(file, document, schema_filename = nil)
    Log3mf.context "validations" do |l|
      l.error   :has_xml_space_attribute if space_attribute_exists?(document)
      l.error   :wrong_encoding if xml_not_utf8_encoded?(document)
      l.error   :dtd_not_allowed if dtd_exists?(file)
      l.warning :missing_object_reference if objects_not_referenced?(document)
      l.error   :contains_xsi_namespace if contains_xsi_namespace?(document)

      if schema_filename
        Log3mf.context "validating core schema" do |l|
          SchemaFiles.open(schema_filename) do |content|
            log_schema_errors(Nokogiri::XML::Schema.new(content).validate(document), l)
          end
        end
      end
    end
  end

  def self.log_schema_errors(core_schema_errors, l)
    l.error :invalid_xml_core if core_schema_errors.size > 0
    core_schema_errors.each do |error|
      case error.message
      when /(ST_ColorValue\b)|(displaycolor\b)/
        l.error :has_improper_base_color
      when /(ST_Number\b)|(numbers not formatted\b)/
        l.error :has_commas_for_floats, e: "line: #{error.line}, #{error.message}"
      else
        l.error :schema_error, e: "line: #{error.line}, #{error.message}"
      end
    end
  end

  def self.objects_not_referenced?(document)
    document.css('object').map { |x| x.attributes["id"].value } != document.css('build/item').map { |x| x.attributes["objectid"].value }
  end

  def self.space_attribute_exists?(document)
    !(document.xpath('//*[@xml:space]').empty?)
  end

  def self.xml_not_utf8_encoded?(document)
    !document.encoding.nil? && (document.encoding.to_s.downcase != 'utf-8')
  end

  def self.dtd_exists?(file)
    file.get_input_stream.read.match(/(!DOCTYPE\b)|(!ELEMENT\b)|(!ENTITY\b)|(!NOTATION\b)|(!ATTLIST\b)/)
  end

  def self.error_involves_colorvalue?(error)
    error.to_s.include?("ST_ColorValue") || error.to_s.include?("displaycolor")
  end

  def self.contains_xsi_namespace?(document)
    document.namespaces.has_value?('http://www.w3.org/2001/XMLSchema-instance')
  end
end
