require 'spec_helper'

describe Hash do

  let(:zip_entry) { double('ZipEntry') }

  let(:model_content) {
    '<?xml version="1.0" encoding="UTF-8"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel" />
    </Relationships>'
  }

  let(:complex_model_content) {
    '<?xml version="1.0" encoding="UTF-8"?>
    <model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
      <resources>
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
      </resources>
      <build>
        <item objectid="1" />
      </build>
    </model>'
  }

  let(:doc) { Nokogiri::XML(zip_entry.get_input_stream) }

  it "should parse properly a simple xml content" do
    allow(zip_entry).to receive(:get_input_stream).and_return(model_content)

    expect(Hash.from_xml(doc).dig(:Relationships)).to eq( { :Relationship=>{:Target=>"/3D/3dmodel.model", :Id=>"rel0", :Type=>"http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel" } }  )
    expect(Hash.from_xml(doc).dig(:Relationships, :Relationship)).to eq( { :Target=>"/3D/3dmodel.model", :Id=>"rel0", :Type=>"http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel" } )
    expect(Hash.from_xml(doc).dig(:Relationships, :Relationship, :Target)).to eq("/3D/3dmodel.model")
  end

  it "should parse a more complex xml content" do
    allow(zip_entry).to receive(:get_input_stream).and_return(complex_model_content)

    expect(Hash.from_xml(doc).dig(:model)).to eq(
      { :unit=>"millimeter", :lang=>"en-US", :resources => {:texture=>[{:id=>"0", :path=>"/3D/Texture/texture1.texture", :width=>"425", :height=>"425", :depth=>"1", :contenttype=>"image/jpeg"}, {:id=>"1", :path=>"/3D/Texture/texture2.texture", :width=>"235", :height=>"208", :depth=>"1", :contenttype=>"image/jpeg"}], :object=>{:id=>"1", :type=>"model", :mesh=>{:vertices=>{:vertex=>[{:x=>"0", :y=>"0", :z=>"0"}, {:x=>"10", :y=>"0", :z=>"0"}, {:x=>"10", :y=>"20", :z=>"0"}, {:x=>"0", :y=>"20", :z=>"0"}, {:x=>"0", :y=>"0", :z=>"30"}, {:x=>"10", :y=>"0", :z=>"30"}, {:x=>"10", :y=>"20", :z=>"30"}, {:x=>"0", :y=>"20", :z=>"30"}]}, :triangles=>{:triangle=>[{:v1=>"3", :v2=>"2", :v3=>"1"}, {:v1=>"1", :v2=>"0", :v3=>"3"}, {:v1=>"4", :v2=>"5", :v3=>"6"}, {:v1=>"6", :v2=>"7", :v3=>"4"}, {:v1=>"0", :v2=>"1", :v3=>"5"}, {:v1=>"5", :v2=>"4", :v3=>"0"}, {:v1=>"1", :v2=>"2", :v3=>"6"}, {:v1=>"6", :v2=>"5", :v3=>"1"}, {:v1=>"2", :v2=>"3", :v3=>"7"}, {:v1=>"7", :v2=>"6", :v3=>"2"}, {:v1=>"3", :v2=>"0", :v3=>"4"}, {:v1=>"4", :v2=>"7", :v3=>"3"}]}}}}, :build=>{:item=>{:objectid=>"1"}}}
    )

    expect(Hash.from_xml(doc).dig(:model, :resources)).to eq(
      {:texture=>[{:id=>"0", :path=>"/3D/Texture/texture1.texture", :width=>"425", :height=>"425", :depth=>"1", :contenttype=>"image/jpeg"}, {:id=>"1", :path=>"/3D/Texture/texture2.texture", :width=>"235", :height=>"208", :depth=>"1", :contenttype=>"image/jpeg"}], :object=>{:id=>"1", :type=>"model", :mesh=>{:vertices=>{:vertex=>[{:x=>"0", :y=>"0", :z=>"0"}, {:x=>"10", :y=>"0", :z=>"0"}, {:x=>"10", :y=>"20", :z=>"0"}, {:x=>"0", :y=>"20", :z=>"0"}, {:x=>"0", :y=>"0", :z=>"30"}, {:x=>"10", :y=>"0", :z=>"30"}, {:x=>"10", :y=>"20", :z=>"30"}, {:x=>"0", :y=>"20", :z=>"30"}]}, :triangles=>{:triangle=>[{:v1=>"3", :v2=>"2", :v3=>"1"}, {:v1=>"1", :v2=>"0", :v3=>"3"}, {:v1=>"4", :v2=>"5", :v3=>"6"}, {:v1=>"6", :v2=>"7", :v3=>"4"}, {:v1=>"0", :v2=>"1", :v3=>"5"}, {:v1=>"5", :v2=>"4", :v3=>"0"}, {:v1=>"1", :v2=>"2", :v3=>"6"}, {:v1=>"6", :v2=>"5", :v3=>"1"}, {:v1=>"2", :v2=>"3", :v3=>"7"}, {:v1=>"7", :v2=>"6", :v3=>"2"}, {:v1=>"3", :v2=>"0", :v3=>"4"}, {:v1=>"4", :v2=>"7", :v3=>"3"}]}}}}
    )

    expect(Hash.from_xml(doc).dig(:model, :resources, :texture)).to eq(
       [{:id=>"0", :path=>"/3D/Texture/texture1.texture", :width=>"425", :height=>"425", :depth=>"1", :contenttype=>"image/jpeg"}, {:id=>"1", :path=>"/3D/Texture/texture2.texture", :width=>"235", :height=>"208", :depth=>"1", :contenttype=>"image/jpeg"}]
    )

    expect(Hash.from_xml(doc).dig(:model, :resources, :object)).to eq(
       {:id=>"1", :type=>"model", :mesh=>{:vertices=>{:vertex=>[{:x=>"0", :y=>"0", :z=>"0"}, {:x=>"10", :y=>"0", :z=>"0"}, {:x=>"10", :y=>"20", :z=>"0"}, {:x=>"0", :y=>"20", :z=>"0"}, {:x=>"0", :y=>"0", :z=>"30"}, {:x=>"10", :y=>"0", :z=>"30"}, {:x=>"10", :y=>"20", :z=>"30"}, {:x=>"0", :y=>"20", :z=>"30"}]}, :triangles=>{:triangle=>[{:v1=>"3", :v2=>"2", :v3=>"1"}, {:v1=>"1", :v2=>"0", :v3=>"3"}, {:v1=>"4", :v2=>"5", :v3=>"6"}, {:v1=>"6", :v2=>"7", :v3=>"4"}, {:v1=>"0", :v2=>"1", :v3=>"5"}, {:v1=>"5", :v2=>"4", :v3=>"0"}, {:v1=>"1", :v2=>"2", :v3=>"6"}, {:v1=>"6", :v2=>"5", :v3=>"1"}, {:v1=>"2", :v2=>"3", :v3=>"7"}, {:v1=>"7", :v2=>"6", :v3=>"2"}, {:v1=>"3", :v2=>"0", :v3=>"4"}, {:v1=>"4", :v2=>"7", :v3=>"3"}]}}}
    )

    expect(Hash.from_xml(doc).dig(:model, :resources, :object, :mesh, :vertices)).to eq(
      {:vertex=>[{:x=>"0", :y=>"0", :z=>"0"}, {:x=>"10", :y=>"0", :z=>"0"}, {:x=>"10", :y=>"20", :z=>"0"}, {:x=>"0", :y=>"20", :z=>"0"}, {:x=>"0", :y=>"0", :z=>"30"}, {:x=>"10", :y=>"0", :z=>"30"}, {:x=>"10", :y=>"20", :z=>"30"}, {:x=>"0", :y=>"20", :z=>"30"}]}
    )

  end

end
