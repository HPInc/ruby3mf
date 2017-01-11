require 'spec_helper'

describe Model3mf do

  let(:zip_entry) { double('ZipEntry') }
  let(:document) { double('Document') }
  let(:ctypes) { {'jpg' => 'image/jpeg',
                  'jpeg' => 'image/jpeg',
                  'png' => 'image/png'} }
  before do
    allow(zip_entry).to receive(:get_input_stream).and_return(model_content)
    allow(document).to receive(:relationships).and_return(relationships)
    allow(document).to receive(:types).and_return(ctypes)
    allow(GlobalXMLValidations).to receive(:validate).and_return(false)
  end

  describe ".parse good file" do

    let(:relationships) { [{:target => "/3D/Texture/texture1.texture",
                            :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture",
                            :id => "rel1"},
                           {:target => "/3D/Texture/texture2.texture",
                            :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture",
                            :id => "rel2"},
                           {:target => "/3D/3dmodel.model",
                            :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel",
                            :id => "rel0"}] }

    let(:model_content) {
      '<?xml version="1.0" encoding="UTF-8"?>
      <model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
        <resources>
          <texture id="0" path="/3D/Texture/texture1.texture" width="425" height="425" depth="1" contenttype="image/jpeg" />
          <texture id="1" path="/3D/Texture/texture2.texture" width="235" height="208" depth="1" contenttype="image/jpeg" />
          <object id="2" type="model">
            <mesh>
              <vertices>
                <vertex x="0" y="0" z="0" />
                <vertex x="10" y="0" z="0" />
                <vertex x="10" y="20" z="0" />
                <vertex x="0" y="20" z="0" />
                <vertex x="0" y="0" z="30" />
                <vertex x="10" y="0" z="30" />
                <vertex x="10" y="20" z="30" />
                <vertex x="0" y="20" z="30" />
              </vertices>
              <triangles>
                <triangle v1="3" v2="2" v3="1" />
                <triangle v1="1" v2="0" v3="3" />
                <triangle v1="4" v2="5" v3="6" />
                <triangle v1="6" v2="7" v3="4" />
                <triangle v1="0" v2="1" v3="5" />
                <triangle v1="5" v2="4" v3="0" />
                <triangle v1="1" v2="2" v3="6" />
                <triangle v1="6" v2="5" v3="1" />
                <triangle v1="2" v2="3" v3="7" />
                <triangle v1="7" v2="6" v3="2" />
                <triangle v1="3" v2="0" v3="4" />
                <triangle v1="4" v2="7" v3="3" />
              </triangles>
            </mesh>
          </object>
        </resources>
        <build>
          <item objectid="2" />
        </build>
      </model>'
    }

    it "should have no error on log" do
      Model3mf.parse(document, zip_entry)
      expect(Log3mf.count_entries(:error, :fatal_error)).to be == 0
      expect(Log3mf.count_entries(:fatal_error)).to be <= 1
    end
  end

  describe ".parse bad file" do

    context "missing resource" do

      let(:relationships) {
        [
          {:target => "/3D/Texture/texture2.texture",
           :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture",
           :id => "rel2"},
          {:target => "/3D/3dmodel.model",
           :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel",
           :id => "rel0"
          }
        ]
      }

      let(:model_content) {
        '<?xml version="1.0" encoding="UTF-8"?>
        <model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
          <resources>
            <texture id="0" path="/3D/Texture/texture1.texture" width="425" height="425" depth="1" contenttype="image/jpeg" />
            <texture id="1" path="/3D/Texture/texture2.texture" width="235" height="208" depth="1" contenttype="image/jpeg" />
            <object id="2" type="model">
              <mesh>
                <vertices>
                  <vertex x="0" y="0" z="0" />
                  <vertex x="10" y="0" z="0" />
                  <vertex x="10" y="20" z="0" />
                  <vertex x="0" y="20" z="0" />
                  <vertex x="0" y="0" z="30" />
                  <vertex x="10" y="0" z="30" />
                  <vertex x="10" y="20" z="30" />
                  <vertex x="0" y="20" z="30" />
                </vertices>
                <triangles>
                  <triangle v1="3" v2="2" v3="1" />
                  <triangle v1="1" v2="0" v3="3" />
                  <triangle v1="4" v2="5" v3="6" />
                  <triangle v1="6" v2="7" v3="4" />
                  <triangle v1="0" v2="1" v3="5" />
                  <triangle v1="5" v2="4" v3="0" />
                  <triangle v1="1" v2="2" v3="6" />
                  <triangle v1="6" v2="5" v3="1" />
                  <triangle v1="2" v2="3" v3="7" />
                  <triangle v1="7" v2="6" v3="2" />
                  <triangle v1="3" v2="0" v3="4" />
                  <triangle v1="4" v2="7" v3="3" />
                </triangles>
              </mesh>
            </object>
          </resources>
          <build>
            <item objectid="2" />
          </build>
        </model>'
      }

      let(:message) { 'Missing required resource' }

      it "should have an error on log" do
        Model3mf.parse(document, zip_entry)
        expect(Log3mf.count_entries(:error, :fatal_error)).to be == 1
        expect(Log3mf.entries(:error).first[2]).to include message
      end

    end

    context "with invalid XML" do

      let(:relationships) {
        [
          {:target => "/3D/Texture/texture1.texture",
           :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture",
           :id => "rel1"},
          {:target => "/3D/Texture/texture2.texture",
           :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture",
           :id => "rel2"},
          {:target => "/3D/3dmodel.model",
           :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel",
           :id => "rel0"
          }
        ]
      }

      let(:model_content) {
        'var string = "this is not valid xml";'
      }

      let(:message) { 'Model file invalid XML' }

      it "should have an error on log" do
        expect { Model3mf.parse(document, zip_entry) }.to raise_error { |e|
          expect(e).to be_a(Log3mf::FatalError)
        }
        expect(Log3mf.count_entries(:fatal_error)).to be == 1
        expect(Log3mf.entries(:fatal_error).first[2]).to include message
      end
    end

    context "with missing required child elements of model" do
      let(:model_content) {
        '<?xml version="1.0" encoding="UTF-8"?>
              <model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
                <resource>
                  <texture id="0" path="/3D/Texture/texture1.texture" width="425" height="425" depth="1" contenttype="image/jpeg" />
                  <texture id="1" path="/3D/Texture/texture2.texture" width="235" height="208" depth="1" contenttype="image/jpeg" />
                  <object id="1" type="model">
                    <mesh>
                      <vertices>
                        <vertex x="0" y="0" z="0" />
                        <vertex x="10" y="0" z="0" />
                        <vertex x="10" y="20" z="0" />
                        <vertex x="0" y="20" z="0" />
                        <vertex x="0" y="0" z="30" />
                        <vertex x="10" y="0" z="30" />
                        <vertex x="10" y="20" z="30" />
                        <vertex x="0" y="20" z="30" />
                      </vertices>
                      <triangles>
                        <triangle v1="3" v2="2" v3="1" />
                        <triangle v1="1" v2="0" v3="3" />
                        <triangle v1="4" v2="5" v3="6" />
                        <triangle v1="6" v2="7" v3="4" />
                        <triangle v1="0" v2="1" v3="5" />
                        <triangle v1="5" v2="4" v3="0" />
                        <triangle v1="1" v2="2" v3="6" />
                        <triangle v1="6" v2="5" v3="1" />
                        <triangle v1="2" v2="3" v3="7" />
                        <triangle v1="7" v2="6" v3="2" />
                        <triangle v1="3" v2="0" v3="4" />
                        <triangle v1="4" v2="7" v3="3" />
                      </triangles>
                    </mesh>
                  </object>
                </resource>
                <building>
                  <item objectid="1" />
                </building>
              </model>'
      }

      let(:relationships) { [{:target => "/3D/Texture/texture1.texture",
                              :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture",
                              :id => "rel1"},
                             {:target => "/3D/Texture/texture2.texture",
                              :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture",
                              :id => "rel2"},
                             {:target => "/3D/3dmodel.model",
                              :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel",
                              :id => "rel0"}] }


      let(:message) { 'Model element must include resources and build as child elements' }

      it 'should log an error' do
        Model3mf.parse(document, zip_entry)
        expect(Log3mf.count_entries(:error, :fatal_error)).to be == 1
        expect(Log3mf.entries(:error).first[2]).to include message
      end
    end

    context "with duplicate metadata elements" do
      let(:model_content) {
        '<?xml version="1.0" encoding="UTF-8"?>
      <model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
          <metadata name="LicenseTerms">All rights reserved</metadata>
          <metadata name="Description">Box</metadata>
          <metadata name="Description">Box - CSS</metadata>
        <resources>
          <texture id="0" path="/3D/Texture/texture1.texture" width="425" height="425" depth="1" contenttype="image/jpeg" />
          <texture id="1" path="/3D/Texture/texture2.texture" width="235" height="208" depth="1" contenttype="image/jpeg" />
          <object id="2" type="model">
            <mesh>
              <vertices>
                <vertex x="0" y="0" z="0" />
                <vertex x="10" y="0" z="0" />
                <vertex x="10" y="20" z="0" />
                <vertex x="0" y="20" z="0" />
                <vertex x="0" y="0" z="30" />
                <vertex x="10" y="0" z="30" />
                <vertex x="10" y="20" z="30" />
                <vertex x="0" y="20" z="30" />
              </vertices>
              <triangles>
                <triangle v1="3" v2="2" v3="1" />
                <triangle v1="1" v2="0" v3="3" />
                <triangle v1="4" v2="5" v3="6" />
                <triangle v1="6" v2="7" v3="4" />
                <triangle v1="0" v2="1" v3="5" />
                <triangle v1="5" v2="4" v3="0" />
                <triangle v1="1" v2="2" v3="6" />
                <triangle v1="6" v2="5" v3="1" />
                <triangle v1="2" v2="3" v3="7" />
                <triangle v1="7" v2="6" v3="2" />
                <triangle v1="3" v2="0" v3="4" />
                <triangle v1="4" v2="7" v3="3" />
              </triangles>
            </mesh>
          </object>
        </resources>
        <build>
          <item objectid="2" />
        </build>
      </model>'
      }

      let(:relationships) { [{:target => "/3D/Texture/texture1.texture",
                                  :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture",
                                  :id => "rel1"},
                                 {:target => "/3D/Texture/texture2.texture",
                                  :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture",
                                  :id => "rel2"},
                                 {:target => "/3D/3dmodel.model",
                                  :type => "http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel",
                                  :id => "rel0"}] }

      let(:message) { 'metadata elements must not share the same name' }
      it 'should log an error' do
        Model3mf.parse(document, zip_entry)
        expect(Log3mf.count_entries(:error, :fatal_error)).to be == 1
        expect(Log3mf.entries(:error).first[2]).to include message
      end
    end
  end
end
