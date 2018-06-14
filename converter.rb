require 'csv'
require 'json'
require 'pry-nav'
# require_relative 'algorithm'

class Converter
  @@nodes = []
  @@edges = []

  def self.csv_to_json(input, output)
    rows = []
    CSV.foreach(input, :encoding => 'UTF-8') do |row|
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
      new_node['label'] = rows[current_row][1]
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
      break if current_row > 10000
    end
    current_row += 1 # Skip header
    id_row = 0 # node id of current row
    edges = []
    next_line_size = 500
    while next_line_size > 0
      #binding.pry
      (nodes.size).times do |i|
        if rows[current_row][i+1].to_i > 0 # i+1 to skip id column
          new_edge = {}
          new_edge['id'] = edges.size
          new_edge['source'] = id_row
          new_edge['target'] = i
          new_edge['dist'] = rows[current_row][i+1].to_i
          edges.push(new_edge)
        end
      end
      id_row += 1
      current_row += 1
      if rows[current_row].nil?
        next_line_size = 0
      else
        next_line_size = rows[current_row].size
      end
    end

    # Checking if all edges are bidirectional
    bidirectional = true
    edges.each do |e|
      if edges.find_all{|d| d['source'] == e['target']}
              .find_all{|d| d['target'] == e['source']}
              .find_all{|d| d['dist'] == e['dist']}.size.zero?
        bidirectional = false
        break
      end
    end
    puts "bidirectional #{bidirectional}"

    # Remove duplicates if is fully bidirectional
    if bidirectional
      edges.each do |e|
        obj = edges.find_all{|d| d['source'] == e['target']}.find_all{|d| d['target'] == e['source']}
        obj.each do |o|
          edges.delete(o)
        end
      end
    end

    # Finally fix edge ids
    idx = 0
    edges.each do |e|
      e['id'] = idx
      idx += 1
    end

    full_json = {}
    full_json['bidirectional'] = 1 if bidirectional
    full_json['bidirectional'] = 0 if !bidirectional
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

  def self.matrix_to_string(matrix)
    size = Math.sqrt(matrix.size).to_i
    string = ''
    string += "\n"

    size.times do |i|
      size.times do |j|
        string += '['
        if matrix[[i,j]] > 10000
          string += "∞∞"
        else
          value = matrix[[i, j]].to_s.rjust(2, '0')
          string += "#{value}"
        end
        string += ']'
      end
      string += "\n"
    end
    return string
  end

  def self.json_nodes(input)
    file = File.read(input)
    data_hash = JSON.parse(file)
    #data_hash
    data_hash['nodes']
  end

  def self.json_edges(input)
    file = File.read(input)
    data_hash = JSON.parse(file)
    #data_hash
    data_hash['edges']
  end
end
# Converter.csv_to_json('public/noroeste.csv', 'public/noroeste.json')
# Converter.csv_to_json('public/testedoc.csv', 'public/testedoc.json')
#binding.pry
# Converter.json_to_csv('public/graph.json', 'lala.csv')
# mc = Algorithm.matrix_from_json('public/testedoc.json')

