$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ruby3mf'

RSpec.configure do |config|
  config.order = 'random'

  config.before(:suite) do
    if File.exists?("spec/ruby3mf-testfiles")
      `cd spec/ruby3mf-testfiles; git pull`
    else
      `cd spec; git clone https://github.com/IPGPTP/ruby3mf-testfiles.git`
    end
  end
end
