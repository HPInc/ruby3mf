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

    failing_cases.each do |test_file, errors|

      context "#{test_file}.3mf" do
        before do
          Document.read("spec/ruby3mf-testfiles/failing_cases/#{test_file}.3mf")
        end

        it "should have errors" do
          expect(Log3mf.count_entries(:error, :fatal_error)).to be >= 1
          expect(Log3mf.count_entries(:fatal_error)).to be <= 1
        end

        it 'should log the correct errors' do
          errors.each do |_, reference|
            reference.each do |reference_error, options|
              options = options ? symbolize_recursive(options) : {}
              expected_error_msg = errormap.fetch(reference_error.to_s)["msg"]
              expect(Log3mf.entries(:error, :fatal_error).first[2]).to eq(interpolate(expected_error_msg, options))
            end
          end

        end
      end
    end

  end

end
