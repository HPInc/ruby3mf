require 'spec_helper'

describe MeshAnalyzer do

  # If the mesh is under an object of type “model” or “solidsupport”, it MUST have:

    # Manifold Edges: Every triangle edge in the mesh shares common vertex endpoints with the edge of exactly 1 other triangle.

    # Consistent Triangle Orientation: Every pair of adjacent triangles within the mesh MUST have the same orientation of the face normal toward the exterior of the mesh,
    # meaning that the order of declaration of the vertices on the shared edge MUST be in the opposite order.
    # For example, if Triangle1 has vertices ABC and Triangle2 has vertices DEF and Triangle1 and Triangle2 share the AB/DE edge,
    # then it MUST be the case that vertices A=E and vertices B=D (see figure 4-1 below). A triangle face normal (for triangle ABC,
    # in that order) throughout this specification is defined as a unit vector in the direction of the vector cross product (B - A) x (C - A). For example,
    #the triangles shown in figure 4-1 have normals pointing out of the page. If the applied transformation has a negative determinant, the vertex ordering of those triangles MUST be inverted in order to preserve the sign of the volume.

    # Outward-facing normals: All triangles MUST be oriented with normals that point away from the interior of the object.
    #Meshes with negative volume will not be printed (or will become voids), in accordance with the Positive fill rule defined in the next section.
    #In combination with the preceding two rules, a mesh is therefore a continuous surface without holes, gaps, open edges, or non-orientable surfaces (e.g. Klein bottle).

    describe ".validate_object" do

    end


    describe ".validate" do
      
    end

end
