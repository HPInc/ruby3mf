require 'yaml'
require_relative '../spec_helper.rb'

describe 'Integration Tests' do

  context 'with passing test case' do
    Dir.glob('spec/ruby3mf-testfiles/passing_cases/*') { |test_file|
      context test_file do
        before do
          allow(GlobalXMLValidations).to receive(:validate).and_return(false)
          Document.read(test_file)
        end
        it "should NOT have errors" do
          expect(Log3mf.count_entries(:error, :fatal_error)).to eq(0)
        end
      end
    }
  end

  context 'failing test cases' do

    failing_cases = YAML.load_file('spec/integration/en.yml')["en"]

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
          errors.each do |error_type, references|
            references.each do |reference|
              #TODO: Need to verify that the expected error msg was actually generated. Will need to
              #ignore the string interpolation placeholders when comparing

              expected_error_msg = I18n.t("#{reference}.msg")
              expect(Log3mf.entries(:error, :fatal_error).first[2]).to eq(expected_error_msg)
            end
          end

        end
      end
    end

  end

end
