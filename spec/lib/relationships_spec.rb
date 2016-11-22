require 'spec_helper'

describe Relationships do

  let(:model_zip_entry) { double('ZipEntry') }

  let(:model_xml) {
    '<?xml version="1.0" encoding="UTF-8"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel" />
    </Relationships>'
  }

  let(:texture_zip_entry) { double('ZipEntry') }

  let(:texture_xml) {
    '<?xml version="1.0" encoding="utf-8"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <Relationship Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture" Target="/3D/Texture/texture1.texture" Id="rel1" />
      <Relationship Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture" Target="/3D/Texture/texture2.texture" Id="rel2" />
    </Relationships>'
  }

  let(:rels) { [model_zip_entry, texture_zip_entry] }

  before do
    allow(model_zip_entry).to receive(:name).and_return("_rels/.rels")

    allow(model_zip_entry).to receive(:get_input_stream).and_return(model_xml)
    allow(texture_zip_entry).to receive(:get_input_stream).and_return(texture_xml)
  end


  it "should parse relationshios prolerly" do
    inputs = rels.map{|r| Relationships.parse(r)}
  end

end
