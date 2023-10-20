#standard requirements
require "sinatra"
require "sinatra/reloader"
require "http"
require "json"

#homepage
get("/") do
  erb(:homepage)
end

get("/:catalogue_search") do

  #getting catalogue number from form in homepage
  @catno = params.fetch("catno").to_s.chomp

  #getting data from Discogs API
  @discogs_key = ENV.fetch("DISCOGS_KEY")
  @discogs_secret = ENV.fetch("DISCOGS_SECRET")
  @discogs_token = ENV.fetch("DISCOGS_TOKEN")
  @discogs_url = "https://api.discogs.com/database/search?type=release&format=vinyl&catno=#{@catno}&key=#{@discogs_key}&secret=#{@discogs_secret}"
  raw_discogs_data = HTTP.get(@discogs_url)
  parsed_discogs_data = JSON.parse(raw_discogs_data)
  results_array = parsed_discogs_data.fetch("results")
  first_result_hash = results_array.at(0)
  pagination_hash = parsed_discogs_data.fetch("pagination")

  #basic info about release
  @title = first_result_hash.fetch("title")
  @album_cover_url = first_result_hash.fetch("cover_image")
  @id = first_result_hash.fetch("id")

  #number of pressings
  @num_pressings = pagination_hash.fetch("items").to_i
  
  #years in which the record has been pressed
  @years=[]
  year = 0
  results_array.each do |array_num|
    begin 
    year = array_num.fetch("year").to_i
    @years.push(year)
    rescue StandardError
    end 
  end 
  @presses_years_num = @years.uniq.count

  #countries in which the record has been pressed
  country = 0
  @countries=[]
  results_array.each do |array_num|
    begin
    country = array_num.fetch("country").to_s
    @countries.push(country)
    rescue StandardError
    end 
  end 
  @presses_countries_num = @countries.uniq.count

  if @num_pressings > 1
    combination = ""
    separator = " | "
    combinations = []
    results_array.each do |to_combine|
      begin 
        if to_combine.fetch("formats").at(0).key?("text")
        combination = to_combine.fetch("year").to_s+separator+to_combine.fetch("country").to_s+separator+to_combine.fetch("formats").at(0).fetch("text").to_s
        combinations.push(combination)
        else 
        combination = to_combine.fetch("year").to_s+separator+to_combine.fetch("country").to_s
        combinations.push(combination)
        end
      rescue StandardError
      end 
    end
    @sorted_combinations = combinations.sort do |a, b|
      first_comparison = a[0, 4].to_i <=> b[0, 4].to_i
      first_comparison.zero? ? a[8] <=> b[8] : first_comparison
    end 
    erb(:multiple_releases)
  else
    @prices_discogs_url = "https://api.discogs.com/marketplace/price_suggestions/#{@id}?&token=#{@discogs_token}"
    raw_discogs_price_data = HTTP.get(@prices_discogs_url)
    @parsed_discogs_price_data = JSON.parse(raw_discogs_price_data)
    @mint = @parsed_discogs_price_data.fetch("Mint (M)").fetch("value")
    @near_mint = @parsed_discogs_price_data.fetch("Near Mint (NM or M-)").fetch("value")
    @Very_good_plus = @parsed_discogs_price_data.fetch("Very Good Plus (VG+)").fetch("value")
    @Very_good = @parsed_discogs_price_data.fetch("Very Good (VG)").fetch("value")
    @good_plus = @parsed_discogs_price_data.fetch("Good Plus (G+)").fetch("value")
    @good = @parsed_discogs_price_data.fetch("Good (G)").fetch("value")
    @fair = @parsed_discogs_price_data.fetch("Fair (F)").fetch("value")
    @poor = @parsed_discogs_price_data.fetch("Poor (P)").fetch("value")
    erb(:single_release)
  end

end
