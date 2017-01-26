class MeshNormalAnalyzer

  def initialize(mesh)
    @vertices = []
    @intersections = []

    vertices_node = mesh.css("vertices")
    vertices_node.children.each do |vertex_node|
      if vertex_node.attributes.count > 0
        x = vertex_node.attributes['x'].to_s.to_f
        y = vertex_node.attributes['y'].to_s.to_f
        z = vertex_node.attributes['z'].to_s.to_f
        @vertices << [x, y, z]
      end
    end

    @triangles = []
    triangles_node = mesh.css("triangles")
    triangles_node.children.each do |triangle_node|
      if triangle_node.attributes.count > 0
        v1 = triangle_node.attributes['v1'].to_s.to_i
        v2 = triangle_node.attributes['v2'].to_s.to_i
        v3 = triangle_node.attributes['v3'].to_s.to_i
        @triangles << [v1, v2, v3]
      end
    end
  end

  def found_inward_triangle
    # Trace a ray toward the center of the vertex points.  This will hopefully
    # maximize our chances of hitting the object's trianges on the first try.
    center = point_cloud_center(@vertices)

    @point = [0.0, 0.0, 0.0]
    @direction = vector_to(@point, center)

    # Make sure that we have a reasonably sized direction.
    # Might end up with a zero length vector if the center is also
    # at the origin.
    if magnitude(@direction) < 0.1
      @direction = [0.57, 0.57, 0.57]
    end

    # make the direction a unit vector just to make the
    # debug info easier to understand
    @direction = normalize(@direction)

    attempts = 0
    begin
      # Get all of the intersections from the ray and put them in order of distance.
      # The triangle we hit that's farthest from the start of the ray should always be
      # a triangle that points away from us (otherwise we would hit a triangle even
      # further away, assuming the mesh is closed).
      #
      # One special case is when the set of triangles we hit at that distance is greater
      # than one.  In that case we might have hit a "corner" of the model and so we don't
      # know which of the two (or more) points away from us.  In that case, cast a random
      # ray from the center of the object and try again.

      @triangles.each do |tri|
        v1 = @vertices[tri[0]]
        v2 = @vertices[tri[1]]
        v3 = @vertices[tri[2]]

        process_triangle(@point, @direction, [v1, v2, v3])
      end

      if @intersections.count > 0
        # Sort the intersections so we can find the hits that are furthest away.
        @intersections.sort! {|left, right| left[0] <=> right[0]}

        max_distance = @intersections.last[0]
        furthest_hits = @intersections.select{|hit| (hit[0]-max_distance).abs < 0.0001}

        # Print out the hits
        # furthest_hits.each {|hit| puts hit[1].to_s}

        found_good_hit = furthest_hits.count == 1
      end

      if found_good_hit
        outside_triangle = furthest_hits.last[2]
      else
        @intersections = []
        attempts = attempts + 1

        target = [Random.rand(10)/10.0, Random.rand(10)/10.0, Random.rand(10)/10.0]
        @point = center
        @direction = normalize(vector_to(@point, target))
      end
    end until found_good_hit || attempts >= 10

    # return true if we have a hit and the normals are going in the same direction
    found_good_hit && compare_normals(outside_triangle, @direction)
  end

  def compare_normals(triangle, hit_direction)
    oriented_normal = cross_product(
        vector_to(triangle[0], triangle[1]),
        vector_to(triangle[1], triangle[2]))

    angle = angle_between(oriented_normal, hit_direction)

    angle < Math::PI / 2.0
  end

  def process_triangle(point, direction, triangle)
    found_intersection, t = intersect(point, direction, triangle)

    if t > 0
      intersection = []
      intersection[0] = point[0] + t * direction[0]
      intersection[1] = point[1] + t * direction[1]
      intersection[2] = point[2] + t * direction[2]

      @intersections << [t, intersection, triangle]
    end
  end

  def intersect(point, direction, triangle)
    v0 = triangle[0]
    v1 = triangle[1]
    v2 = triangle[2]

    return [false, 0] if v0.nil? || v1.nil? || v2.nil?

    e1 = vector_to(v0, v1)
    e2 = vector_to(v0, v2)

    h = cross_product(direction, e2)
    a = dot_product(e1, h)

    if a.abs < 0.00001
      return false, 0
    end

    f = 1.0/a
    s = vector_to(v0, point)
    u = f * dot_product(s, h)

    if u < 0.0 || u > 1.0
      return false, 0
    end

    q = cross_product(s, e1)
    v = f * dot_product(direction, q)

    if v < 0.0 || u + v > 1.0
      return false, 0
    end

    t = f * dot_product(e2, q)
    [t > 0, t]
  end
end

# Various utility functions

def cross_product(a, b)
  result = [0, 0, 0]
  result[0] = a[1]*b[2] - a[2]*b[1]
  result[1] = a[2]*b[0] - a[0]*b[2]
  result[2] = a[0]*b[1] - a[1]*b[0]

  result
end

def dot_product(a, b)
  a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
end

def vector_to(a, b)
  [b[0] - a[0], b[1] - a[1], b[2] - a[2]]
end

def magnitude(a)
  Math.sqrt(a[0]*a[0] + a[1]*a[1] + a[2]*a[2])
end

def equal(a, b)
  (a[0] - b[0]).abs < 0.0001 && (a[1] - b[1]).abs < 0.0001 && (a[2] - b[2]).abs < 0.0001
end

def angle_between(a, b)
  cos_theta = dot_product(a, b) / (magnitude(a) * magnitude(b))
  Math.acos(cos_theta)
end

def normalize(a)
  length = magnitude(a)
  [a[0]/length, a[1]/length, a[2]/length]
end

def point_cloud_center(vertices)
  if vertices.count < 1
    return [0, 0, 0]
  end

  vertex = vertices[0]
  min_x = max_x = vertex[0]
  min_y = max_y = vertex[1]
  min_z = max_z = vertex[2]

  vertices.each do |vertex|
    x = vertex[0]
    y = vertex[1]
    z = vertex[2]

    min_x = x if x < min_x
    max_x = x if x > max_x
    min_y = y if y < min_y
    max_y = y if y > max_y
    min_z = z if z < min_z
    max_z = z if z > max_z
  end

  [(min_x + max_x) / 2.0, (min_y + max_y) / 2.0, (min_z + max_z) / 2.0]
end