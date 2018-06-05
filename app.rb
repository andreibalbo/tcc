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
    centers_path_hash = Algorithm.center_hash_paths(proximity_hash)
    puts 'centerspath hash done'
  end
  nodes = Converter.json_nodes(filename)
  edges = Converter.json_edges(filename)
  erb :graph2, :locals => {nodes: nodes,
                           edges: edges,
                           centers: centers,
                           prox_hash: proximity_hash.to_json,
                           cpath_hash: centers_path_hash.to_json}
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
