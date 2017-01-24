class Document

  attr_accessor :types
  attr_accessor :type_overrides
  attr_accessor :relationships
  attr_accessor :models
  attr_accessor :thumbnails
  attr_accessor :textures
  attr_accessor :objects
  attr_accessor :parts
  attr_accessor :zip_filename

  # Relationship schemas
  MODEL_TYPE = 'http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel'
  THUMBNAIL_TYPE = 'http://schemas.openxmlformats.org/package/2006/relationships/metadata/thumbnail'
  TEXTURE_TYPE = 'http://schemas.microsoft.com/3dmanufacturing/2013/01/3dtexture'
  PRINT_TICKET_TYPE = 'http://schemas.microsoft.com/3dmanufacturing/2013/01/printticket'

  # Image Content Types
  THUMBNAIL_TYPES = %w[image/jpeg image/png].freeze
  TEXTURE_TYPES = %w[image/jpeg image/png application/vnd.ms-package.3dmanufacturing-3dmodeltexture].freeze

  # Relationship Type => Class validating relationship type
  RELATIONSHIP_TYPES = {
    MODEL_TYPE => {klass: 'Model3mf', collection: :models, valid_types: ['application/vnd.ms-package.3dmanufacturing-3dmodel+xml']},
    THUMBNAIL_TYPE => {klass: 'Thumbnail3mf', collection: :thumbnails, valid_types: THUMBNAIL_TYPES},
    TEXTURE_TYPE => {klass: 'Texture3mf', collection: :textures, valid_types: TEXTURE_TYPES},
    PRINT_TICKET_TYPE => {valid_types: ['application/vnd.ms-printing.printticket+xml']}
  }

  def initialize(zip_filename)
    self.models=[]
    self.thumbnails=[]
    self.textures=[]
    self.objects={}
    self.relationships={}
    self.types={}
    self.type_overrides={}
    self.parts=[]
    @zip_filename = zip_filename
  end

  #verify that each texture part in the 3MF is related to the model through a texture relationship in a rels file
  def self.validate_texture_parts(document, log)
    unless document.types.empty?
      document.parts.select { |part| TEXTURE_TYPES.include?(document.types[File.extname(part).strip.downcase[1..-1]]) }.each do |tfile|
        if document.textures.select { |f| f[:target] == tfile }.size == 0
          if document.thumbnails.select { |t| t[:target] == tfile }.size == 0
            log.context "part names" do |l|
              l.warning "#{tfile} appears to be a texture file but no rels file declares any relationship to the model", page: 13
            end
          end
        end
      end
    end
  end

  def self.read(input_file)

    m = new(input_file)
    begin
      Log3mf.context 'zip' do |l|
        begin
          Zip.warn_invalid_date = false

          # check for the general purpose flag set - if so, warn that 3mf may not work on some systems
          File.open(input_file, "r") do |file|
            if file.read[6] == "\b"
              l.warning 'File format: this file may not open on all systems'
            end
          end

          Zip::File.open(input_file) do |zip_file|

            l.info 'Zip file is valid'

            # check for valid, absolute URI's for each path name

            zip_file.each do |part|
              l.context "part names /#{part.name}" do |l|
                unless part.name.end_with? '[Content_Types].xml'
                  begin
                    u = URI part.name
                  rescue ArgumentError, URI::InvalidURIError
                    l.fatal_error "This NEVER Happens! mdw 12Jan2017"
                    l.error :err_uri_bad
                    next
                  end

                  u.path.split('/').each do |segment|
                    l.error :err_uri_hidden_file if (segment.start_with? '.') && !(segment.end_with? '.rels')
                  end
                  m.parts << '/' + part.name unless part.directory?
                end
              end
            end

            l.context 'content types' do |l|
              content_type_match = zip_file.glob('\[Content_Types\].xml').first
              if content_type_match
                m.types, m.type_overrides = ContentTypes.parse(content_type_match)
                model_extension = m.types.key('application/vnd.ms-package.3dmanufacturing-3dmodel+xml')
                model_extension = model_extension.downcase unless model_extension.nil?
                model_file = zip_file.glob("**/*.#{model_extension}").first
                l.error :no_3d_model, extension: model_extension if model_file.nil?
              else
                l.fatal_error 'Missing required file: [Content_Types].xml', page: 4
              end
            end

            l.context 'relationships' do |l|
              rel_file = zip_file.glob('_rels/.rels').first
              l.fatal_error :missing_dot_rels_file unless rel_file

              zip_file.glob('**/*.rels').each do |rel|
                m.relationships[rel.name] = Relationships.parse(rel)
              end
            end

            l.context "print tickets" do |l|
              print_ticket_types = m.relationships.flat_map { |k, v| v }.select { |rel| rel[:type] == PRINT_TICKET_TYPE }
              l.error :multiple_print_tickets if print_ticket_types.size > 1
            end

            l.context "relationship elements" do |l|
              m.relationships.each do |file_name, rels|
                rels.each do |rel|
                  l.context rel[:target] do |l|

                    begin
                      u = URI rel[:target]
                    rescue URI::InvalidURIError
                      l.error :err_uri_bad
                      next
                    end

                    l.error :err_uri_relative_path unless u.to_s.start_with? '/'

                    target = rel[:target].gsub(/^\//, "")
                    l.error :err_uri_empty_segment if target.end_with? '/' or target.include? '//'
                    l.error :err_uri_relative_path if target.include? '/../'
                    relationship_file = zip_file.glob(target).first
                    rel_type = rel[:type]

                    if relationship_file
                      relationship_type = RELATIONSHIP_TYPES[rel_type]
                      if relationship_type.nil?
                        l.warning :unsupported_relationship_type, type: rel[:type], target: rel[:target]
                      else
                        # check that relationships are valid; extensions and relationship types must jive
                        if m.type_overrides["/#{target}"]
                          content_type = m.type_overrides["/#{target}"]
                        else
                          extension = File.extname(target).strip.downcase[1..-1]
                          content_type = m.types[extension]
                        end
                        expected_content_type = relationship_type[:valid_types]

                        if (expected_content_type)
                          l.error :missing_extension_in_content_types, ext: extension unless content_type
                          l.error :resource_contentype_invalid, bt: content_type, rt: rel[:target] unless (!content_type.nil? && expected_content_type.include?(content_type))
                        else
                          l.info "found unrecognized relationship type: #{rel_type}"
                        end

                        unless relationship_type[:klass].nil?
                          m.send(relationship_type[:collection]) << {
                            rel_id: rel[:id],
                            target: rel[:target],
                            object: Object.const_get(relationship_type[:klass]).parse(m, relationship_file)
                          }
                        end
                      end
                    else
                      l.error "Relationship Target file #{rel[:target]} not found", page: 11
                    end
                  end
                end
              end
            end

            validate_texture_parts(m, l)
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

      File.open(output_file, 'wb') { |f| f.write(buffer.string) }

    end

  end

  def contents_for(path)
    Zip::File.open(zip_filename) do |zip_file|
      zip_file.glob(path).first.get_input_stream.read
    end
  end

  def type_for(path)
    extn = File.extname(path)
    base = path[0..-(extn.length+1)]
    extn = extn.tr('.', '')

    override = type_overrides[path]
    if override
      override
    else
      types[extn]
    end
  end

end
