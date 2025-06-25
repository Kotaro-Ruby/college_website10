namespace :import do
  desc "Simple comprehensive import - focuses on most important fields first"
  task simple_comprehensive_college_scorecard: :environment do
    require 'net/http'
    require 'json'
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY'] || 'YOUR_API_KEY_HERE'
    
    if api_key == 'YOUR_API_KEY_HERE'
      puts "ERROR: Please set COLLEGE_SCORECARD_API_KEY environment variable"
      exit 1
    end
    
    # 重要なフィールドのみに絞り込み
    important_fields = [
      'id', 'school.name', 'school.city', 'school.state', 'school.zip', 'school.ownership',
      'school.hbcu', 'school.tribal', 'school.hsi', 'school.school_url',
      
      # SAT/ACT スコア (ユーザーが特に要求)
      'latest.admissions.sat_scores.25th_percentile.critical_reading',
      'latest.admissions.sat_scores.75th_percentile.critical_reading',
      'latest.admissions.sat_scores.25th_percentile.math', 
      'latest.admissions.sat_scores.75th_percentile.math',
      'latest.admissions.act_scores.25th_percentile.cumulative',
      'latest.admissions.act_scores.75th_percentile.cumulative',
      
      # 基本情報
      'latest.student.size', 'latest.admissions.admission_rate.overall',
      'latest.completion.completion_rate_4yr_150nt',
      'latest.student.retention_rate.four_year.full_time',
      
      # 学費データ
      'latest.cost.tuition.in_state', 'latest.cost.tuition.out_of_state',
      'latest.cost.avg_net_price.overall', 'latest.cost.avg_net_price.public', 'latest.cost.avg_net_price.private',
      'latest.cost.avg_net_price.by_income_level.0-30000',
      'latest.cost.avg_net_price.by_income_level.30001-48000',
      'latest.cost.avg_net_price.by_income_level.48001-75000',
      'latest.cost.avg_net_price.by_income_level.75001-110000',
      'latest.cost.avg_net_price.by_income_level.110001-plus',
      
      # 卒業後収入
      'latest.earnings.6_yrs_after_entry.median', 'latest.earnings.10_yrs_after_entry.median',
      
      # 人口統計
      'latest.student.demographics.race_ethnicity.white',
      'latest.student.demographics.race_ethnicity.black', 
      'latest.student.demographics.race_ethnicity.hispanic',
      'latest.student.demographics.race_ethnicity.asian',
      'latest.student.demographics.men', 'latest.student.demographics.women',
      
      # 財政援助
      'latest.aid.pell_grant_rate', 'latest.aid.federal_loan_rate',
      'latest.aid.median_debt.graduates.overall'
    ]
    
    puts "🚀 SIMPLE COMPREHENSIVE IMPORT"
    puts "Fields to import: #{important_fields.length}"
    puts "="*50
    
    url = "https://api.data.gov/ed/collegescorecard/v1/schools?"
    total_updated = 0
    total_errors = 0
    page = 0
    per_page = 100
    
    loop do
      puts "\n📄 Processing page #{page + 1}..."
      
      params = {
        'api_key' => api_key,
        'school.degrees_awarded.predominant' => '3',
        '_fields' => important_fields.join(','),
        '_per_page' => per_page,
        '_page' => page
      }
      
      uri = URI(url)
      uri.query = URI.encode_www_form(params)
      
      puts "URL length: #{uri.to_s.length} characters"
      
      begin
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 30
        http.read_timeout = 90
        
        response = http.request(Net::HTTP::Get.new(uri))
        
        if response.code == '200'
          data = JSON.parse(response.body)
          schools = data['results'] || []
          
          if schools.empty?
            puts "✅ No more schools found. Import complete!"
            break
          end
          
          puts "✅ Got #{schools.length} schools from API"
          
          page_updated = 0
          page_errors = 0
          
          schools.each do |school|
            begin
              name = school['school.name']
              next unless name&.strip&.length&.positive?
              
              ownership = case school['school.ownership']
                         when 1 then '州立'
                         when 2 then '私立' 
                         when 3 then '営利'
                         else '不明'
                         end
              
              condition = Condition.find_or_initialize_by(college: name.strip)
              
              # 基本情報更新
              condition.assign_attributes(
                state: school['school.state'],
                city: school['school.city'],
                zip: school['school.zip'],
                privateorpublic: ownership,
                students: school['latest.student.size'],
                graduation_rate: school['latest.completion.completion_rate_4yr_150nt'],
                acceptance_rate: school['latest.admissions.admission_rate.overall'],
                website: school['school.school_url'],
                
                # SAT/ACT スコア
                sat_math_25: school['latest.admissions.sat_scores.25th_percentile.math'],
                sat_math_75: school['latest.admissions.sat_scores.75th_percentile.math'],
                sat_reading_25: school['latest.admissions.sat_scores.25th_percentile.critical_reading'],
                sat_reading_75: school['latest.admissions.sat_scores.75th_percentile.critical_reading'],
                act_composite_25: school['latest.admissions.act_scores.25th_percentile.cumulative'],
                act_composite_75: school['latest.admissions.act_scores.75th_percentile.cumulative'],
                
                # その他重要データ
                retention_rate: school['latest.student.retention_rate.four_year.full_time'],
                earnings_6yr_median: school['latest.earnings.6_yrs_after_entry.median'],
                earnings_10yr_median: school['latest.earnings.10_yrs_after_entry.median'],
                pell_grant_rate: school['latest.aid.pell_grant_rate'],
                federal_loan_rate: school['latest.aid.federal_loan_rate'],
                median_debt: school['latest.aid.median_debt.graduates.overall'],
                net_price_0_30k: school['latest.cost.avg_net_price.by_income_level.0-30000'],
                net_price_30_48k: school['latest.cost.avg_net_price.by_income_level.30001-48000'],
                net_price_48_75k: school['latest.cost.avg_net_price.by_income_level.48001-75000'],
                net_price_75_110k: school['latest.cost.avg_net_price.by_income_level.75001-110000'],
                net_price_110k_plus: school['latest.cost.avg_net_price.by_income_level.110001-plus'],
                percent_white: school['latest.student.demographics.race_ethnicity.white'],
                percent_black: school['latest.student.demographics.race_ethnicity.black'],
                percent_hispanic: school['latest.student.demographics.race_ethnicity.hispanic'],
                percent_asian: school['latest.student.demographics.race_ethnicity.asian'],
                percent_men: school['latest.student.demographics.men'],
                percent_women: school['latest.student.demographics.women'],
                tuition_in_state: school['latest.cost.tuition.in_state'],
                tuition_out_state: school['latest.cost.tuition.out_of_state'],
                hbcu: school['school.hbcu'] == 1,
                tribal: school['school.tribal'] == 1,
                hsi: school['school.hsi'] == 1
              )
              
              # 学費設定
              net_price = if ownership == '州立'
                            school['latest.cost.avg_net_price.public'] || 
                            school['latest.cost.tuition.out_of_state'] || 
                            school['latest.cost.avg_net_price.overall']
                          else
                            school['latest.cost.avg_net_price.private'] || 
                            school['latest.cost.avg_net_price.overall'] ||
                            school['latest.cost.tuition.in_state']
                          end
              condition.tuition = net_price
              
              # 全データをJSONで保存
              condition.comprehensive_data = school.to_json
              
              if condition.save
                page_updated += 1
              else
                page_errors += 1
                puts "  ❌ #{name}: #{condition.errors.full_messages.join(', ')}"
              end
              
            rescue => e
              page_errors += 1
              puts "  ❌ Error: #{school['school.name']} - #{e.message}"
            end
          end
          
          total_updated += page_updated
          total_errors += page_errors
          
          puts "Page #{page + 1} results: ✅#{page_updated} ❌#{page_errors}"
          puts "Running total: ✅#{total_updated} ❌#{total_errors}"
          
        else
          puts "❌ API Error: #{response.code}"
          puts "Response: #{response.body[0..200]}"
          break
        end
        
      rescue => e
        puts "❌ Network error: #{e.message}"
        break
      end
      
      page += 1
      sleep(1) # API rate limiting
    end
    
    puts "\n🎉 IMPORT COMPLETE!"
    puts "="*30
    puts "✅ Updated: #{total_updated}"
    puts "❌ Errors: #{total_errors}"
    puts "📊 Success rate: #{((total_updated.to_f / (total_updated + total_errors)) * 100).round(2)}%" if (total_updated + total_errors) > 0
    puts "\n✨ Data includes SAT/ACT scores, financial info, demographics, and earnings!"
  end
end