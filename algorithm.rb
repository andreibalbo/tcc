require 'json'
require 'pry-nav'
require_relative 'converter'
require_relative 'Converter'

class Algorithm

  def self.matrix_c_from_json(input)
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
      m[[e['source'], e['target']]] = e['dist']
    end
    return m
  end

  def self.generate_matrix_p(size)
    m = Hash.new
    size.times do |i|
      size.times do |j|
        m[[i, j]] = i+1
      end
    end
    return m
  end

  def self.floyd_algorithm(matrix_c)
    size = Math.sqrt(matrix_c.size).to_i
    matrix_p = Algorithm.generate_matrix_p(size)

    # FLoyd
    size.times do |k|
      size.times do |i|
        size.times do |j|

          if matrix_c[[i, k]] + matrix_c[[k, j]] < matrix_c[[i, j]]

            matrix_p[[i, j]] = matrix_p[[k, j]]
            matrix_c[[i, j]] = matrix_c[[i, k]] + matrix_c[[k, j]]

          end

        end
      end
    end

    m = []
    m.push(matrix_c)
    m.push(matrix_p)
    return m
  end
end

# mc = Algorithm.matrix_c_from_json('public/testedoc.json')
# puts "matrix c"
# puts Converter.matrix_to_string(mc)
# ret = Algorithm.floyd_algorithm(mc)
# mc2 = ret[0]
# mp2 = ret[1]
# puts "matrix c2"
# puts Converter.matrix_to_string(mc2)
# puts "matrix p2"
# puts Converter.matrix_to_string(mp2)
# binding.pry
