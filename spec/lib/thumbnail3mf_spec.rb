require 'spec_helper'

describe Thumbnail3mf do

  context ".parse good ContentType" do
    let(:img_type)  { double('ImgType', :type => 'image/jpeg')}
    let(:zip_entry) { double('ZipEntry', :get_input_stream => img_type)}
    let(:images)    { double('Images', :first => zip_entry) }
    let(:message)   { 'thumbnail is of type'}

    it "Should not log error and only log debug for content type image/jpeg or image/png" do
      ENV['LOGDEBUG']='true'
      allow(MimeMagic).to receive(:by_magic).and_return(img_type)
      Thumbnail3mf.parse(:doc, images.first)
      expect(Log3mf.entries(:debug).first[2]).to include message
    end
  end

  context ".parse good ContentType" do
    let(:img_type)  { double('ImgType', :type => 'foo/bar')}
    let(:zip_entry) { double('ZipEntry', :get_input_stream => img_type)}
    let(:images)    { double('Images', :first => zip_entry) }
    let(:message)   { 'Expected a png or jpeg thumbnail but the thumbnail was of type'}

    it "Should log error when no png or jpeg" do
      allow(MimeMagic).to receive(:by_magic).and_return(img_type)
      Thumbnail3mf.parse(:doc, images.first)
      expect(Log3mf.entries(:error).first[2]).to include message
    end
  end


end
