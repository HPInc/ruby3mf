require 'yaml'
require_relative '../spec_helper.rb'

describe 'Integration Tests' do

  include Interpolation

  context 'with passing test case' do
    Dir.glob('spec/ruby3mf-testfiles/passing_cases/*') { |test_file|
      context test_file do
        before do
          Document.read(test_file)
        end
        it "should NOT have errors" do
          expect(Log3mf.count_entries(:error, :fatal_error)).to eq(0)
        end
      end
    }
  end

  context 'failing test cases' do

    failing_cases = YAML.load_file('spec/integration/integration_tests.yml')
    let(:errormap) { YAML.load_file('lib/ruby3mf/errors.yml') }

    failing_cases.each do |test_file, levels|

      context "#{test_file}.3mf" do
        before do
          Document.read("spec/ruby3mf-testfiles/failing_cases/#{test_file}.3mf")
        end

        it 'should log the correct errors' do
          levels.each do |level, reference|

            expect(Log3mf.count_entries(level.to_sym)).to be >= 1
            expect(Log3mf.count_entries(level.to_sym)).to be <= 1 if level.to_sym == :fatal_error

            reference.each do |reference_error, options|
              options = options ? symbolize_recursive(options) : {}
              expected_msg = errormap.fetch(reference_error.to_s)["msg"]
              expect(Log3mf.entries(level.to_sym).any?{|error| error[2] == (interpolate(expected_msg, options))}).to be true
            end
          end

        end
      end
    end

  end

end
