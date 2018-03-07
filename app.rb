require 'sinatra'
require 'erb'
require 'sinatra/reloader'
require 'json'
require 'pry-nav'

#classes
require_relative 'converter'

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
    filename == "public/uploads/#{graph}.json"
  end
  nodes = Converter.json_nodes(filename)
  edges = Converter.json_edges(filename)
  erb :graph1, :locals => {graph: params[:graph], nodes: nodes, edges: edges}
end

get '/upload' do
    erb :upload
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
    else
      redirect "/?error=1"
    end
end
