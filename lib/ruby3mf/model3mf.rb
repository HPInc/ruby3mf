class Model3mf

  def self.parse(document, zip_entry)
    model_doc = nil

    Log3mf.context "parsing model" do |l|
      begin
        model_doc = Nokogiri::XML(zip_entry.get_input_stream) do |config|
          config.strict.nonet.noblanks
        end
        l.info "We Found a Model, and it's XML!"
      rescue Nokogiri::XML::SyntaxError => e
        l.fatal_error "Model file invalid XML. Exception #{e}"
      end

      GlobalXMLValidations.validate(model_doc)

      l.context "verifying 3D payload required resources" do |l|
        # results = model_doc.css("model resources m:texture2d")
        required_resources = model_doc.css("//model//resources//*[path]").collect { |n| n["path"] }

        # for each, ensure that they exist in m.relationships
        relationship_resources = document.relationships.map { |relationship| relationship[:target] }

        missing_resources = (required_resources - relationship_resources)
        if missing_resources.empty?
          l.info "All model required resources are defined in .rels relationship files."
        else
          missing_resources.each { |mr|
            l.error "Missing required resource: #{mr} Resource referenced in model, but not in .rels relationship file", page: 10
          }
        end

        l.context "verifying 3D resource types" do |l|
          model_types = model_doc.css("//model//resources//*[path]").collect { |t| t["contenttype"] }

          #for each, ensure they exist in ContentTypes
          all_types = document.types.map { |t, v| v }

          bad_types = (model_types - all_types)
          if bad_types.empty?
            l.info "All model resource contenttypes are valid"
          else
            bad_types.each { |bt|
              l.error :resource_contentype_invalid, bt: bt
            }
          end
        end

      end
    end
    model_doc
  end
end
