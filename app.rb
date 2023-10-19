#standard requirements
require "sinatra"
require "sinatra/reloader"
require "http"
require "json"
load "catalogue_search.rb"


#homepage
get("/") do
  erb(:homepage)
end
