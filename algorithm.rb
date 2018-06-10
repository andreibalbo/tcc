require 'json'
require 'pry-nav'
require_relative 'converter'
require 'csv'

class Algorithm

  @matrix_c = Hash.new
  @matrix_p = Hash.new
  @matrix_p2 = Hash.new
  @matrix_c2 = Hash.new
  @centers = []
  @edges = []
  @nodes = []
  @g_matrix_c = Hash.new
  @g_matrix_p = Hash.new
  @g_matrix_p2 = Hash.new
  @g_matrix_c2 = Hash.new
  @g_centers = []
  @g_edges = []
  @g_nodes = []
  @correlation_list = []

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

  def self.centers
    @centers
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
    if @matrix_p2[[nodea, nodeb]] == nodea && @matrix_c[[nodea, nodeb]] > 1000
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
    @centers = []
    while @centers.size < ncenters
      random = rand(size)
      @centers.push(random) if @centers.index(random).nil?
    end
    non_analysed = []
    size.times do |i|
      non_analysed.push(i)
    end
    non_analysed = non_analysed - @centers
    analysed = []
    d = calculate_total_centers_distance
    min_tdistance = d

    while non_analysed.size > 0
      # Teitz&Bart Algorithm

      # random current node
      current_node = non_analysed.sample
      centers_backup = @centers[0..@centers.length]
      tdistances = []
      # swap with every center and calculate total distance
      ncenters.times do |i|
        @centers[i] = current_node
        tdistances[i] = calculate_total_centers_distance
        @centers = centers_backup[0..centers_backup.length]
      end

      # get min distance from array and check if its better
      node_min_d = tdistances.min
      if node_min_d < min_tdistance
        min_tdistance = node_min_d
        idx = tdistances.index(node_min_d)
        analysed.push(@centers[idx])
        @centers[idx] = current_node
      else
        analysed.push(current_node)
      end
        non_analysed = non_analysed - [current_node]
    end
    return @centers
  end

  def self.calculate_total_centers_distance
    total_distance = 0
    center_proximity = []
    # Get an array that shows nearest center for each node
    @nodes.each do |n|
      min_center_dist = Float::INFINITY
      @centers.each do |c|
        if shortest_distance(n['id'].to_i, c) < min_center_dist
          min_center_dist = shortest_distance(n['id'].to_i, c)
          center_proximity[n['id'].to_i] = c
        end
      end
    end
    # Calculate total centers distance
    center_proximity.each_with_index do |c, i|
      total_distance += shortest_distance(i, c) unless c.nil?
    end
    total_distance
  end

  def self.center_hash_proximity
    center_proximity = {}
    # Get an array that shows nearest center for each node
    center_nodes = []
    @centers.each do |c|
      center_nodes[c] = []
    end
    @nodes.each do |n|
      min_center_dist = Float::INFINITY
      chosen_center = nil
      @centers.each do |c|
        if shortest_distance(n['id'].to_i, c) < min_center_dist
          min_center_dist = shortest_distance(n['id'].to_i, c)
          chosen_center = c
        end
      end
      center_nodes[chosen_center].push(n['id'].to_i)
    end
    @centers.each do |c|
      center_proximity[c.to_s] = center_nodes[c]
    end
    center_proximity
  end

  def self.center_hash_paths(hash_input)
    puts "######### Hash de rotas para cada centro #########"

    center_proximity = hash_input
    keys = center_proximity.keys
    centers = keys.map(&:to_i)
    hash_centers_path = {}
    centers.each do |c|
      hash_centers_path[c.to_s] = []
      arr_path = center_proximity[c.to_s]
      # Adding beginning and end for closed route
      arr_path_c = arr_path.first == c ? (arr_path + [c]) : ([c] + arr_path + [c])
      arr_path_c = nearest_neighbour_path(arr_path_c)
      arr_path_c = two_opt_best_route(arr_path_c)
      hash_centers_path[c.to_s] = arr_path_c
    end
    begin
      full_path_hash = {}
      centers.each do |c|
        full_path_hash[c.to_s] = hash_centers_path[c.to_s][0..hash_centers_path[c.to_s].length]
      end
      centers.each do |c|
        "Calculando rota extendida para o centro #{c} | Rota inicial: #{hash_centers_path[c.to_s]}"
        inserted_counter = 0
        hash_centers_path[c.to_s].each_with_index do |a,i|
          next if a == hash_centers_path[c.to_s].last
          puts "Calculando rota do centro #{c} | node: #{a}"
          path = shortest_path(a, hash_centers_path[c.to_s][i+1])
          if path.size > 2
            elmnts_to_insert = path.drop(1)
            elmnts_to_insert = elmnts_to_insert.reverse.drop(1).reverse
            puts "Inserindo elementos: #{elmnts_to_insert}"
            elmnts_to_insert.reverse.each do |e|
              full_path_hash[c.to_s].insert(i + 1 + inserted_counter, e)
              puts "Caminho atual: #{full_path_hash[c.to_s]}"
            end
            inserted_counter += elmnts_to_insert.size
          end
        end
      end
      puts "####################################################"

      return full_path_hash
    rescue => e
      puts e.backtrace
    end
  end

  def self.two_opt_best_route(array)
    begin
      if array.size.zero?
        return -1
      else
        puts "######## Iniciando 2-OPT para o vetor: #{array} #######"
        puts "Distancia total inicial: #{calculate_route_length(array)}"
        min_distance = calculate_route_length(array)
        route_result = array[0..array.length]
        test_array = array[0..array.length]
        no_swap = false
        while no_swap == false
          puts "verificacao com caminho #{route_result.to_s}"
          no_swap = true
          route_result.each_with_index do |n, i|
            break if no_swap == false
            route_result.each_with_index do |m, j|
              break if no_swap == false
              next if j == i || [m, n].include?(route_result.first) || [m, n].include?(route_result.last)
              test_array[i] = m
              test_array[j] = n
              length = calculate_route_length(test_array)
              if length < min_distance
                puts "trocando #{route_result.to_s} d:#{min_distance} | por #{test_array.to_s} d:#{length}"
                no_swap = false
                min_distance = length
                route_result = test_array[0..test_array.length]
              else
                test_array = route_result[0..route_result.length]
              end
            end
          end
        end
        puts "2-OPT caminho final: #{route_result}"
        puts "Distancia do percurso final: #{calculate_route_length(route_result)}"
        puts "####################################################"
        return route_result
      end
    rescue StandardError => e
      puts e.backtrace
      return -1
    end
  end

  def self.calculate_extended_path(array)
    puts "########## Calculando rota extendida de: #{array} ##############"

    inserted_counter = 0
    ext_array = array[0..array.length]
    array.each_with_index do |a,i|
      next if i == (array.length-1)
      path = shortest_path(a, array[i+1])
      if path.size > 2
        elmnts_to_insert = path.drop(1)
        elmnts_to_insert = elmnts_to_insert.reverse.drop(1).reverse
        puts "Inserindo elementos: #{elmnts_to_insert}"

        elmnts_to_insert.reverse.each do |e|
          ext_array.insert(i + 1 + inserted_counter, e)
        end
        inserted_counter += elmnts_to_insert.size
      end
    end
    puts "Rota extendida final: #{ext_array}"
    puts "####################################################"
    ext_array
  end

  def self.calculate_route_length(array)
    length = 0
    array.each_with_index do |n, i|
      unless array[i+1].nil?
        length = length + @matrix_c2[[n, array[i+1]]]
      end
    end
    return length
  end

  def self.nearest_neighbour_path(array)
    puts "####### Vizinho mais proximo para o vetor: #{array} ##########"

    begin
      if array.size.zero?
        return -1
      else
        path = [array.first]
        puts "Iniciando com vetor: #{path}"
        unused_nodes = array - [array.first]
        while unused_nodes.size > 0
          min_distance = Float::INFINITY
          selected_node = nil
          unused_nodes.each do |n|
            if shortest_distance(path.last, n) < min_distance
              selected_node = n
              min_distance = shortest_distance(path.last, n)
            end
          end
          puts "Adicionando node [#{selected_node}]"
          path.push(selected_node)
          unused_nodes = unused_nodes - [selected_node]
        end
        puts "Fechando rota com [#{selected_node}]"

        path.push(array.first)
        puts "Rota com vizinho mais proximo: #{path}"
        puts "Distancia total: #{calculate_route_length(path)}"
        puts "####################################################"
        return path
      end
    rescue StandardError => e
      puts e.backtrace
      return -1
    end
  end

  def self.nearest_insertion_path(array)
    begin
      if array.size.zero?
        return -1
      else
        puts "####### Insercao do mais proximo para o vetor: #{array} ##########"
        puts "Distancia total inicial: #{calculate_route_length(array)}"
        path = [array.first]
        puts "Iniciando com vetor: #{path}"

        unused_nodes = array - [array.first]
        while unused_nodes.size > 0
          min_distance = Float::INFINITY
          selected_node = nil
          unused_nodes.each do |n|
            path.each do |path_n|
              if shortest_distance(path_n, n) < min_distance
                selected_node = n
                min_distance = shortest_distance(path_n, n)
              end
            end
          end
          to_minimize = Float::INFINITY
          position = 0

          path.each_with_index do |n, i|
            if i == (path.length - 1)
              value = (shortest_distance(n, selected_node) + shortest_distance(array.first, selected_node)) - shortest_distance(n, array.first)
            else
              value = (shortest_distance(n, selected_node) + shortest_distance(path[i+1], selected_node)) - shortest_distance(n, path[i+1])
            end
            if value < to_minimize
              to_minimize = value
              position = i + 1
            end
          end
          puts "Inserindo #{selected_node} na posicao #{position}"
          path.insert(position, selected_node)
          unused_nodes = unused_nodes - [selected_node]
        end
        path.push(array.first)
        puts "Rota com insercao do mais proximo: #{path}"
        puts "Distancia total: #{calculate_route_length(path)}"
        puts "####################################################"
        return path
      end
    rescue StandardError => e
      puts e.backtrace
      return -1
    end
  end

  def self.farthest_insertion_path(array)
    begin
      if array.size.zero?
        return -1
      else
        puts "####### Insercao do mais distante para o vetor: #{array} ##########"
        puts "Distancia total inicial: #{calculate_route_length(array)}"
        path = [array.first]
        puts "Iniciando com vetor: #{path}"

        unused_nodes = array - [array.first]
        while unused_nodes.size > 0
          min_distance = 0
          selected_node = nil
          unused_nodes.each do |n|
            path.each do |path_n|
              if shortest_distance(path_n, n) > min_distance
                selected_node = n
                min_distance = shortest_distance(path_n, n)
              end
            end
          end
          to_minimize = Float::INFINITY
          position = 0

          path.each_with_index do |n, i|
            if i == (path.length - 1)
              value = (shortest_distance(n, selected_node) + shortest_distance(array.first, selected_node)) - shortest_distance(n, array.first)
            else
              value = (shortest_distance(n, selected_node) + shortest_distance(path[i+1], selected_node)) - shortest_distance(n, path[i+1])
            end
            if value < to_minimize
              to_minimize = value
              position = i + 1
            end
          end
          puts "Inserindo #{selected_node} na posicao #{position}"
          path.insert(position, selected_node)
          unused_nodes = unused_nodes - [selected_node]
        end
        path.push(array.first)
        puts "Rota com insercao do mais distante: #{path}"
        puts "Distancia total: #{calculate_route_length(path)}"
        puts "####################################################"
        return path
      end
    rescue StandardError => e
      puts e.backtrace
      return -1
    end
  end

  def self.generate_subgraph(selected_nodes)
    if selected_nodes.size < 2
      return -1
    end
    # Pass matrix and other info to g_ variables
    @g_matrix_c = @matrix_c
    @g_matrix_p = @matrix_p
    @g_matrix_p2 = @matrix_p2
    @g_matrix_c2 = @matrix_c2
    @g_edges = @edges
    @g_nodes = @nodes
    # Populating nodes
    new_file_data = {}
    new_file_data['bidirectional'] = 1 # TODO: get bidirectional from file
    new_file_data['nodes'] = []
    id_counter = 0
    @g_nodes.each do |n|
      if selected_nodes.include?(n['id'])
        json_node = {}
        json_node['id'] = id_counter
        json_node['label'] = n['label']
        json_node['x'] = n['x']
        json_node['y'] = n['y']
        json_node['size'] = n['size']
        new_file_data['nodes'].push(json_node)
        @correlation_list[id_counter] = n["id"].to_i
        id_counter += 1
      end
    end
    # Populating edges
    new_file_data['edges'] = []
    id_counter = 0
    selected_nodes.each do |n1|
      selected_nodes.each do |n2|
        unless n1 >= n2
          sp = shortest_path(n1, n2)
          if sp.size > 2
            if ((sp & selected_nodes) == [n1, n2]) || ((sp & selected_nodes) == [n2, n1])
              # add with g_path
              json_edge = {}
              json_edge['id'] = id_counter
              json_edge['source'] = @correlation_list.index(n1)
              json_edge['target'] = @correlation_list.index(n2)
              json_edge['dist'] = shortest_distance(n1, n2)
              json_edge['g_path'] = sp
              id_counter += 1
              new_file_data['edges'].push(json_edge)
            end
          else
            # add without description
            json_edge = {}
            json_edge['id'] = id_counter
            json_edge['source'] = @correlation_list.index(n1)
            json_edge['target'] = @correlation_list.index(n2)
            json_edge['dist'] = shortest_distance(n1, n2)
            id_counter += 1
            new_file_data['edges'].push(json_edge)
          end
        end
      end
    end

    # clean variables
    @matrix_c = Hash.new
    @matrix_p = Hash.new
    @matrix_p2 = Hash.new
    @matrix_c2 = Hash.new
    @centers = []
    @edges = []
    @nodes = []
    out = JSON.pretty_generate(new_file_data)
    File.write('public/uploads/subgraph.json', out)
    return 1
  end

  def self.best_route_all_algorithms(array)
    nodes = array
    min_distance = Float::INFINITY
    min_path = nil
    nn_path = Algorithm.nearest_neighbour_path(nodes)
    nn_dist = Algorithm.calculate_route_length(nn_path)
    if nn_dist < min_distance
      min_distance = nn_dist
      min_path = nn_path
    end
    ni_path = Algorithm.nearest_insertion_path(nodes)
    ni_dist = Algorithm.calculate_route_length(ni_path)
    if ni_dist < min_distance
      min_distance = ni_dist
      min_path = ni_path
    end
    fi_path = Algorithm.farthest_insertion_path(nodes)
    fi_dist = Algorithm.calculate_route_length(fi_path)
    if fi_dist < min_distance
      min_distance = fi_dist
      min_path = fi_path
    end
    arr_path = Algorithm.two_opt_best_route(min_path)
    ext_path = Algorithm.calculate_extended_path(arr_path)
    ext_dist = Algorithm.calculate_route_length(ext_path)

    return_hash = {}
    return_hash['path'] = ext_path
    return_hash['dist'] = ext_dist
    return return_hash
  end

  def self.export_to_csv

    File.delete('export/download.csv') if File.exists?('export/download.csv')

    file_data = ''
    # Create header
    file_data += "Relatório:;\r\n"
    # First graph nodes
    file_data += "GRAFO ORIGINAL:;\r\n"
    @g_nodes = @nodes if @g_nodes.size.zero?
    file_data += "Cidades:;"
    @g_nodes.each do |n|
      file_data += "#{n['label']};"
    end
    file_data += "\r\n"
    file_data += "\r\n"
    # Subgraph nodes
    file_data += "SUBGRAFO:\r\n"
    file_data += "Cidades:;"
    @nodes.each do |n|
      file_data += "#{n['label']};"
    end
    file_data += "\r\n"
    file_data += "\r\n"

    # centers
    file_data += "Número de centros:;"
    file_data += "#{@centers.size};\r\n"
    c_proximity = center_hash_proximity
    file_data += 'Cidades abrangidas:;'
    @centers.each do |c|
      file_data += "Centro: #{@nodes[c]['label']};\r\n"
      file_data += "Cidades:;"
      c_proximity[c.to_s].each do |n|
        file_data += "#{@nodes[n]['label']};"
      end
      file_data += "\r\n"
    end
    file_data += "\r\n"

    # centers path
    if @centers.size > 2
      file_data += "Melhor rota entre os centros;\r\n"
      path_array = @centers[0..@centers.length]
      path_array.push(@centers[0])
      path_hash = best_route_all_algorithms(path_array)

      path = calculate_extended_path(path_hash['path'])
      file_data += "Rota:;"
      path.each do |n|
        file_data += "#{@nodes[n]['label']};"
      end
      file_data += "\r\n"
      file_data += "Distância total:;"
      file_data += "#{path_hash['dist']};\r\n"

      file_data += "\r\n"
    end

    #center nodes path
    file_data += "Melhor rota entre as cidades de centros:;\r\n"
    @centers.each do |c|
      file_data += 'Centro:;'
      file_data += "#{@nodes[c]['label']};\r\n"
      if c_proximity[c.to_s].nil?
        file_data += "Rota:;\r\n"
      else
        file_data += "Rota:;"
        array = c_proximity[c.to_s][0..c_proximity[c.to_s].length]
        while array[0] != c
          array = array.rotate
        end
        array.push(array[0]) unless array.last == array.first
        path_hash = best_route_all_algorithms(array)
        path = calculate_extended_path(path_hash['path'])
        path.each do |n|
          file_data += "#{@nodes[n]['label']};"
        end
        file_data += "\r\n"
        file_data += "Distância total:;"
        file_data += "#{path_hash['dist']};\r\n"
      end
    end
    file_data += "\r\n"
    file_data += "FIM;\r\n"

    # file generation

    File.write('public/export/download.csv', file_data)
    return 'download.csv'
  end
end

# Algorithm.matrix_c_from_json('public/noroeste.json')
# # # # #puts "matrix c"
# # # # #puts Converter.matrix_to_string(Algorithm.matrix_c)
# Algorithm.floyd_algorithm
# Algorithm.generate_subgraph([1,2,3])

# Algorithm.teitz_bart(2)
# h = Algorithm.center_hash_proximity
# binding.pry
# Algorithm.center_hash_paths(h)
# binding.pry
# #puts "matrix c2"
# binding.pry
# #puts Converter.matrix_to_string(Algorithm.matrix_c2)
# #puts "matrix p2"
# #puts Converter.matrix_to_string(Algorithm.matrix_p2)
# path = [3, 4, 0, 2, 1, 3]
# Algorithm.nearest_neighbour_path(path)
# Algorithm.nearest_insertion_path(path)
# Algorithm.farthest_insertion_path(path)
# Algorithm.two_opt_best_route(path)
# puts "teitzbart centers: #{Algorithm.teitz_bart(2).to_s}"
# binding.pry
