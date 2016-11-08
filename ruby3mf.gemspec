# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby3mf/version'

Gem::Specification.new do |spec|
  spec.name          = "ruby3mf"
  spec.version       = Ruby3mf::VERSION
  spec.authors       = ["Mike Whitmarsh, Jeff Porter, and William Hertling"]
  spec.email         = ["mwhit@hp.com", "jeff.porter@hp.com", "william.hertling@hp.com"]

  spec.summary       = %q{Read, write and validate 3MF files with native Ruby}
  spec.description   = %q{Read, write and validate 3MF files with native Ruby easily.}
  spec.homepage      = "https://github.com/IPGPTP/ruby3mf"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency 'rubyzip'
  spec.add_runtime_dependency 'nokogiri', '~>1.6.8'
  spec.add_runtime_dependency 'mimemagic'
end
