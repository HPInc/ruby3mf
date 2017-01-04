require_relative '../spec_helper.rb'

describe 'Integration Tests' do

  context 'with passing test case' do
    Dir.glob('spec/ruby3mf-testfiles/passing_cases/*') { |test_file|
      context test_file do
        before do
          allow(GlobalXMLValidations).to receive(:validate).and_return(false)
          Document.read(test_file)
        end
        it "should NOT have errors" do
          expect(Log3mf.count_entries(:error, :fatal_error)).to eq(0)
        end
      end
    }
  end

  context 'failing test cases' do
    let(:failures) { {
      '3d_model_invalid_xml.3mf' => [["zip/relationship elements//3D/3dmodel.model/parsing model", :fatal_error, "Model file invalid XML. Exception Start tag expected, '<' not found", {}]],
      '3d_payload_files.3mf' => [["zip/relationship elements//3D/Texture/texture2.texture", :error, "Relationship Target file /3D/Texture/texture2.texture not found", {:page => 11}]],
      'content_types_invalid_xml.3mf' => [["zip/content types/parse", :error, "[Content_Types].xml file is not valid XML. Start tag expected, '<' not found", {:page => 15}]],
      'dot_rels_file_has_invalid_xml.3mf' => [["zip/relationships/parsing relationships", :error, "Relationships (.rel) file is not a valid XML file: Start tag expected, '<' not found", {:page => 4}]],
      'dot_rels_file_missing_relationships_element.3mf' => [["zip/relationships/parsing relationships", :error, ".rels XML must have &lt;Relationships&gt; root element", {:page => 4}]],
      'dot_rels_file_no_relationship_element.3mf' => [["zip/relationships/parsing relationships", :error, "No relationship elements found", {:page => 4}]],
      'invalid_content_type.3mf' => [["zip/content types/parse", :error, "[Content_Types].xml is missing required ContentType \"application/vnd.openxmlformats-package.relationships+xml\"", {:page => 10}]],
      'invalid_startpart_type.3mf' => [["zip/relationships/parsing relationships/Verifying StartPart", :error, "rels/.rels Relationship file has an invalide attribute type for the root 3D Model (StartPart).\n                         The correct attribute type should be \"http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel\"", {:page => 10}]],
      'invalid_thumbnail_colorspace.3mf' => [["zip/relationship elements//Metadata/thumbnail.jpg/Thumbnail3mf", :fatal_error, "CMYK JPEG images must not be used for the thumbnail", :page => 36]],
      'invalid_thumbnail_file_type.3mf' => [["zip/relationship elements//Metadata/thumbnail.gif/Thumbnail3mf", :error, "Expected a png or jpeg thumbnail but the thumbnail was of type image/gif", {:page => 12}]],
      'invalid_texture_file_type.3mf' => [["zip/relationship elements//3D/Textures/texture.gif/Texture3mf", :error, "Expected a png or jpeg texture but the texture was of type image/gif", {:spec => :material, :page => 16}]],
      'missing_content_types.3mf' => [["zip/content types", :error, "Missing required file: [Content_Types].xml", {:page => 4}]],
      'missing_dot_rels_file.3mf' => [["zip/relationships", :fatal_error, "Missing required file _rels/.rels", {:page => 4}]],
      'missing_rels_entry_for_resources.3mf' => [["zip/relationship elements//3D/3dmodel.model/parsing model/verifying 3D payload required resources", :error, "Missing required resource: /3D/Texture/texture1.texture Resource referenced in model, but not in .rels relationship file", {:page => 10}]],
      'missing_rels_folder.3mf' => [["zip/relationships", :fatal_error, "Missing required file _rels/.rels", {:page => 4}]],
      'no_3d_model.3mf' => [["zip/relationship elements//3D/3dmodel.model", :error, "Relationship Target file /3D/3dmodel.model not found", {:page => 11}]],
      'not_a_zip.3mf' => [["zip", :fatal_error, "File provided is not a valid ZIP archive", {:page => 9}]],
      'invalid_texture_path_in_model.3mf' => [["zip/relationship elements//3D/3dmodel.model/parsing model/verifying 3D payload required resources", :error, "Missing required resource: /3D/Textures/wrong-file-name.png Resource referenced in model, but not in .rels relationship file", {:page => 10}]],
      'zero_size_texture.3mf' => [["zip/relationship elements//3D/Textures/texture.png/Texture3mf", :fatal_error, "Texture file must be valid image file", {:spec => :material, :page => 16}]],
      'bad_image_type.3mf' => [["zip/relationship elements//3D/3dmodel.model/parsing model/verifying 3D payload required resources/verifying 3D resource types", :error, "resource in model has invalid contenttype image/ping", {:page => 10}]],
      'has_xml_space_attribute.3mf' => [["foo", :error, "found an xml:space attribute when it is not allowed", {:page => 16}]]
    } }

    context 'global validations' do
      let(:global_failures) {
        [["zip/content types/parse/global xml validations", :error, "found an xml:space attribute when it is not allowed", {:page => 16}]]
      }

      before do
        Document.read('spec/ruby3mf-testfiles/failing_cases/has_xml_space_attribute.3mf')
      end

      it 'should have errors' do
        expect(Log3mf.count_entries(:error)).to be >= 1
      end

      it 'should log the correct errors' do
        expect(Log3mf.entries(:error)).to eq(global_failures)
      end
    end


    Dir.glob('spec/ruby3mf-testfiles/failing_cases/*') { |test_file|
      unless test_file == 'spec/ruby3mf-testfiles/failing_cases/has_xml_space_attribute.3mf'
        context test_file do
          before do
            allow(GlobalXMLValidations).to receive(:validate).and_return(false)
            Document.read(test_file)
          end

          it "should have errors" do
            expect(Log3mf.count_entries(:error, :fatal_error)).to be >= 1
            expect(Log3mf.count_entries(:fatal_error)).to be <= 1
          end

          it 'should log the correct errors' do
            expect(Log3mf.entries(:error, :fatal_error)).to eq(failures[test_file.split('/').last])
          end
        end
      end
    }
  end

end

