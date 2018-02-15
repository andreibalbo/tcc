require 'csv'
require 'json'
require 'pry-nav'

class Converter
  @@nodes = []
  @@edges = []

  def self.csv_to_json(input, output)
    binding.pry
    data = File.open(input).read

    CSV.parse(data).to_json

  end

  def self.json_to_csv(input, output)
    binding.pry
    file = File.read(input)
    data_hash = JSON.parse(file)

    # Nodes info header
    csv_string = "Id;Name;X;Y;Size;\r\n"
    data_hash['nodes'].each do |n|
      id = n['id']
      label = n['label']
      x = n['x']
      y = n['y']
      size = n['size']
      csv_string += "#{id};#{label};#{x};#{y};#{size};\r\n"
    end
    # Line break
    csv_string += ";;;;;\r\n"

    # Edge pairs gather
    edge_pairs = []
    edges_size = []
    data_hash['edges'].each do |a|
      edge_pairs.push([a['source'], a['target']])
      edges_size.push(a['dist'])
    end

    # Graph edges header
    nodes_number = data_hash['nodes'].size

    csv_string += "Graph;"
    nodes_number.times do |i|
      csv_string += "#{i};"
    end
    csv_string += "\r\n"

    nodes_number.times do |i|
      # First column
      csv_string += "#{i};"

      nodes_number.times do |j|

        # Remaining columns
        if i == j
          csv_string += "0;"
        elsif edge_pairs.include? [i, j]
          idx = edge_pairs.index [i, j]
          dist = data_hash['edges'][idx]['dist']
          csv_string += "#{dist};"
        elsif edge_pairs.include? [j, i]
          idx = edge_pairs.index [j, i]
          dist = data_hash['edges'][idx]['dist']
          csv_string += "#{dist};"
        else
          csv_string += "-1;"
        end

      end
      # Line break
      csv_string += "\r\n"
    end
    # mexer

    File.write(output, csv_string)

  end

  def self.create_node(label, x, y, size)

  end

  def self.create_edge(source, target)

  end
end

#Converter.csv_to_json('public/noroeste.csv', 'xd.json')
Converter.json_to_csv('public/graph.json', 'lala.csv')
