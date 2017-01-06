require 'fileutils'

require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ruby3mf'

I18n.load_path << Dir[File.join('integration', '*.yml')]

RSpec.configure do |config|
  config.order = 'random'

  config.before(:suite) do
    if ENV["NOPULL"]
      puts "Skipping git pull for test files"
    else
      if File.exists?("spec/ruby3mf-testfiles")
        `cd spec/ruby3mf-testfiles; git pull`
      else
        `cd spec; git clone https://github.com/IPGPTP/ruby3mf-testfiles.git`
      end
    end
  end

  config.before(:example) do
    Log3mf.reset_log
  end

end
