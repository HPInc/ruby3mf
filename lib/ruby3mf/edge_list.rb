class EdgeList

  def initialize()
    @edges = { }
  end

  def add_edge(first_vertex, second_vertex)
    if first_vertex < second_vertex
      edge = "#{first_vertex}:#{second_vertex}"
    else
      edge = "#{second_vertex}:#{first_vertex}"
    end

    (pos_count, neg_count) = @edges[edge]

    if pos_count == nil or neg_count == nil
      pos_count = 0
      neg_count = 0
    end

    pos_count += 1 if first_vertex < second_vertex
    neg_count += 1 if second_vertex < first_vertex

    @edges[edge] = [pos_count, neg_count]
  end

  def edge_count(first_vertex, second_vertex)
    if first_vertex < second_vertex
      edge = "#{first_vertex}:#{second_vertex}"
    else
      edge = "#{second_vertex}:#{first_vertex}"
    end

    return @edges[edge]
  end

  def print_list()
    @edges.each do |key, value|
      (pos, neg) = value
      puts "#{pos} : #{neg}"
    end
  end

  def manifold_edges()
    @edges.each do |key, value|
      (pos, neg) = value
      return false if (pos != 1 or neg != 1)
    end

    return true
  end

end

