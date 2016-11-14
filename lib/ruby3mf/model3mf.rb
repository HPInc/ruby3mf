class Model3mf

  def self.extract_paths(value)
    if value.is_a? Array
      value.map { |v| extract_paths(v) }
    else
      if value.is_a? Hash
        value[:path]
      else
        nil
      end
    end
  end

  def self.parse(document, zip_entry, relationships)
    model_hash = {}
    Log3mf.context "parsing model" do |l|
      begin
        # parse model
        doc = Nokogiri::XML(zip_entry.get_input_stream) do |config|
          config.strict.nonet.noblanks
        end

        l.info "We Found a Model, and it's XML!"
        model_hash = Hash.from_xml(doc)
      rescue Nokogiri::XML::SyntaxError => e
        l.fatal_error "Model file invalid XML. Exception #{e}"
        doc.errors.each { |error| l.error error }
      end

      l.context "verifying 3D payload required resources" do |l|
        # find all resources (that are not the object) in model_hash

        required_resources = []

        model_hash[:model][:resources].each do |key, value|
          required_resources << extract_paths(value)
        end

        required_resources.flatten!
        required_resources.compact!

        # for each, ensure that they exist in @relationships

        relationship_resources = relationships.map { |relationship| relationship[:target] }

        missing_resources = (required_resources - relationship_resources)
        if missing_resources.empty?
          l.info "All model required resources are defined in .rels relationship files."
        else
          missing_resources.each { |mr|
            l.error "Missing required resource: #{mr} Resource referenced in model, but not in .rels relationship file", page: 10
          }
        end

      end
    end
    model_hash
  end
end
