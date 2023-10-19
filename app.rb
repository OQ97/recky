require "sinatra"
require "sinatra/reloader"
require "http"
require "json"

get("/") do
  erb(:homepage)
end

get("/searching") do

  @barcode = params.fetch("barcode").to_s.chomp

  discogs_key = ENV.fetch("DISCOGS_KEY")
  discogs_secret = ENV.fetch("DISCOGS_SECRET")
  @discogs_url = "https://api.discogs.com/database/search?format=vinyl&barcode=#{@barcode}&key=#{discogs_key}&secret=#{discogs_secret}"

  raw_discogs_data = HTTP.get(@discogs_url)
  parsed_discogs_data = JSON.parse(raw_discogs_data)

  results_array = parsed_discogs_data.fetch("results")
  first_result_hash = results_array.at(0)

  @title = first_result_hash.fetch("title")
  @album_cover_url = first_result_hash.fetch("cover_image")
  @master_id = first_result_hash.fetch("master_id")

  pagination_hash = parsed_discogs_data.fetch("pagination")
  @num_results = pagination_hash.fetch("items").to_i
  
  

  if @num_results == 1
      redirect ("/:single_release&#{@barcode}")
  else
      redirect ("/:multiple_releases&#{@barcode}")
  end

  erb(:searching)
end 

get ("/:multiple_releases") do
  
  @barcode = params.fetch("multiple_releases").gsub(":multiple_releases&", "").to_i

  discogs_key = ENV.fetch("DISCOGS_KEY")
  discogs_secret = ENV.fetch("DISCOGS_SECRET")
  @discogs_url = "https://api.discogs.com/database/search?format=vinyl&barcode=#{@barcode}&key=#{discogs_key}&secret=#{discogs_secret}"

  raw_discogs_data = HTTP.get(@discogs_url)
  parsed_discogs_data = JSON.parse(raw_discogs_data)

  results_array = parsed_discogs_data.fetch("results")

  first_result_hash = results_array.at(0)

  @title = first_result_hash.fetch("title")
  @album_cover_url = first_result_hash.fetch("cover_image")
  
  @years=[]

  results_array.each do |array_num|
    year = array_num.fetch("year").to_i
    @years.push(year)
  end 

  @countries=[]

  results_array.each do |array_num|
    country = array_num.fetch("country").to_s
    @countries.push(country)
  end 

  erb(:multiple_releases)

end

get ("/:single_release") do
  erb(:single_release)
end 
