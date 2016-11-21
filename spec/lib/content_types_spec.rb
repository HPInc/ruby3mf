require 'spec_helper'

describe ContentTypes do

  let(:required_content_types) { ['application/vnd.openxmlformats-package.relationships+xml', 'application/vnd.ms-package.3dmanufacturing-3dmodel+xml'] }
  let(:optional_content_types) { ['application/vnd.ms-printing.printticket+xml'] }

	describe ".parse a good file" do

    let(:zip_path) { "spec/ruby3mf-testfiles/passing_cases/test_case_5.zip" }
    let(:zip_file) { Zip::File.open(zip_path) }
    let(:inputs)   { zip_file.each(&:get_input_stream) }
    let(:types)    { ContentTypes.parse(inputs["[Content_Types].xml"]) }

    it "should have valid content types" do
      required_content_types.all? { |e| expect(types.values).to include(e) }
      expect(Log3mf.count_entries(:error, :fatal_error)).to be == 0
      expect(Log3mf.count_entries(:fatal_error)).to be <= 1
    end

  end

end