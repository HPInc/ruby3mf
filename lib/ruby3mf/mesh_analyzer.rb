require_relative 'edge_list'


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
    list = EdgeList.new

    mesh = find_child(object, "mesh")
    if mesh
      triangles = find_child(mesh, "triangles")

      if triangles
        triangles.children.each do |triangle|
          v1 = triangle.attributes["v1"].to_s().to_i()
          v2 = triangle.attributes["v2"].to_s().to_i()
          v3 = triangle.attributes["v3"].to_s().to_i()

          list.add_edge(v1, v2)
          list.add_edge(v2, v3)
          list.add_edge(v3, v1)
        end

        return list.verify_edges()
      end
    end

    true
  end

  def self.validate(model_doc)
    Log3mf.context "validating geometry" do |l|
      root = model_doc.root
      node = root

      if node.name == "model"
        resources = find_child(node, "resources")

        if resources
          resources.children.each do |resource|
            if resource.name = "object" and resource.attributes["type"].to_s() == "model"
              result = validate_object(resource)

              if result == :bad_orientation
                l.fatal_error "Bad triangle orientation", page: 27
              elsif result == :hole
                l.fatal_error "Hole in model", page: 27
              elsif result == :nonmanifold
                l.fatal_error "Non-manifold edge in 3dmodel", page: 27
              end
            end
          end
        end
      end
    end
  end
end