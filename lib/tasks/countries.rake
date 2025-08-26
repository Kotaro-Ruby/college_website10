namespace :countries do
  desc "Fetch and update country data from REST Countries API"
  task update: :environment do
    puts "Fetching country data..."
    
    if CountryApiService.fetch_and_update_countries
      count = Country.count
      puts "Successfully updated #{count} countries"
    else
      puts "Failed to update countries"
    end
  end
end