require 'spec_helper'

describe ContentTypes do

  let(:required_content_types) { ['application/vnd.openxmlformats-package.relationships+xml', 'application/vnd.ms-package.3dmanufacturing-3dmodel+xml'] }
  let(:optional_content_types) { ['application/vnd.ms-printing.printticket+xml'] }

  let(:zip_entry) { double('ZipEntry') }

  before do
    allow(zip_entry).to receive(:get_input_stream).and_return(content_xml)
    allow(XmlVal).to receive(:validate).and_return(false)
  end

  describe ".parse a good file" do
    let(:content_xml) {
      '<?xml version="1.0" encoding="UTF-8"?>
      <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml" />
        <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml" />
      </Types>'
    }

    it "should have valid content types" do
      types = ContentTypes.parse(zip_entry)
      required_content_types.all? { |e| expect(types.get_types).to include(e) }
      expect(Log3mf.count_entries(:error, :fatal_error)).to be == 0
    end
  end

  describe "invalid content type" do
    let(:content_xml) {
      '<?xml version="1.0" encoding="UTF-8"?>
      <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="invalid content type" />
        <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml" />
      </Types>'
    }
    let(:message) { 'missing required ContentType' }
    it 'should report content type error' do
      ContentTypes.parse(zip_entry)
      expect(Log3mf.count_entries(:error, :fatal_error)).to be == 1
      expect(Log3mf.count_entries(:fatal_error)).to be <= 1
      expect(Log3mf.entries(:error).first[:message]).to include message
    end
  end

  describe "when xml contains unexpected element" do
    let(:content_xml) {
      '<?xml version="1.0" encoding="UTF-8"?>
      <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Foo Extension="rels" ContentType="invalid content type for foo element" />
        <Default Extension="rels" ContentType="invalid content type" />
        <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml" />
      </Types>'
    }
    let(:message) { 'contains unexpected element' }
    it 'should report unexpected element warning' do
      ContentTypes.parse(zip_entry)
      expect(Log3mf.count_entries(:warning)).to be == 1
      expect(Log3mf.entries(:warning).first[:message]).to include message
    end
  end

  describe "valid file with override" do
    let(:content_xml) {
      '<?xml version="1.0" encoding="UTF-8"?>
      <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml" />
        <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml" />
        <Default Extension="extension" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml" />
        <Override PartName="/Folder/File.extension" ContentType="image/png" />
      </Types>'
    }

    it "should return valid overrides" do
      types = ContentTypes.parse(zip_entry)
      expect(types.get_type('/Folder/File.extension')).to eq 'image/png'
      expect(Log3mf.count_entries(:error, :fatal_error)).to be == 0
    end
  end
end
