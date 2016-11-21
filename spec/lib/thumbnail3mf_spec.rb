require 'spec_helper'

describe Thumbnail3mf do

  let(:zip_path)      { "spec/ruby3mf-testfiles/passing_cases/cylinder.3mf" }
  let(:zip_file)      { Zip::File.open(zip_path) }

  let(:document)      { Document.read(zip_path) } 
  let(:relationships) { zip_file.glob('**/*.rels').map{|r| Relationships.parse(r)}.flatten }

  describe ".parse" do

    xit "should have parse/build the model inside document" do

      allow(Thumbnail3mf).to receive(:parse) { :thumbnail }
 
      relationships.each do |rel|
        if rel.fetch(:target).include?("thumbnail") then
          target = rel.fetch(:target).gsub(/^\//, "")
          relationship_file = zip_file.glob(target).first
          expect(document.textures).to include( { rel_id: rel.fetch(:id), target: target, object: :thumbnail } )
        end  
      end  
  
    end

  end
end