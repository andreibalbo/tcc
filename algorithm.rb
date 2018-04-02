require 'json'
require 'pry-nav'
require_relative 'converter'

class Algorithm

  @matrix_c = Hash.new
  @matrix_p = Hash.new
  @matrix_p2 = Hash.new
  @matrix_c2 = Hash.new
  @centers = []
  @edges = []
  @nodes = []

  def self.matrix_c
    @matrix_c
  end
  def self.matrix_p
    @matrix_p
  end
  def self.matrix_c2
    @matrix_c2
  end
  def self.matrix_p2
    @matrix_p2
  end

  def self.nodes
    @nodes
  end

  def self.edges
    @edges
  end

  def self.matrix_c_from_json(input)
    m = Hash.new
    inf = Float::INFINITY
    file = File.read(input)
    data_hash = JSON.parse(file)
    @edges = data_hash['edges']
    @nodes = data_hash['nodes']
    if data_hash['bidirectional'].zero?
      bidirectional = false
    else
      bidirectional = true
    end

    # Fill matrix with standard values
    nodes.size.times do |i|
      nodes.size.times do |j|
        if i == j
          m[[i, j]] = 0
        else
          m[[i, j]] = inf
        end
      end
    end
    # Filling with edge values
    edges.each do |e|
      m[[e['source'], e['target']]] = e['dist']
      m[[e['target'], e['source']]] = e['dist'] if bidirectional
    end
    @matrix_c = m
  end

  def self.generate_matrix_p
    size = Math.sqrt(@matrix_c.size).to_i
    m = Hash.new
    size.times do |i|
      size.times do |j|
        m[[i, j]] = i
      end
    end
    @matrix_p = m
  end

  def self.floyd_algorithm
    size = Math.sqrt(@matrix_c.size).to_i

    Algorithm.generate_matrix_p
    @matrix_c2 = @matrix_c
    @matrix_p2 = @matrix_p
    # FLoyd
    size.times do |k|
      size.times do |i|
        size.times do |j|

          if @matrix_c2[[i, k]] + @matrix_c2[[k, j]] < @matrix_c2[[i, j]]

            @matrix_p2[[i, j]] = @matrix_p2[[k, j]]
            @matrix_c2[[i, j]] = @matrix_c2[[i, k]] + @matrix_c2[[k, j]]

          end

        end
      end
    end

  end

  def self.shortest_distance(nodea, nodeb)
    @matrix_c2[[nodea, nodeb]]
  end

  def self.shortest_path(nodea, nodeb)
    path = []
    # First verification
    if @matrix_p2[[nodea, nodeb]] == nodea && matrix_c[[nodea, nodeb]] > 1000
      # There is no path
      return -1
    end
    # Put end of the path first
    target = nodeb
    path.push(target)
    while @matrix_p2[[nodea, target]] != nodea
        target = @matrix_p2[[nodea, target]]
        path.push(target)
    end
    # Put beginning of the path
    path.push(nodea)
    # Return reversed array to show correct path order
    return path.reverse
  end

  def self.teitz_bart(ncenters)
    size = Math.sqrt(@matrix_c.size).to_i
    if ncenters > size/2 || ncenters < 1
      return -1
    end
    while @centers.size < ncenters
      random = rand(ncenters)
      @centers.push(random) if @centers.index(random).nil?
    end
    non_analysed = []
    size.times do |i|
      non_analysed.push(i)
    end
    non_analysed = non_analysed - @centers
    analysed = []
    binding.pry
    while non_analysed.size > 0
      # Teitz&Bart Algorithm

    end

    binding.pry

  end

  def self.calculate_total_centers_distance(centers)

    total_distance = 0
    center_proximity = []
    # Get an array that shows nearest center for each node
    @nodes.each do |n|
      if
      min_center_dist = Float::INFINITY
      @centers.each do |c|
        if shortest_distance(n['id'].to_i, c) < min_center_dist
          min_center_dist = shortest_distance(n['id'].to_i, c)
          center_proximity[n['id'].to_i] = c
        end
      end
    end
    binding.pry
    # Calculate total centers distance
    center_proximity.each do |i|
      total_distance += shortest_distance(center_proximity.index(i), i) unless i.nil?
    end
    total_distance

    end

    @centers.each  do |c|

    end

  end

end

Algorithm.matrix_c_from_json('public/noroeste.json')
puts "matrix c"
puts Converter.matrix_to_string(Algorithm.matrix_c)
Algorithm.floyd_algorithm
puts "matrix c2"
puts Converter.matrix_to_string(Algorithm.matrix_c2)
puts "matrix p2"
puts Converter.matrix_to_string(Algorithm.matrix_p2)
binding.pry
