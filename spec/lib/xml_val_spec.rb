require 'spec_helper'
require 'nokogiri'

describe XmlVal do

  include Interpolation

  failing_cases = YAML.load_file('spec/integration/integration_tests.yml')
  let(:errormap) { YAML.load_file('lib/ruby3mf/errors.yml') }

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
      expect(Log3mf.entries(:error).first[:message]).to include message
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
      expect(Log3mf.entries(:error).first[:message]).to include message
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
      Nokogiri::XML('<?xml version="1.0" encoding="utf-8"?>
      <model xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" unit="millimeter" xml:lang="en-US" xmlns:m="http://schemas.microsoft.com/3dmanufacturing/material/2015/02">
      	<resources>
      		<object id="1" name="Cube" type="model">
      			<mesh>
      				<vertices>
      					<vertex x="0" y="0" z="0" />
      					<vertex x="10,000" y="0" z="0" />
      					<vertex x="10,000" y="20,000" z="0" />
      					<vertex x="0" y="20,000" z="0" />
      					<vertex x="0" y="0" z="30,000" />
      					<vertex x="10,000" y="0" z="30,000" />
      					<vertex x="10,000" y="20,000" z="30,000" />
      					<vertex x="0" y="20,000" z="30,000" />
      				</vertices>
      				<triangles>
      					<triangle v1="2" v2="1" v3="0" />
      					<triangle v1="0" v2="3" v3="2" />
      					<triangle v1="4" v2="5" v3="6" />
      					<triangle v1="6" v2="7" v3="4" />
      					<triangle v1="0" v2="1" v3="5" />
      					<triangle v1="5" v2="4" v3="0" />
      					<triangle v1="2" v2="3" v3="7" />
      					<triangle v1="7" v2="6" v3="2" />
      					<triangle v1="1" v2="2" v3="6" />
      					<triangle v1="6" v2="5" v3="1" />
      					<triangle v1="3" v2="0" v3="4" />
      					<triangle v1="4" v2="7" v3="3" />
      				</triangles>
      			</mesh>
      		</object>
      	</resources>
      	<build>
      		<item objectid="1" />
      	</build>
      </model>')
    }

    it "should produce an error" do
      XmlVal.validate(zipentry, xml, SchemaFiles::SchemaTemplate)
      expect(Log3mf.entries(:error)).to_not be_empty
      expected_msg = errormap.fetch(:has_commas_for_floats.to_s)["msg"]
      expect(Log3mf.entries(:error).any?{|error| error[:message].include? (interpolate(expected_msg, {}))}).to be true
    end

  end

  context "when no locale is present, but floating point falues are valid" do

    let(:xml) {
      Nokogiri::XML('<?xml version="1.0" encoding="utf-8"?>
        <model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:s="http://schemas.microsoft.com/3dmanufacturing/slice/2015/07" requiredextensions="s p" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06">
          <resources>
            <object id="2">
              <mesh>
                <vertices>
                  <vertex x="20.000" y="20.000" z="0.500" />
                  <vertex x="20.000" y="0.000" z="0.500" />
                  <vertex x="20.000" y="20.000" z="0.000" />
                  <vertex x="0.000" y="20.000" z="0.000" />
                  <vertex x="20.000" y="0.000" z="0.000" />
                  <vertex x="0.000" y="0.000" z="0.000" />
                  <vertex x="0.000" y="0.000" z="0.500" />
                  <vertex x="0.000" y="20.000" z="0.500" />
                </vertices>
                <triangles>
                  <triangle v1="0" v2="1" v3="2" />
                  <triangle v1="3" v2="0" v3="2" />
                  <triangle v1="4" v2="3" v3="2" />
                  <triangle v1="5" v2="3" v3="4" />
                  <triangle v1="4" v2="6" v3="5" />
                  <triangle v1="6" v2="7" v3="5" />
                  <triangle v1="7" v2="6" v3="0" />
                  <triangle v1="1" v2="6" v3="4" />
                  <triangle v1="5" v2="7" v3="3" />
                  <triangle v1="7" v2="0" v3="3" />
                  <triangle v1="2" v2="1" v3="4" />
                  <triangle v1="0" v2="6" v3="1" />
                </triangles>
              </mesh>
            </object>
          </resources>
          <build p:UUID="125fd563-0216-4491-bf88-bdac9dd1406b">
            <item objectid="2"/>
          </build>
        </model>
        ')
    }

    it "should not have any errors" do
      XmlVal.validate(zipentry, xml, SchemaFiles::SchemaTemplate)
      expect(Log3mf.count_entries(:error)).to be == 0
      expect(Log3mf.entries(:error)).to be_empty
    end

  end

  context "when no locale is present and floating point values are invalid" do

    let(:validation_result) {
      [ double(:has_commas_for_floats,
         "id"=>"has_commas_for_floats",
          "context"=>"validations/validating core schema",
          "severity"=>"error",
          "line" => 1,
          "message"=>"numbers not formatted for the en-US locale",
          "spec_ref"=>"http://3mf.io/wp-content/uploads/2016/03/3MFcoreSpec_1.1.pdf#page=15",
          "caller"=>"xml_val.rb:33"
        ),
        double(:schema_error,
         "id"=>"schema_error",
          "context"=>"validations/validating core schema",
          "severity"=>"error",
          "line" => 2,
          "message"=>"Element '{http://schemas.microsoft.com/3dmanufacturing/core/2015/02}vertex', attribute 'x': '10,000' is not a valid value of the atomic type '{http://schemas.microsoft.com/3dmanufacturing/core/2015/02}ST_Number'.",
          "spec_ref"=>"http://3mf.io/wp-content/uploads/2016/03/3MFcoreSpec_1.1.pdf#page=15",
          "caller"=>"xml_val.rb:33"
        )
      ]
    }

    let(:xml) {
      Nokogiri::XML('<?xml version="1.0" encoding="utf-8"?>
      <model xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" unit="millimeter" xmlns:m="http://schemas.microsoft.com/3dmanufacturing/material/2015/02">
      	<resources>
      		<object id="1" name="Cube" type="model">
      			<mesh>
      				<vertices>
      					<vertex x="0" y="0" z="0" />
      					<vertex x="10,000" y="0" z="0" />
      					<vertex x="10,000" y="20,000" z="0" />
      					<vertex x="0" y="20,000" z="0" />
      					<vertex x="0" y="0" z="30,000" />
      					<vertex x="10,000" y="0" z="30,000" />
      					<vertex x="10,000" y="20,000" z="30,000" />
      					<vertex x="0" y="20,000" z="30,000" />
      				</vertices>
      				<triangles>
      					<triangle v1="2" v2="1" v3="0" />
      					<triangle v1="0" v2="3" v3="2" />
      					<triangle v1="4" v2="5" v3="6" />
      					<triangle v1="6" v2="7" v3="4" />
      					<triangle v1="0" v2="1" v3="5" />
      					<triangle v1="5" v2="4" v3="0" />
      					<triangle v1="2" v2="3" v3="7" />
      					<triangle v1="7" v2="6" v3="2" />
      					<triangle v1="1" v2="2" v3="6" />
      					<triangle v1="6" v2="5" v3="1" />
      					<triangle v1="3" v2="0" v3="4" />
      					<triangle v1="4" v2="7" v3="3" />
      				</triangles>
      			</mesh>
      		</object>
      	</resources>
      	<build>
      		<item objectid="1" />
      	</build>
      </model>
      ')
    }

    it "should give an error" do

      allow(Nokogiri::XML::Schema).to receive_message_chain("new.validate") { validation_result }

      XmlVal.validate(zipentry, xml, SchemaFiles::SchemaTemplate)
      expect(Log3mf.entries(:error)).to_not be_empty
      expected_msg = errormap.fetch(:has_commas_for_floats.to_s)["msg"]
      expect(Log3mf.entries(:error).any?{|error| error[:message].include? (interpolate(expected_msg, {})) }).to be true
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
