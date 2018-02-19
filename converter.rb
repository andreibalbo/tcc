require 'csv'
require 'json'
require 'pry-nav'

class Converter
  @@nodes = []
  @@edges = []

  def self.csv_to_json(input, output)
    rows = []
    CSV.foreach(input) do |row|
      rows.push(row.join.split(';'))
    end
    # Create nodes
    nodes = []
    current_row = 1 # Skip header
    next_line_size = 500 # Value just to enter loop
    # Loop until find line break
    while next_line_size > 0
      new_node = {}
      new_node['id'] = rows[current_row][0].to_i
      new_node['name'] = rows[current_row][1]
      new_node['x'] = rows[current_row][2].to_i
      new_node['y'] = rows[current_row][3].to_i
      new_node['size'] = rows[current_row][4].to_i
      nodes.push(new_node)
      current_row += 1
      next_line_size = rows[current_row].size
    end

    # Create edges

    # Find edges header
    while rows[current_row][0] != "Graph"
      current_row += 1
      break if current_row > 1000
    end
    current_row += 1 # Skip header
    id_row = 0 # node id of current row
    edges = []
    next_line_size = 500
    while next_line_size > 0
      (nodes.size - id_row).times do |i|
        if rows[current_row][i+1+id_row].to_i > 0 # i+1 to skip id column
          new_edge = {}
          new_edge['id'] = edges.size
          new_edge['source'] = id_row
          new_edge['target'] = i+id_row
          new_edge['dist'] = rows[current_row][i+1+id_row].to_i
          edges.push(new_edge)
        end
      end
      id_row += 1
      current_row += 1
      next_line_size = rows[current_row].size
    end

    full_json = {}
    full_json['nodes'] = nodes
    full_json['edges'] = edges

    out = JSON.pretty_generate(full_json)

    File.write(output, out)
  end

  def self.json_to_csv(input, output)
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

  # def self.create_node(id, label, x, y, size)
  #   node = {}
  #   node['id'] = id
  #   node['label'] = label
  #   node['x'] = x
  #   node['y'] = y
  #   node['size'] = size
  #   node
  # end

  # def self.create_edge(source, target, dist)
  #   edge = {}
  #   edge['source'] = source
  #   edge['target'] = target
  #   edge['dist'] = dist
  #   edge
  # end
end

Converter.csv_to_json('public/noroeste.csv', 'public/noroeste.json')
# Converter.json_to_csv('public/graph.json', 'lala.csv')
