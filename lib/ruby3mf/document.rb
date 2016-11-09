class Document

  attr_accessor :models
  attr_accessor :thumbnails
  # attr_accessor :textures

  # Relationship Type => Class validating relationship type
  RELATIONSHIP_TYPES = {
    'http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel' => {klass: 'Model3mf', collection: :models},
    'http://schemas.openxmlformats.org/package/2006/relationships/metadata/thumbnail' => {klass: 'Thumbnail3mf', collection: :thumbnails} #,
    # 'http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture' => {klass: 'Texture3d', collection: :textures}
  }

  def initialize
    self.models=[]
    self.thumbnails=[]
    # self.textures=[]
  end

  def self.read(input_file)
    m=self.new
    begin
      Log3mf.context "examining zip" do |l|
        begin
          Zip::File.open(input_file) do |zip_file|

            # puts "Zip contents:"
            # zip_file.each do |entry|
            #   puts entry
            # end

            l.info "Zip file is valid"

            l.context "content types" do |l|
              # 1. Get Content Types
              content_type_match = zip_file.glob('\[Content_Types\].xml').first
              if content_type_match
                @types = ContentTypes.parse(content_type_match)
              else
                l.error "Missing required file: [Content_Types].xml", page: 4
              end
            end

            l.context "relationships" do |l|
              # 2. Get Relationships
              # rel_folders = zip_file.glob('**/_rels')
              # l.fatal_error "Missing any _rels folder", page: 4 unless rel_folders.size>0

              # 2.1 Validate that the top level _rels/.rel file exists
              rel_file = zip_file.glob('_rels/.rels').first
              l.fatal_error "Missing required file _rels/.rels", page: 4 unless rel_file

              @relationships=[]
              zip_file.glob('**/*.rels').each do |rel|
                @relationships += Relationships.parse(rel)
              end
            end

            l.context "relationship elements" do |l|
              # 3. Validate all relationships
              @relationships.each do |rel|
                l.context rel[:target] do |l|
                  target = rel[:target].gsub(/^\//, "")
                  relationship_file = zip_file.glob(target).first

                  if relationship_file
                    relationship_type = RELATIONSHIP_TYPES[rel[:type]]
                    if relationship_type.nil?
                      l.warning "Relationship file defines a type that is not used in a normal 3mf file: #{rel[:type]}. Ignoring relationship."
                    else
                      m.send(relationship_type[:collection]) << {
                        rel_id: rel[:id],
                        target: rel[:target],
                        object: Object.const_get(relationship_type[:klass]).parse(relationship_file, @relationships)
                      }
                    end
                  else
                    l.error "Relationship Target file #{rel[:target]} not found", page: 11
                  end
                end
              end
            end
          end
          return m
        rescue Zip::Error
          l.fatal_error 'File provided is not a valid ZIP archive', page: 9
          return nil
        end
      end
    rescue Log3mf::FatalError
      #puts "HALTING PROCESSING DUE TO FATAL ERROR"
      return nil
    end
  end
end
