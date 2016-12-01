class Thumbnail3mf

  def self.parse(doc, relationship_file)
    img_type = MimeMagic.by_magic(relationship_file.get_input_stream)
    Log3mf.context "Thumbnail3mf" do |l|
      l.fatal_error "thumbnail file must be valid image file", page: 10 unless img_type
      l.debug "thumbnail is of type: #{img_type}"
      l.error "Expected a png or jpeg thumbnail but the thumbnail was of type #{img_type}", page: 12 unless ['image/png', 'image/jpeg'].include? img_type.type
    end

  end
end
