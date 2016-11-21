require 'spec_helper'

describe Model3mf do

  let(:zip_path) 			{ "spec/ruby3mf-testfiles/passing_cases/3d_payload_files.3mf" }
  let(:zip_file) 			{ Zip::File.open(zip_path) }
 
  let(:document)   		{ Document.read(zip_path) }
 	let(:relationships) { zip_file.glob('**/*.rels').map{|r| Relationships.parse(r)}.flatten }

	describe ".parse" do

		it "should have parse/build the model inside document" do
	
      relationships.each do |rel|
        if rel.fetch(:target).include?(".model") then
          target = rel.fetch(:target).gsub(/^\//, "")
          relationship_file = zip_file.glob(target).first           
          model = { rel_id: rel.fetch(:id), target: target, object: Model3mf.parse(document, relationship_file, relationships) }
          expect(document.models).to include(model)
        end  
      end      

		end

	end
end