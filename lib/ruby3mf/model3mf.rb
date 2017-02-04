class Model3mf

  MATERIAL_EXTENSION = 'http://schemas.microsoft.com/3dmanufacturing/material/2015/02'
  SLICE_EXTENSION = 'http://schemas.microsoft.com/3dmanufacturing/slice/2015/07'
  PRODUCTION_EXTENSION = 'http://schemas.microsoft.com/3dmanufacturing/production/2015/06'

  KNOWN_EXTENSIONS = {
      MATERIAL_EXTENSION => {name: '3MF Materials and Properties Extension', supported: false},
      SLICE_EXTENSION => {name: '3MF Slice Extension', supported: false},
      PRODUCTION_EXTENSION => {name: '3MF Production Extension', supported: false}
  }.freeze

  VALID_CORE_METADATA_NAMES = ['Title', 'Designer', 'Description', 'Copyright', 'LicenseTerms', 'Rating', 'CreationDate', 'ModificationDate'].freeze

  def self.parse(document, zip_entry)
    model_doc = nil

    Log3mf.context "parsing model" do |l|
      begin
        model_doc = XmlVal.validate_parse(zip_entry, SchemaFiles::SchemaTemplate)
      rescue Nokogiri::XML::SyntaxError => e
        l.fatal_error :model_invalid_xml, e: e
      end

      l.context "verifying supported extensions" do |l|
        model_doc.css("//model").first.namespaces.each do |prefix, uri|
          unless prefix == "xmlns"
            ext = KNOWN_EXTENSIONS[uri]
            if ext.nil? || !ext[:supported]
              l.warning :unsupported_extension, ext: (ext.nil? ? uri : ext[:name])
            end
          end
        end
      end

      l.context "verifying requiredextensions" do |l|
        model_doc.css("//model").map{|node| node.attributes["requiredextensions"]}.compact.each do |required_extension|
          required_extension.value.split(" ").each do |ns|
            namespace_uri = model_doc.namespaces["xmlns:#{ns}"]
            l.error :missing_extension_namespace_uri, ns: ns unless namespace_uri
          end
        end
      end

      l.context "verifying 3D payload required resources" do |l|
        # results = model_doc.css("model resources m:texture2d")
        required_resources = model_doc.css("//model//resources//*[path]").collect { |n| n["path"] }
        required_resources += model_doc.css("//model//resources//object[thumbnail]").collect { |n| n["thumbnail"] }

        # for each, ensure that they exist in m.relationships
        relationship_resources = []
        rel_file = "#{Pathname(zip_entry.name).dirname.to_s}/_rels/#{File.basename(zip_entry.name)}.rels"
        relationships = document.relationships[rel_file]
        unless (relationships.nil?)
          relationship_resources = relationships.map { |relationship| relationship[:target] }
        end

        missing_resources = (required_resources - relationship_resources)
        if missing_resources.empty?
          l.info "All model required resources are defined in .rels relationship files."
        else
          missing_resources.each { |mr|
            l.error :model_resource_not_in_rels, mr: mr
          }
        end

      end

      l.context 'verifying resources' do |l|
        resources = model_doc.root.css("resources")
        if resources
          ids = resources.children.map { |child| child.attributes['id'].to_s if child.attributes['id'] }
          l.error :resource_id_collision if ids.uniq.size != ids.size
          pids = resources.children.map { |child| child.attributes['pid'].to_s }
          missing_pids = pids.select { |pid| !pid.empty? and !ids.include? pid }
          missing_pids.each do |p|
            l.error :resource_pid_missing, pid: p
          end
        end
      end

      l.context "verifying build items" do |l|

        l.error :build_with_other_item if model_doc.css('build/item').map { |x| x.attributes["objectid"].value }.map{ |id|  model_doc.search(".//xmlns:object[@id=$id][@type=$type]", nil, { :id => id, :type => 'other' } ) }.flatten.any?

      end

      l.context "checking metadata" do |l|
        metadata_names = model_doc.root.css("metadata").map { |met| met['name'] }
        l.error :metadata_elements_with_same_name unless metadata_names.uniq!.nil?

        unless (metadata_names - VALID_CORE_METADATA_NAMES).empty?
          extra_names = metadata_names - VALID_CORE_METADATA_NAMES
          ns_names = extra_names.select { |n| n.include? ':' }

          l.error :invalid_metadata_under_defaultns unless (extra_names - ns_names).empty?

          unless ns_names.empty?
            prefixes = model_doc.root.namespace_definitions.map { |defs| defs.prefix }.reject { |pre| pre.nil? }
            l.error :invalid_metadata_name unless (ns_names.collect { |i| i.split(':').first } - prefixes).empty?
          end
        end
      end

      includes_material = model_doc.namespaces.values.include?(MATERIAL_EXTENSION)
      MeshAnalyzer.validate(model_doc, includes_material)

      l.context "verifying triangle normal" do |l|
        model_doc.css('model/resources/object').select { |object| ['model', 'solidsupport', ''].include?(object.attributes['type'].to_s) }.each do |object|
          meshes = object.css('mesh')
          meshes.each do |mesh|
            processor = MeshNormalAnalyzer.new(mesh)
            l.error :inward_facing_normal if processor.found_inward_triangle
          end
        end
      end
    end
    model_doc
  end
end
