require 'spec_helper'
require 'nokogiri'

describe XmlVal do

  let(:xml) { Nokogiri::XML(
    '<?xml version="1.0" encoding="UTF-8"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml" />
          <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml" />
        </Types>'
  )
  }
  let(:zipentry) { 'foo' }

  before do
    allow(XmlVal).to receive(:dtd_exists?).and_return(false)
  end

  context 'when xml space attribute is present' do
    let(:xml) { Nokogiri::XML(
      '<?xml version="1.0" encoding="UTF-8"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" xml:space="preserved" ContentType="application/vnd.openxmlformats-package.relationships+xml" />
                  <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml" />
                </Types>'
    )
    }

    let(:message) { "xml:space attribute is not allowed" }

    it 'should give an error' do
      XmlVal.validate(zipentry, xml)
      expect(Log3mf.count_entries(:error)).to be == 1
      expect(Log3mf.entries(:error).first[2]).to include message
    end
  end

  context 'when xml space attribute is not present' do
    it 'should be supes chill (not give an error) if the xml:space attribute is missing' do
      XmlVal.validate(zipentry, xml)
      expect(Log3mf.count_entries(:error)).to be == 0
      expect(Log3mf.entries(:error)).to be_empty
    end
  end

  context 'when xml encoding is not UTF-8' do
    let(:xml) { Nokogiri::XML(
      '<?xml version="1.0" encoding="ISO-8859-11"?>
                    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                      <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml" />
                      <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml" />
                    </Types>'
    )
    }

    let(:message) { "XML content must be UTF8 encoded" }

    it 'should give an error' do
      XmlVal.validate(zipentry, xml)
      expect(Log3mf.count_entries(:error)).to be == 1
      expect(Log3mf.entries(:error).first[2]).to include message
    end
  end

  context 'when xml encoding is UTF-8' do
    it 'should validate that the file is correctly encoded' do
      XmlVal.validate(zipentry, xml)
      expect(Log3mf.count_entries(:error)).to be == 0
      expect(Log3mf.entries(:error)).to be_empty
    end
  end

  context "when locale is en-US and floating point values are invalid" do

    let(:xml) {
      Nokogiri::XML('<?xml version="1.0" encoding="UTF-8"?>
      <model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
        <resources>
          <texture id="0" path="/3D/Texture/texture1.texture" width="425" height="425" depth="1" contenttype="image/jpeg" />
          <texture id="1" path="/3D/Texture/texture2.texture" width="235" height="208" depth="1" contenttype="image/jpeg" />
          <object id="2" type="model">
            <mesh>
              <vertices>
                <vertex x="0,000" y="00,000" z="00,000" />
                <vertex x="10,000" y="00,000" z="00,000" />
                <vertex x="10,000" y="200,000" z="00,000" />
                <vertex x="00,000" y="200,000" z="00,000" />
                <vertex x="00,000" y="00,000" z="300,000" />
                <vertex x="10,0000" y="0" z="300,000" />
                <vertex x="100,000" y="20" z="300,000" />
                <vertex x="00,000" y="200,000" z="300,000" />
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
      </model>')
    }

    it "should produce an error" do
      XmlVal.validate(zipentry, xml)
      expect(Log3mf.count_entries(:error)).to be == 1
      expect(Log3mf.entries(:error)).to_not be_empty
    end

  end

  context "when locale is not en-US and floating point falues are valid" do

    let(:xml) {
      Nokogiri::XML('<?xml version="1.0" encoding="UTF-8"?>
      <model unit="millimeter" xml:lang="pt_BR" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
        <resources>
          <texture id="0" path="/3D/Texture/texture1.texture" width="425" height="425" depth="1" contenttype="image/jpeg" />
          <texture id="1" path="/3D/Texture/texture2.texture" width="235" height="208" depth="1" contenttype="image/jpeg" />
          <object id="2" type="model">
            <mesh>
              <vertices>
                <vertex x="0.000" y="00.000" z="00.000" />
                <vertex x="10.000" y="00.000" z="00.000" />
                <vertex x="10.000" y="200.000" z="00.000" />
                <vertex x="00.000" y="200.000" z="00.000" />
                <vertex x="00.000" y="00.000" z="300.000" />
                <vertex x="10.0000" y="0" z="300.000" />
                <vertex x="100.000" y="20" z="300.000" />
                <vertex x="00.000" y="200.000" z="300.000" />
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
      </model>')
    }

    it "should produce an error " do
      XmlVal.validate(zipentry, xml)
      expect(Log3mf.count_entries(:error)).to be == 1
      expect(Log3mf.entries(:error)).to_not be_empty
    end

  end

  context "when no locale is present, but floating point falues are valid" do

    let(:xml) {
      Nokogiri::XML('<?xml version="1.0" encoding="UTF-8"?>
      <model unit="millimeter" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
        <resources>
          <texture id="0" path="/3D/Texture/texture1.texture" width="425" height="425" depth="1" contenttype="image/jpeg" />
          <texture id="1" path="/3D/Texture/texture2.texture" width="235" height="208" depth="1" contenttype="image/jpeg" />
          <object id="2" type="model">
            <mesh>
              <vertices>
                <vertex x="0.000" y="00.000" z="00.000" />
                <vertex x="10.000" y="00.000" z="00.000" />
                <vertex x="10.000" y="200.000" z="00.000" />
                <vertex x="00.000" y="200.000" z="00.000" />
                <vertex x="00.000" y="00.000" z="300.000" />
                <vertex x="10.0000" y="0" z="300.000" />
                <vertex x="100.000" y="20" z="300.000" />
                <vertex x="00.000" y="200.000" z="300.000" />
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
      </model>')
    }

    it "should not have any errors" do
      XmlVal.validate(zipentry, xml)
      expect(Log3mf.count_entries(:error)).to be == 0
      expect(Log3mf.entries(:error)).to be_empty
    end

  end

  context "when no locale is present and floating point values are invalid" do

    let(:xml) {
      Nokogiri::XML('<?xml version="1.0" encoding="UTF-8"?>
      <model unit="millimeter" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
        <resources>
          <texture id="0" path="/3D/Texture/texture1.texture" width="425" height="425" depth="1" contenttype="image/jpeg" />
          <texture id="1" path="/3D/Texture/texture2.texture" width="235" height="208" depth="1" contenttype="image/jpeg" />
          <object id="2" type="model">
            <mesh>
              <vertices>
                <vertex x="0,000" y="00,000" z="00,000" />
                <vertex x="10,000" y="00,000" z="00,000" />
                <vertex x="10,000" y="200,000" z="00,000" />
                <vertex x="00,000" y="200,000" z="00,000" />
                <vertex x="00,000" y="00,000" z="300,000" />
                <vertex x="10,0000" y="0" z="300,000" />
                <vertex x="100,000" y="20" z="300,000" />
                <vertex x="00,000" y="200,000" z="300,000" />
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
      </model>')
    }

    it "should give an error" do
      XmlVal.validate(zipentry, xml)
      expect(Log3mf.count_entries(:error)).to be == 1
      expect(Log3mf.entries(:error)).to_not be_empty
    end

  end

  context "when a consumer tries to output any 3D objects that is not referenced by an <item> element" do
      let(:xml) {Nokogiri::XML('<?xml version="1.0" encoding="UTF-8"?>
      <model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
        <resources>
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
          <item objectid="1" />
        </build>
      </model>')}

      it "should at least warning up it" do
        XmlVal.validate(zipentry, xml)
        expect(Log3mf.count_entries(:warning)).to be == 1
        expect(Log3mf.entries(:warning)).to_not be_empty
      end

  end

  context "when a consumer tries to output 3D objects all referenced by an <item> element" do
      let(:xml) {Nokogiri::XML('<?xml version="1.0" encoding="UTF-8"?>
      <model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
        <resources>
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
          <item objectid="1" />
          <item objectid="2" />
        </build>
      </model>')}

      it "should at least warning up it" do
        XmlVal.validate(zipentry, xml)
        expect(Log3mf.count_entries(:warning)).to be == 0
        expect(Log3mf.entries(:warning)).to be_empty
      end

  end

end
