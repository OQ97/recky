#standard requirements
require "sinatra"
require "sinatra/reloader"
require "http"
require "json"

#homepage
get("/") do
  erb(:homepage)
end

#initial search function
get("/:catalogue_search") do

  #getting catalogue number from text form in homepage
  $catno = params.fetch("catno").to_s.chomp

  #getting data from Discogs API
  $discogs_key = ENV.fetch("DISCOGS_KEY")
  $discogs_secret = ENV.fetch("DISCOGS_SECRET")
  $discogs_token = ENV.fetch("DISCOGS_TOKEN")
  @discogs_url = "https://api.discogs.com/database/search?type=release&format=vinyl&catno=#{$catno}&key=#{$discogs_key}&secret=#{$discogs_secret}"
  raw_discogs_data = HTTP.get(@discogs_url)
  parsed_discogs_data = JSON.parse(raw_discogs_data)
  $results_array = parsed_discogs_data.fetch("results")
  first_result_hash = $results_array.at(0)
  pagination_hash = parsed_discogs_data.fetch("pagination")

  #checking if release exists
  if first_result_hash.nil?
    erb(:not_found)
  else 
  
  #getting basic info about release
  $title = first_result_hash.fetch("title")
  $album_cover_url = first_result_hash.fetch("cover_image")
  @id = first_result_hash.fetch("id")

  #calculating number of pressings
  @num_pressings = pagination_hash.fetch("items").to_i
  
  #calculating # of years in which the record has been pressed
  @years=[]
  year = 0
  $results_array.each do |array_num|
    begin 
    year = array_num.fetch("year").to_i
    @years.push(year)
    rescue StandardError
    end 
  end 
  @presses_years_num = @years.uniq.count

  #calcualting # of countries in which the record has been pressed
  country = 0
  @countries=[]
  $results_array.each do |array_num|
    begin
    country = array_num.fetch("country").to_s
    @countries.push(country)
    rescue StandardError
    end 
  end 
  @presses_countries_num = @countries.uniq.count

  #redirectioning based on whether there are multiple pressings for a given catalogue number
  if @num_pressings > 1

    #See if there are multiple releases under the same catalogue number
    @title_catno=[]
    title_per_cat = ""
    $results_array.each do |item|
      begin 
      title_per_cat = item.fetch("title").to_s
      @title_catno.push(title_per_cat)
      rescue StandardError
      end 
    end
    @all_titles = @title_catno.map do |item|
      item.strip.downcase
    end  

    #MULTIPLE RELEASE SIDE - Getting all year-country-text combinations
    combination = ""
    separator = " | "
    combinations = []
    $results_array.each do |to_combine|
      begin 
        #checks if there is a special text in the release (e.g., disc color, signed...)
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
    #SINGLE-RELEASE SIDE - getting prices from API
    @prices_discogs_url = "https://api.discogs.com/marketplace/price_suggestions/#{@id}?&token=#{$discogs_token}"
    raw_discogs_price_data = HTTP.get(@prices_discogs_url)
    @parsed_discogs_price_data = JSON.parse(raw_discogs_price_data)

    #getting prices for different conditions
    @mint = @parsed_discogs_price_data.fetch("Mint (M)").fetch("value")
    @near_mint = @parsed_discogs_price_data.fetch("Near Mint (NM or M-)").fetch("value")
    @Very_good_plus = @parsed_discogs_price_data.fetch("Very Good Plus (VG+)").fetch("value")
    @Very_good = @parsed_discogs_price_data.fetch("Very Good (VG)").fetch("value")
    @good_plus = @parsed_discogs_price_data.fetch("Good Plus (G+)").fetch("value")
    @good = @parsed_discogs_price_data.fetch("Good (G)").fetch("value")
    @fair = @parsed_discogs_price_data.fetch("Fair (F)").fetch("value")
    @poor = @parsed_discogs_price_data.fetch("Poor (P)").fetch("value")
    
    #calculating new prices
    @new = (@mint+@near_mint)/2
    @used_excellent = (@Very_good_plus+@Very_good)/2
    @used_working = (@good_plus+@good)/2
    @used_poor = (@fair+@poor)/2

    erb(:single_release)
  end
end
end

get("/:catalogue_search/:detailed_search") do
  #getting release details provided by user
  @release_details = params.fetch("release_details").to_s
  separated_release_details = @release_details.split(" | ")
  
  #checks if there is special text in the selection, then separates year, country, and special release from selection
  if separated_release_details[2].nil?
    @detail_year = separated_release_details[0].strip
    @detail_country = separated_release_details[1].strip
    @detailed_selection = $results_array.find do |hash|
      hash["year"] == @detail_year &&
      hash["country"] == @detail_country
    end 
  else 
    @detail_year = separated_release_details[0].strip
    @detail_country = separated_release_details[1].strip
    @detail_text = separated_release_details[2].strip
    @detailed_selection = $results_array.find do |hash|
      hash["year"] == @detail_year &&
      hash["country"] == @detail_country &&
      hash["formats"].any? { |format| format["text"] == @detail_text }
    end 
  end 

  #getting prices from discogs API
  @detailed_id = @detailed_selection.fetch("id").to_s
  @detailed_prices_discogs_url = "https://api.discogs.com/marketplace/price_suggestions/#{@detailed_id}?&token=#{$discogs_token}"
  detailed_raw_discogs_price_data = HTTP.get(@detailed_prices_discogs_url)
  @detailed_parsed_discogs_price_data = JSON.parse(detailed_raw_discogs_price_data)
  
  #determining prices based on condition
  @mint = @detailed_parsed_discogs_price_data.fetch("Mint (M)").fetch("value")
  @near_mint = @detailed_parsed_discogs_price_data.fetch("Near Mint (NM or M-)").fetch("value")
  @Very_good_plus = @detailed_parsed_discogs_price_data.fetch("Very Good Plus (VG+)").fetch("value")
  @Very_good = @detailed_parsed_discogs_price_data.fetch("Very Good (VG)").fetch("value")
  @good_plus = @detailed_parsed_discogs_price_data.fetch("Good Plus (G+)").fetch("value")
  @good = @detailed_parsed_discogs_price_data.fetch("Good (G)").fetch("value")
  @fair = @detailed_parsed_discogs_price_data.fetch("Fair (F)").fetch("value")
  @poor = @detailed_parsed_discogs_price_data.fetch("Poor (P)").fetch("value")

  #calculating new prices
  @new = (@mint+@near_mint)/2
  @used_excellent = (@Very_good_plus+@Very_good)/2
  @used_working = (@good_plus+@good)/2
  @used_poor = (@fair+@poor)/2
  
  erb(:detailed_search)
end
