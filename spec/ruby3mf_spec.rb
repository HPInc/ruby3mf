require 'spec_helper'

describe Ruby3mf do
  before do
    Log3mf.reset_log
  end

  it 'has a version number' do
    expect(Ruby3mf::VERSION).not_to be nil
  end

  it 'parses a valid file without errors' do
    Log3mf.context "box.3mf" do |l|
      Document.read('spec/examples/box.3mf')
    end

    expect(Log3mf.count_entries(:error, :fatal_error)).to eq(0)
  end

  it 'parses a invalid file reporting 1 error' do
    Log3mf.context "3d_model_invalid_xml.3mf" do |l|
      Document.read('spec/examples/3d_model_invalid_xml.3mf')
    end

    expect(Log3mf.count_entries(:error, :fatal_error)).to eq(1)
    log = JSON.parse(Log3mf.to_json)
    fatal_error = log.select { |entry| entry["severity"]=="fatal_error" }.first
    expect(fatal_error["message"]).to include("Model file invalid XML")
  end


  describe "Document" do
    it 'should return a Document' do
      doc=Document.read('spec/examples/box.3mf')
      expect(doc).to be_a(Document)
    end

    context "document.model" do
      before do
        @doc3mf=Document.read('spec/examples/box.3mf')
      end

      it 'should be a collection of model Hashes' do
        expect(@doc3mf.models).to be_an(Array)
        expect(@doc3mf.models.size).to be(1)
        @doc3mf.models.each do |model|
          expect(model).to be_a(Hash)
        end
      end
    end
  end

end
