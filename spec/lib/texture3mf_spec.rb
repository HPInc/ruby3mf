require 'spec_helper'

describe Texture3mf do

  let(:zip_path)      { "spec/ruby3mf-testfiles/passing_cases/3d_payload_files.3mf" }
  let(:zip_file)      { Zip::File.open(zip_path) }

  let(:document)      { Document.read(zip_path) } 
  let(:relationships) { zip_file.glob('**/*.rels').map{|r| Relationships.parse(r)}.flatten }

  describe ".parse" do

    it "should have parse/build the model inside document" do

      allow(Texture3mf).to receive(:parse) { :texture }
 
      relationships.each do |rel|
        if rel.fetch(:target).include?(".texture") then
          target = rel.fetch(:target).gsub(/^\//, "")
          relationship_file = zip_file.glob(target).first
          expect(document.textures).to include( { rel_id: rel.fetch(:id), target: target, object: :texture } )
        end  
      end  
  
    end

  end
end