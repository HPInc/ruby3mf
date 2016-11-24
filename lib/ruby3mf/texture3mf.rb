class Texture3mf
  attr_accessor :name

  def initialize(document)
    @doc = document
  end

  def self.parse(document, relationship_file, relationships)

    t = new(document)
    t.name = relationship_file.name
    stream = relationship_file.get_input_stream
    img_type = MimeMagic.by_magic(stream)
    @bytes = stream.read
    Log3mf.context "Texture3mf" do |l|
      l.debug "texture is of type: #{img_type}"
      l.error "Expected a png or jpeg texture but the texture was of type #{img_type}", spec: :material, page: 16 unless ['image/png', 'image/jpeg'].include? img_type.type
    end
    t
  end

  def update(bytes)
    @doc.objects[name]=bytes
  end

  def contents
    @doc.objects[name] || @doc.contents_for(name)
  end

end
