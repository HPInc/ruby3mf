require 'spec_helper'

describe Relationships do

  context "when all relations are satisfied" do

    let(:model_zip_entry) { double('ZipEntry', :name => "Relationships") }

    let(:model_xml) {
      '<?xml version="1.0" encoding="UTF-8"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel" />
      </Relationships>'
    }

    let(:texture_zip_entry) { double('ZipEntry', :name => "Relationships") }

    let(:texture_xml) {
      '<?xml version="1.0" encoding="utf-8"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture" Target="/3D/Texture/texture1.texture" Id="rel1" />
        <Relationship Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture" Target="/3D/Texture/texture2.texture" Id="rel2" />
      </Relationships>'
    }

    let(:rels) { [model_zip_entry, texture_zip_entry] }

    before do
      allow(model_zip_entry).to receive(:get_input_stream).and_return(model_xml)
      allow(texture_zip_entry).to receive(:get_input_stream).and_return(texture_xml)
      allow(GlobalXMLValidations).to receive(:validate).and_return(false)
    end

    it "should parse relationshios prolerly" do
      rels.map{|r| Relationships.parse(r)}
      expect(Log3mf.count_entries(:error, :fatal_error)).to be == 0
    end

  end

  context "when all relations are not satisfied" do

    let(:model_zip_entry) { double('ZipEntry', :name => "Relationships") }

    let(:model_xml) {
      '<?xml version="1.0" encoding="UTF-8"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel" />
      <FooNode Target="Bar" Id="rel0" Type="Baz" />
      </Relationships>'
    }

    let(:texture_zip_entry) { double('ZipEntry', :name => "Relationships") }

    let(:texture_xml) {
      '<?xml version="1.0" encoding="utf-8"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture" Target="/3D/Texture/texture1.texture" Id="rel1" />
        <Relationship Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture" Target="/3D/Texture/texture2.texture" Id="rel2" />
      </Relationships>'
    }

    let(:rels) { [model_zip_entry, texture_zip_entry] }

    let(:message) { "found non-Relationship node: FooNode" }

    before do
      allow(model_zip_entry).to receive(:get_input_stream).and_return(model_xml)
      allow(texture_zip_entry).to receive(:get_input_stream).and_return(texture_xml)
    end

    it "should parse relationshios prolerly" do
      rels.map{|r| Relationships.parse(r)}
      expect(Log3mf.count_entries(:error, :fatal_error)).to be == 0
      expect(Log3mf.entries(:info)[1][2]).to include message
    end

  end


end
