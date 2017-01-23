def find_child(node, child_name)
  node.children.each do |child|
    if child.name == child_name
      return child
    end
  end

  nil
end


class MeshAnalyzer

  def self.validate_object(object, includes_material)
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
        l.error :not_enough_triangles if triangles.count < 4

        if triangles
          triangles.each do |triangle|

            v1 = triangle.attributes["v1"].to_s.to_i
            v2 = triangle.attributes["v2"].to_s.to_i
            v3 = triangle.attributes["v3"].to_s.to_i

            unless includes_material
              l.context "validating property overrides" do |l|
                property_overrides = []
                property_overrides << triangle.attributes['p1'].to_s.to_i if triangle.attributes['p1']
                property_overrides << triangle.attributes['p2'].to_s.to_i if triangle.attributes['p2']
                property_overrides << triangle.attributes['p3'].to_s.to_i if triangle.attributes['p3']

                property_overrides.reject! { |prop| prop.nil? }
                l.error :has_base_materials_gradient unless property_overrides.uniq.size <= 1
              end
            end

            if v1 == v2 || v2 == v3 || v3 == v1
              l.error :non_distinct_indices
            end

            list.add_edge(v1, v2)
            list.add_edge(v2, v3)
            list.add_edge(v3, v1)
            unless has_triangle_pid
              has_triangle_pid = triangle.attributes["pid"] != nil
            end
          end

          if has_triangle_pid && !(object.attributes["pindex"] && object.attributes["pid"])
            l.error :missing_object_pid
          end

          result = list.verify_edges
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
  end

  def self.validate(model_doc, includes_material)
    model_doc.css('model/resources/object').select { |object| ['model', 'solidsupport', ''].include?(object.attributes['type'].to_s) }.each do |object|
      validate_object(object, includes_material)
    end
  end

end
