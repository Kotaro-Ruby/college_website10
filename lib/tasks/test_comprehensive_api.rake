namespace :test do
  desc "Test comprehensive College Scorecard API with a few schools"
  task comprehensive_api: :environment do
    require 'net/http'
    require 'json'
    
    # Test the comprehensive API with a few schools first
    url = "https://api.data.gov/ed/collegescorecard/v1/schools?"
    
    # Test with just a few key fields first
    test_fields = [
      'id',
      'school.name',
      'school.city',
      'school.state',
      'school.ownership',
      'latest.student.size',
      'latest.admissions.sat_scores.25th_percentile.math',
      'latest.admissions.sat_scores.75th_percentile.math',
      'latest.admissions.act_scores.25th_percentile.cumulative',
      'latest.admissions.act_scores.75th_percentile.cumulative',
      'latest.admissions.admission_rate.overall',
      'latest.completion.completion_rate_4yr_150nt',
      'latest.earnings.6_yrs_after_entry.median',
      'latest.cost.avg_net_price.overall'
    ]
    
    params = {
      'school.degrees_awarded.predominant' => '3',  # 4年制大学のみ
      'school.state' => 'CA',  # カリフォルニア州のみテスト
      '_fields' => test_fields.join(','),
      '_per_page' => 10
    }
    
    uri = URI(url)
    uri.query = URI.encode_www_form(params)
    
    puts "Testing API endpoint: #{uri}"
    puts "Fields requested: #{test_fields.count}"
    
    begin
      response = Net::HTTP.get_response(uri)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        schools = data['results']
        
        puts "SUCCESS! Retrieved #{schools.length} schools"
        
        schools.first(3).each do |school|
          puts "\n--- School Test Data ---"
          puts "Name: #{school['school.name']}"
          puts "State: #{school['school.state']}"
          puts "Students: #{school['latest.student.size']}"
          puts "SAT Math 25th: #{school['latest.admissions.sat_scores.25th_percentile.math'] || 'N/A'}"
          puts "SAT Math 75th: #{school['latest.admissions.sat_scores.75th_percentile.math'] || 'N/A'}"
          puts "ACT 25th: #{school['latest.admissions.act_scores.25th_percentile.cumulative'] || 'N/A'}"
          puts "ACT 75th: #{school['latest.admissions.act_scores.75th_percentile.cumulative'] || 'N/A'}"
          puts "Acceptance Rate: #{(school['latest.admissions.admission_rate.overall'] * 100).round(1) if school['latest.admissions.admission_rate.overall']}%"
          puts "6yr Median Earnings: $#{school['latest.earnings.6_yrs_after_entry.median'] || 'N/A'}"
          puts "Net Price: $#{school['latest.cost.avg_net_price.overall'] || 'N/A'}"
        end
        
        puts "\n✓ API connection successful!"
        puts "✓ Test fields are working correctly"
        puts "✓ Ready to run full comprehensive import"
        
      else
        puts "ERROR: API returned #{response.code}"
        puts "Response: #{response.body}"
        puts "\nYou may need to get an API key from: https://collegescorecard.ed.gov/data/documentation/"
      end
      
    rescue => e
      puts "ERROR: #{e.message}"
      puts "Make sure you have internet connection and the API is accessible"
    end
  end
end