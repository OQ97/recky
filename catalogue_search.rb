#search function
get("/catalogue_search") do

  #getting catalogue number from form in homepage
  $catno = params.fetch("catno").to_s.chomp

  #getting data from Discogs API
  $discogs_key = ENV.fetch("DISCOGS_KEY")
  $discogs_secret = ENV.fetch("DISCOGS_SECRET")
  @discogs_url = "https://api.discogs.com/database/search?type=release&format=vinyl&catno=#{$catno}&key=#{$discogs_key}&secret=#{$discogs_secret}"
  raw_discogs_data = HTTP.get(@discogs_url)
  parsed_discogs_data = JSON.parse(raw_discogs_data)
  results_array = parsed_discogs_data.fetch("results")
  first_result_hash = results_array.at(0)
  pagination_hash = parsed_discogs_data.fetch("pagination")

  #basic info about release
  @title = first_result_hash.fetch("title")
  @album_cover_url = first_result_hash.fetch("cover_image")

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

  erb(:catalogue_search)
end
