require 'spec_helper'

describe Thumbnail3mf do

  before do
    allow(MiniMagick::Image).to receive(:read).and_return(img_colorspace)
    allow(MimeMagic).to receive(:by_magic).and_return(img_type)
    allow(XmlVal).to receive(:validate).and_return(false)
  end

  context ".parse bad ContentType" do
    let(:img_type)  { double('ImgType', :type => 'foo/bar')}
    let(:zip_entry) { double('ZipEntry', :get_input_stream => img_type)}
    let(:images)    { double('Images', :first => zip_entry) }
    let(:message)   { 'Expected a png or jpeg thumbnail but the thumbnail was of type'}
    let(:img_colorspace) { double('String', :colorspace => 'DirectClass sRGB Matte')}

    it "Should log error when no png or jpeg" do
      Thumbnail3mf.parse(:doc, images.first)
      expect(Log3mf.entries(:error).first[2]).to include message
    end
  end

  context "when the thumbnail is a jpeg" do
    let(:img_colorspace) { double('String', :colorspace => 'DirectClass sRGB Matte')}
    let(:zip_entry) { double('ZipEntry', :get_input_stream => img_colorspace)}
    let(:img_type)  { double('ImgType', :type => 'image/jpeg')}

    it 'should not fail for RGB jpegs' do
      expect(Log3mf.entries(:error)).to be_empty
    end

    context "when the jpeg is a CMYK image" do
      let(:img_colorspace) { double('String', :colorspace => 'DirectClass CMYK Matte')}
      let(:message) { 'CMYK JPEG images must not be used for the thumbnail'}
      let(:img_type)  { double('ImgType', :type => 'foo/bar')}

      it 'should log a an error' do
        expect { Thumbnail3mf.parse(:doc, zip_entry) }.to raise_error { |e|
          expect(e).to be_a(Log3mf::FatalError)
        }
        expect(Log3mf.entries(:fatal_error).first[2]).to include message
      end
    end
  end

end
