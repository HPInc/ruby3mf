require_relative 'mesh_analyzer'

class Model3mf

  def self.parse(document, zip_entry)
    model_doc = nil

    Log3mf.context "parsing model" do |l|
      begin
        model_doc = GlobalXMLValidations.validate_parse(zip_entry)
      rescue Nokogiri::XML::SyntaxError => e
        l.fatal_error "Model file invalid XML. Exception #{e}"
      end

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
            l.error :model_resource_not_in_rels, mr: mr
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

      l.context "verifying resources" do |l|
        resources = find_child(model_doc.root, "resources")
        if resources
          ids = resources.children.map { |child| child.attributes["id"].to_s() if child.attributes["id"] }
          l.error :resource_id_collision if ids.uniq.size != ids.size
        end
      end

      l.context "verifying model structure" do |l|
        root = model_doc.root
        l.error :root_3dmodel_element_not_model if root.name != "model"

        children = model_doc.root.children.map { |child| child.name }
        l.error :missing_model_children unless children.include?("resources") && children.include?("build")
      end

      l.context "verifying build items" do |l|
        build = find_child(model_doc.root, "build")
        if build
          items = build.children.map { |child| child.attributes["objectid"].to_s() if child.name == "item"}

          resources = find_child(model_doc.root, "resources")
          resources.children.each do |resource|
            if resource.name == "object"
              object_id = resource.attributes["id"].to_s()
              l.error :build_with_other_item if resource.attributes["type"].to_s() == "other" and items.include?(object_id)
            end
          end
        end
      end

      MeshAnalyzer.validate(model_doc)
    end
    model_doc
  end
end
