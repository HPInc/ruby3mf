require 'erb'

class SchemaFiles

  SchemaTemplate  = File.join(File.dirname(__FILE__), "3MFcoreSpec_1.1.xsd.template")
  SchemaLocation  = File.join(File.dirname(__FILE__), "xml.xsd")

  class << self

    def open(file)
      @@template ||= File.open(file, "r") do |file|
        file.read
      end

      yield(SchemaFiles.render(@@template))

    end

    def render(template)
       @@xsd_content ||= ERB.new(template).result( binding )
    end

  end


end
