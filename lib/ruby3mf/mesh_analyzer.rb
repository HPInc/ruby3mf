def find_child(node, child_name)
  node.children.each do |child|
    if child.name == child_name
      return child
    end
  end

  nil
end


class MeshAnalyzer

  def self.validate_object(object)

    Log3mf.context "verifying object" do |l|
      children = object.children.map { |child| child.name }
      have_override = object.attributes["pid"] or object.attributes["pindex"]
      l.error :object_with_components_and_pid if have_override && children.include?("components")
    end

    Log3mf.context "validating geometry" do |l|
      list = EdgeList.new

      # if a triangle has a pid, then the object needs a pid
      has_triangle_pid = false

      # mesh = find_child(object, "mesh")
      meshs = object.css('mesh')

      meshs.each do |mesh|

        # l.error :non_distinct_indices if mesh.css('triangle').map{ |triangle| [ triangle.attributes["v1"].value, triangle.attributes["v2"].value, triangle.attributes["v3"].value ] }.map(&:uniq).map(&:size).any?{ |v| v != 3 }

        # triangles = find_child(mesh, "triangles")
        triangles = mesh.css('triangle')

        triangles.each do |triangle|
          v1 = triangle.attributes["v1"].to_s.to_i
          v2 = triangle.attributes["v2"].to_s.to_i
          v3 = triangle.attributes["v3"].to_s.to_i

          if v1 == v2 || v2 == v3 || v3 == v1
            l.error :non_distinct_indices
          end

          list.add_edge(v1, v2)
          list.add_edge(v2, v3)
          list.add_edge(v3, v1)

          if not has_triangle_pid
            has_triangle_pid = triangle.attributes["pid"] != nil
          end
        end

        has_object_material = object.attributes["pid"] && object.attributes["pindex"]
        if has_triangle_pid and not has_object_material
          l.error :missing_object_pid
        end

        result = list.verify_edges()
        if result == :bad_orientation
          l.error :resource_3dmodel_orientation
        elsif result == :hole
          l.error :resource_3dmodel_hole
        elsif result == :nonmanifold
          l.error :resource_3dmodel_nonmanifold
        end

      end

    end
  end

  def self.validate(model_doc)
    # root = model_doc.root
    # node = root

    model_doc.css('object').each do |object|
      validate_object(object) if ["model", "solidsupport", nil, ""].any?{ |type| type == object.attributes['type'].to_s }
    end

    # if node.name == "model"
    #   resources = find_child(node, "resources")
    #
    #   if resources
    #     resources.children.each do |resource|
    #       if resource.name == "object" || ( resource.attributes["type"].to_s == "model" || resource.attributes["type"].to_s == "solidsupport" )
    #         validate_object(resource)
    #       end
    #     end
    #   end
    # end

  end
end
