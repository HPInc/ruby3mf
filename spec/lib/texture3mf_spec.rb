require 'spec_helper'

describe Texture3mf do

  let(:bytes)             { "Dale Internacional !!!".bytes }
  let(:document)          { double('Document', :objects => {}, :contents_for => bytes) }
  let(:relationship_file) { double('ZipEntry', :name => 'name', :get_input_stream => double('Stream', :read => bytes))}

  before do
    allow(MimeMagic).to receive(:by_magic).and_return(img_type)
    allow(MimeMagic).to receive(:name=)
    allow(GlobalXMLValidations).to receive(:validate).and_return(false)
  end

  context ".parse good ContentType" do
    let(:img_type)          { double('ImgType', :type => 'image/jpeg')}
    let(:message)           { 'texture is of type'}

    it "Should not log error and only log debug for content type image/jpeg or image/png" do
      ENV['LOGDEBUG']='true'
      Texture3mf.parse(:doc, relationship_file)
      expect(Log3mf.entries(:debug).first[2]).to include message
    end
  end

  context ".parse bad ContentType" do
    let(:img_type)  { double('ImgType', :type => 'foo/bar')}
    let(:message)   { 'Expected a png or jpeg texture but the texture was of type'}

    it "Should log error when no png or jpeg" do
      Texture3mf.parse(:doc, relationship_file)
      expect(Log3mf.entries(:error).first[2]).to include message
    end
  end

  context "#update @doc content" do
    let(:img_type)  { double('ImgType', :type => 'image/jpeg')}
    let(:texture)   { Texture3mf.parse(document, relationship_file) }
    let(:new_data)  { 'Dale Timbers !!!'.bytes}

    it "Should update texture content" do
      expect(texture.contents).not_to eq(new_data)
      texture.update(new_data)
      expect(texture.contents).to eq(new_data)
    end
  end

  context ".contents should return texture bytes content" do
    let(:img_type)  { double('ImgType', :type => 'image/jpeg')}
    let(:texture)   { Texture3mf.parse(document, relationship_file) }

    it "#contents should return content for relationship_file" do
      expect(texture.contents).to eq(bytes)
    end
  end

end
