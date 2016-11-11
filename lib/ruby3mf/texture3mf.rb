class Texture3mf

  def self.parse(relationship_file, relationships)
    img_type = MimeMagic.by_magic(relationship_file.get_input_stream)
    Log3mf.context "Texture3mf" do |l|
      l.debug "texture is of type: #{img_type}"
      l.error "Expected a png or jpeg texture but the texture was of type #{img_type}", spec: :material, page: 16 unless ['image/png', 'image/jpeg'].include? img_type.type
    end

  end
end
