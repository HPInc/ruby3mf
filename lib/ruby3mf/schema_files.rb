require 'erb'

class SchemaFiles

  SchemaTemplate  = File.join(File.dirname(__FILE__), "3MFcoreSpec_1.1.xsd.template")
  SchemaLocation  = File.join(File.dirname(__FILE__), "xml.xsd")

  def self.render(template)
    ERB.new(template).result( binding )
  end

end
