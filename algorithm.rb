require 'json'
require 'pry-nav'

class Algorithm

  def self.matrix_from_json(input)
    m = Hash.new
    inf = Float::INFINITY
    file = File.read(input)
    data_hash = JSON.parse(file)
    edges = data_hash['edges']
    nodes = data_hash['nodes']

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
      m[[e['source'],e['target']]] = e['dist']
      m[[e['target'],e['source']]] = e['dist']
    end

    return m
  end

end
