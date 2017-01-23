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

      meshs = object.css('mesh')
      meshs.each do |mesh|

        triangles = mesh.css("triangle")

        if triangles
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
            if !has_triangle_pid
              has_triangle_pid = triangle.attributes["pid"] != nil
            end
          end

          if has_triangle_pid && !(object.attributes["pindex"] && object.attributes["pid"])
            l.error :missing_object_pid
          end

          result = list.verify_edges
          if result == :bad_orientation
            l.fatal_error :resource_3dmodel_orientation
          elsif result == :hole
            l.fatal_error :resource_3dmodel_hole
          elsif result == :nonmanifold
            l.fatal_error :resource_3dmodel_nonmanifold
          end

        end
      end
    end
  end

  def self.validate(model_doc)
    model_doc.css('model/resources/object').select{ |object| ['model', 'solidsupport', 'support', 'other', ''].include?(object.attributes['type'].to_s) }.each do |object|
      validate_object(object)
    end
  end

end
