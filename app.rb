require 'sinatra'
require 'erb'
require 'sinatra/reloader'
require 'json'
require 'pry-nav'

#classes
require_relative 'converter'
require_relative 'algorithm'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8
set :bind, '0.0.0.0'
use_ssl = true

# First page just redirects to 'init' route.
get '/' do
  error = params[:error]
  erb :index, :locals => {error: params[:error]}
end

get '/graph1' do
  graph = params[:graph]
  if graph == "" || graph.nil?
    filename = 'public/uploads/default.json'
  else
    filename = "public/uploads/#{graph}"
  end
  nodes = Converter.json_nodes(filename)
  edges = Converter.json_edges(filename)
  erb :graph1, :locals => {graph: params[:graph], nodes: nodes, edges: edges}
end

get '/create_subgraph' do
  param_ids = params[:selected]
  unless param_ids.nil?
    parsed_ids = JSON.parse(param_ids)['ids']
    selected_nodes = parsed_ids.map(&:to_i)
  end
  if File.exist? 'public/uploads/upload.json'
    filename = 'public/uploads/upload.json'
  else
    filename = 'public/uploads/default.json'
  end
  # First graph matrix generation
  Algorithm.matrix_c_from_json(filename)
  Algorithm.floyd_algorithm

  if selected_nodes.nil?
    file = File.read(filename)
    File.write('public/uploads/subgraph.json', file)
  else
    Algorithm.generate_subgraph(selected_nodes)
  end
  Algorithm.matrix_c_from_json('public/uploads/subgraph.json')
  Algorithm.floyd_algorithm
  redirect '/graph2'
end

get '/graph2' do
  ncenters = params[:nc]

  if File.exist? "public/uploads/subgraph.json"
    filename = "public/uploads/subgraph.json"
  else
    return {status: 500}
  end

  centers = []
  proximity_hash = {}
  unless ncenters.nil?
    Algorithm.matrix_c_from_json(filename)
    Algorithm.floyd_algorithm
    puts 'floyd done'
    centers = Algorithm.teitz_bart(ncenters.to_i)
    puts 'teitzbart done'
    proximity_hash = Algorithm.center_hash_proximity
    puts 'centerhash done'
    #centers_path_hash = Algorithm.center_hash_paths(proximity_hash)
    #puts 'centerspath hash done'
  end
  nodes = Converter.json_nodes(filename)
  edges = Converter.json_edges(filename)
  erb :graph2, :locals => {nodes: nodes,
                           edges: edges,
                           centers: centers,
                           prox_hash: proximity_hash.to_json#,
                           #cpath_hash: centers_path_hash.to_json
                           }
end

post '/upload' do
  tempfile = params[:file][:tempfile]
  filename = params[:file][:filename]
  if File.extname(filename) == '.csv'
    FileUtils.cp(tempfile.path, "public/uploads/upload.csv")
    Converter.csv_to_json("public/uploads/upload.csv", "public/uploads/upload.json")
    if File.exist?("public/uploads/upload.json")
      redirect "/graph1?graph=upload.json"
    else
      redirect "/?error=2"
    end
  elsif File.extname(filename) == '.json'
    FileUtils.cp(tempfile.path, "public/uploads/upload.json")
    if File.exist?("public/uploads/upload.json")
      redirect "/graph1?graph=upload.json"
    else
      redirect "/?error=2"
    end
    redirect "/?error=1"
  else
    redirect "/?error=1"
  end
end

get '/centers_path' do
  c_param = params[:centers]
  nodes = JSON.parse(c_param)
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
  return return_hash.to_json
end

get '/best_path' do
  arr_param = params[:arr]
  nodes = JSON.parse(arr_param)
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
  return return_hash.to_json
end
