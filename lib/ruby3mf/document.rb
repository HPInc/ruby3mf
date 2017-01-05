class Document

  attr_accessor :types
  attr_accessor :relationships
  attr_accessor :models
  attr_accessor :thumbnails
  attr_accessor :textures
  attr_accessor :objects
  attr_accessor :zip_filename

  # Relationship Type => Class validating relationship type
  RELATIONSHIP_TYPES = {
    'http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel' => {klass: 'Model3mf', collection: :models},
    'http://schemas.openxmlformats.org/package/2006/relationships/metadata/thumbnail' => {klass: 'Thumbnail3mf', collection: :thumbnails},
    'http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture' => {klass: 'Texture3mf', collection: :textures}
  }

  def initialize(zip_filename)
    self.models=[]
    self.thumbnails=[]
    self.textures=[]
    self.objects={}
    self.relationships=[]
    self.types=[]
    @zip_filename = zip_filename
  end

  def self.read(input_file)

    m = new(input_file)
    begin
      Log3mf.context "zip" do |l|
        begin
          Zip.warn_invalid_date = false

          # check for the general purpose flag set - if so, warn that 3mf may not work on some systems
          if File.read(input_file)[6] == "\b"
            l.warning "File format: this file may not open on all systems"
          end

          Zip::File.open(input_file) do |zip_file|

            l.info "Zip file is valid"

            # check for valid, absolute URI's for each path name

            zip_file.each do |part|

              l.context "part names /#{part.name}" do |l|
                unless (part.name == '[Content_Types].xml')
                  begin
                    u = URI "/#{part.name}"
                  rescue ArgumentError
                    # :err_uri_bad
                    l.error 'Path names must be valid Open Package Convention URIs or IRIs', page: 13
                    next
                  end

                  #No segement of a part name may be empty or start with '.' except for the package relations part (_rels/.rels)
                  u.component.each do |segment|
                    # :err_uri_empty_segment
                    if segment.nil?
                      l.error 'No segment of a 3MF part name path may be empty', page: 13
                    end
                    if segment.to_s.start_with? '.'
                      #ignore .rels files, misnamed .rels should result in "missing .rels error" later
                      unless segment.to_s.end_with? '.rels'
                        # :err_uri_invalid_name
                        l.error "Other than /_rels/.rels, no segment of a 3MF part name may start with the '.' character", page: 13
                      end
                    end
                  end
                end
              end
            end

            l.context "content types" do |l|
              # 1. Get Content Types
              content_type_match = zip_file.glob('\[Content_Types\].xml').first
              if content_type_match
                m.types = ContentTypes.parse(content_type_match)
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

              zip_file.glob('**/*.rels').each do |rel|
                m.relationships += Relationships.parse(rel)
              end
            end

            l.context "relationship elements" do |l|
              # 3. Validate all relationships
              m.relationships.each do |rel|
                l.context rel[:target] do |l|

                  begin
                    u = URI rel[:target]
                  rescue ArgumentError
                    # :err_uri_bad
                    l.error 'Part names must be valid Open Package Convention URIs or IRIs', page: 13
                    next
                  end

                  #URI:relative? and .absolute? seem to be giving the wrong answer
                  unless u.to_s.start_with? '/'
                    # :err_uri_relative_path
                    puts "Relative path is #{u.to_s}"
                    l.error 'Part names must not include relative paths', page: 13
                  end

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
                        object: Object.const_get(relationship_type[:klass]).parse(m, relationship_file)
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
        end
      end
    rescue Log3mf::FatalError
      #puts "HALTING PROCESSING DUE TO FATAL ERROR"
      return nil
    end
  end

  def write(output_file = nil)
    output_file = zip_filename if output_file.nil?

    Zip::File.open(zip_filename) do |input_zip_file|

      buffer = Zip::OutputStream.write_buffer do |out|
        input_zip_file.entries.each do |e|
          if e.directory?
            out.copy_raw_entry(e)
          else
            out.put_next_entry(e.name)
            if objects[e.name]
              out.write objects[e.name]
            else
              out.write e.get_input_stream.read
            end
          end
        end
      end

      File.open(output_file, "wb") { |f| f.write(buffer.string) }

    end

  end

  def contents_for(path)
    Zip::File.open(zip_filename) do |zip_file|
      zip_file.glob(path).first.get_input_stream.read
    end
  end

end
