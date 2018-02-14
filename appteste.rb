require 'sinatra'
require 'erb'
require 'sinatra/reloader'
require 'json'

#classes
require_relative 'converter'

set :bind, '0.0.0.0'
use_ssl = true

# First page just redirects to 'init' route.
get '/' do
  '<head>
  <title>App</title>
  </head>
  <body>
  <meta http-equiv="refresh" content="0; url=/init" />
  </body>'
end

get '/init' do
  erb :testview
end