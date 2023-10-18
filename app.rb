require "sinatra"
require "sinatra/reloader"
require "http"
require "json"

get("/") do
  erb(:homepage)
end


get ("/results") do
  @catalogue = params.fetch("catno").to_s.chomp
  erb(:results)

  discogs_key = ENV.fetch("DISCOGS_KEY")
  discogs_secret = ENV.fetch("DISCOGS_SECRET")
  discogs_url = "https://api.discogs.com/database/search?catno=#{@catalogue}&key=#{discogs_key}&secret=#{discogs_secret}"

  raw_discogs_data = HTTP.get(discogs_url)
  parsed_discogs_data = JSON.parse(raw_discogs_data)

  results_array = parsed_discogs_data.fetch("results")
  first_result_hash = results_array.at(0)

  title = first_result_hash.fetch("title")

end
