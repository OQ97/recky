require "sinatra"
require "sinatra/reloader"

get("/") do
  erb(:homepage)
end


get ("/results") do
  @catalogue = params.fetch("catno").to_s.chomp
  erb(:results)

  discogs_key = ENV.fetch("DISCOGS_KEY")
  discogs_secret = ENV.fetch("DISCOGS_SECRET")
  discogs_url = "https://api.discogs.com/database/search?catno=#{catalogue}&key=#{discogs_key}&secret=#{discogs_secret}"

end
