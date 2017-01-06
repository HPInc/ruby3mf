require_relative "ruby3mf/version"
require_relative "ruby3mf/log3mf"
require_relative "ruby3mf/document"
require_relative "ruby3mf/content_types"
require_relative "ruby3mf/model3mf"
require_relative "ruby3mf/relationships"
require_relative "ruby3mf/thumbnail3mf"
require_relative "ruby3mf/texture3mf"
require_relative "ruby3mf/global_xml_validations"

require 'zip'
require 'nokogiri'
require 'json'
require 'mimemagic'
require 'I18n'

I18n.load_path = Dir[File.join('lib', 'ruby3mf','config', 'locales', '*.yml')]

module Ruby3mf

  # Your code goes here...
end
