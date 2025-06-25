namespace :update do
  desc "Update existing colleges with international student data"
  task international_student_data: :environment do
    require 'net/http'
    require 'json'
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY'] || 'YOUR_API_KEY_HERE'
    
    if api_key == 'YOUR_API_KEY_HERE'
      puts "ERROR: Please set COLLEGE_SCORECARD_API_KEY environment variable"
      exit 1
    end
    
    puts "🌍 UPDATING INTERNATIONAL STUDENT DATA"
    puts "="*50
    
    total_colleges = Condition.count
    puts "Total colleges to update: #{total_colleges}"
    
    # Process in batches to avoid API rate limits
    batch_size = 20
    updated_count = 0
    error_count = 0
    
    Condition.find_in_batches(batch_size: batch_size) do |batch|
      # Build API request for this batch
      ids = batch.map(&:id).join(',')
      
      url = "https://api.data.gov/ed/collegescorecard/v1/schools?"
      params = {
        'api_key' => api_key,
        '_fields' => 'id,latest.student.demographics.race_ethnicity.non_resident_alien',
        'id' => ids
      }
      
      uri = URI(url)
      uri.query = URI.encode_www_form(params)
      
      begin
        puts "📥 Processing batch of #{batch.size} colleges..."
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 30
        http.read_timeout = 60
        
        response = http.request(Net::HTTP::Get.new(uri))
        
        if response.code == '200'
          data = JSON.parse(response.body)
          schools = data['results'] || []
          
          schools.each do |school|
            college_id = school['id']
            international_ratio = school['latest.student.demographics.race_ethnicity.non_resident_alien']
            
            # Find the college in our database
            college = batch.find { |c| c.id == college_id }
            
            if college && international_ratio
              college.update!(percent_non_resident_alien: international_ratio)
              updated_count += 1
              puts "  ✅ Updated #{college.college}: #{(international_ratio * 100).round(1)}%"
            elsif college
              puts "  ⚪ No data for #{college.college}"
            end
          end
          
        else
          puts "  ❌ API Error: #{response.code}"
          error_count += batch.size
        end
        
        # Rate limiting
        sleep(2)
        
      rescue => e
        puts "  ❌ Error processing batch: #{e.message}"
        error_count += batch.size
      end
      
      puts "Progress: #{updated_count} updated, #{error_count} errors"
    end
    
    puts "\n🎉 UPDATE COMPLETE!"
    puts "="*30
    puts "Total colleges processed: #{total_colleges}"
    puts "Successfully updated: #{updated_count}"
    puts "Errors: #{error_count}"
    puts "Colleges with international data: #{Condition.where.not(percent_non_resident_alien: nil).count}"
  end
end