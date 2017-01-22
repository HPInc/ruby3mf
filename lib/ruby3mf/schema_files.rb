require 'erb'

class SchemaFiles

  SchemaTemplate  = File.join(File.dirname(__FILE__), "3MFcoreSpec_1.1.xsd.template")
  SchemaLocation  = File.join(File.dirname(__FILE__), "xml.xsd")

  class << self
    attr_accessor :xsd_content

    def render(template)
       @@xsd_content ||= ERB.new(template).result( binding )
    end

  end


end
