namespace :import do
  desc "Continue importing remaining colleges with API rate limiting handled"
  task continue_comprehensive_import: :environment do
    require 'net/http'
    require 'json'
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY'] || 'YOUR_API_KEY_HERE'
    
    if api_key == 'YOUR_API_KEY_HERE'
      puts "ERROR: Please set COLLEGE_SCORECARD_API_KEY environment variable"
      exit 1
    end
    
    current_count = Condition.count
    puts "🔄 CONTINUING IMPORT FROM #{current_count} COLLEGES"
    puts "="*60
    puts "Target: 6,429 total colleges"
    puts "Remaining: #{6429 - current_count} colleges"
    puts "Using slower rate to avoid API limits"
    puts "="*60
    
    # 同じフィールドセット
    core_fields = [
      'id', 'school.name', 'school.city', 'school.state', 'school.zip', 'school.ownership',
      'school.school_url', 'school.hbcu', 'school.tribal', 'school.hsi', 'school.menonly', 'school.womenonly',
      'school.relaffil', 'school.locale', 'school.carnegie_basic',
      'latest.student.size', 'latest.admissions.admission_rate.overall',
      'latest.admissions.sat_scores.25th_percentile.math', 'latest.admissions.sat_scores.75th_percentile.math',
      'latest.admissions.sat_scores.25th_percentile.critical_reading', 'latest.admissions.sat_scores.75th_percentile.critical_reading',
      'latest.admissions.act_scores.25th_percentile.cumulative', 'latest.admissions.act_scores.75th_percentile.cumulative',
      'latest.completion.completion_rate_4yr_150nt', 'latest.completion.completion_rate_less_than_4yr_150nt',
      'latest.student.retention_rate.four_year.full_time', 'latest.cost.tuition.in_state', 'latest.cost.tuition.out_of_state',
      'latest.cost.avg_net_price.overall', 'latest.cost.avg_net_price.public', 'latest.cost.avg_net_price.private',
      'latest.cost.roomboard.oncampus', 'latest.student.demographics.race_ethnicity.white',
      'latest.student.demographics.race_ethnicity.black', 'latest.student.demographics.race_ethnicity.hispanic',
      'latest.student.demographics.race_ethnicity.asian', 'latest.student.demographics.race_ethnicity.non_resident_alien',
      'latest.student.demographics.men', 'latest.student.demographics.women',
      'latest.aid.pell_grant_rate', 'latest.aid.federal_loan_rate', 'latest.aid.median_debt.graduates.overall',
      'latest.earnings.6_yrs_after_entry.median', 'latest.earnings.10_yrs_after_entry.median', 'latest.faculty.salary'
    ]
    
    url = "https://api.data.gov/ed/collegescorecard/v1/schools?"
    existing_names = Condition.pluck(:college).to_set
    
    # 取得済みの学校をスキップするため、より大きなページから開始
    start_page = (current_count / 50).to_i
    page = start_page
    per_page = 50  # より小さくしてAPI制限を回避
    new_schools_saved = 0
    
    puts "Starting from page #{page + 1} (estimated)"
    
    loop do
      params = {
        'api_key' => api_key,
        '_fields' => core_fields.join(','),
        '_per_page' => per_page,
        '_page' => page
      }
      
      uri = URI(url)
      uri.query = URI.encode_www_form(params)
      
      retries = 0
      max_retries = 5
      success = false
      
      while retries < max_retries && !success
        begin
          wait_time = [2 ** retries, 30].min
          if retries > 0
            puts "  ⏳ Waiting #{wait_time}s before retry #{retries + 1}..."
            sleep(wait_time)
          end
          
          puts "📄 Page #{page + 1} (attempt #{retries + 1})"
          
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = 30
          http.read_timeout = 120
          
          response = http.request(Net::HTTP::Get.new(uri))
          
          if response.code == '200'
            data = JSON.parse(response.body)
            schools = data['results'] || []
            
            if schools.empty?
              puts "✅ Reached end of data"
              success = true
              break
            end
            
            new_schools_in_page = 0
            schools.each do |school|
              name = school['school.name']
              next unless name&.strip&.length&.positive?
              next if existing_names.include?(name.strip)  # スキップ済み学校
              
              begin
                ownership = case school['school.ownership']
                           when 1 then '州立'
                           when 2 then '私立'
                           when 3 then '営利'
                           else '不明'
                           end
                
                Condition.transaction do
                  condition = Condition.new(college: name.strip)
                  
                  condition.assign_attributes(
                    state: school['school.state'],
                    city: school['school.city'],
                    zip: school['school.zip'],
                    privateorpublic: ownership,
                    students: school['latest.student.size'],
                    graduation_rate: school['latest.completion.completion_rate_4yr_150nt'] || 
                                   school['latest.completion.completion_rate_less_than_4yr_150nt'],
                    acceptance_rate: school['latest.admissions.admission_rate.overall'],
                    website: school['school.school_url'],
                    sat_math_25: school['latest.admissions.sat_scores.25th_percentile.math'],
                    sat_math_75: school['latest.admissions.sat_scores.75th_percentile.math'],
                    sat_reading_25: school['latest.admissions.sat_scores.25th_percentile.critical_reading'],
                    sat_reading_75: school['latest.admissions.sat_scores.75th_percentile.critical_reading'],
                    act_composite_25: school['latest.admissions.act_scores.25th_percentile.cumulative'],
                    act_composite_75: school['latest.admissions.act_scores.75th_percentile.cumulative'],
                    retention_rate: school['latest.student.retention_rate.four_year.full_time'],
                    earnings_6yr_median: school['latest.earnings.6_yrs_after_entry.median'],
                    earnings_10yr_median: school['latest.earnings.10_yrs_after_entry.median'],
                    pell_grant_rate: school['latest.aid.pell_grant_rate'],
                    federal_loan_rate: school['latest.aid.federal_loan_rate'],
                    median_debt: school['latest.aid.median_debt.graduates.overall'],
                    percent_white: school['latest.student.demographics.race_ethnicity.white'],
                    percent_black: school['latest.student.demographics.race_ethnicity.black'],
                    percent_hispanic: school['latest.student.demographics.race_ethnicity.hispanic'],
                    percent_asian: school['latest.student.demographics.race_ethnicity.asian'],
                    percent_non_resident_alien: school['latest.student.demographics.race_ethnicity.non_resident_alien'],
                    percent_men: school['latest.student.demographics.men'],
                    percent_women: school['latest.student.demographics.women'],
                    faculty_salary: school['latest.faculty.salary'],
                    room_board_cost: school['latest.cost.roomboard.oncampus'],
                    tuition_in_state: school['latest.cost.tuition.in_state'],
                    tuition_out_state: school['latest.cost.tuition.out_of_state'],
                    hbcu: school['school.hbcu'] == 1,
                    tribal: school['school.tribal'] == 1,
                    hsi: school['school.hsi'] == 1,
                    women_only: school['school.womenonly'] == 1,
                    men_only: school['school.menonly'] == 1,
                    religious_affiliation: school['school.relaffil'],
                    carnegie_basic: school['school.carnegie_basic'],
                    locale: school['school.locale'],
                    urbanicity: school['school.locale']
                  )
                  
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
                  condition.comprehensive_data = school.to_json
                  
                  if condition.save
                    new_schools_saved += 1
                    new_schools_in_page += 1
                    existing_names.add(name.strip)
                  end
                end
                
              rescue => e
                puts "  ❌ Error with #{name}: #{e.message}"
              end
            end
            
            total_now = Condition.count
            puts "  ✅ #{schools.length} schools, #{new_schools_in_page} new → Total: #{total_now}"
            success = true
            
          elsif response.code == '429'
            puts "  ⚠ Rate limit hit, increasing wait time..."
            retries += 1
            sleep([5 * retries, 60].min)
          else
            puts "  ❌ API Error: #{response.code}"
            retries += 1
          end
          
        rescue => e
          puts "  ❌ Error: #{e.message}"
          retries += 1
          sleep(2)
        end
      end
      
      unless success
        puts "❌ Failed page #{page + 1} after #{max_retries} attempts"
        break
      end
      
      break if new_schools_saved >= 6000  # 安全な上限
      
      page += 1
      
      # API制限対策：より長い待機
      puts "  ⏳ Waiting 3 seconds before next page..."
      sleep(3)
    end
    
    final_count = Condition.count
    puts "\n🎉 IMPORT CONTINUATION COMPLETE!"
    puts "="*50
    puts "📊 RESULTS:"
    puts "  🎯 Started with: #{current_count} colleges"
    puts "  ✅ New colleges added: #{new_schools_saved}"
    puts "  📈 Final total: #{final_count} colleges"
    puts "  🎯 Target (6,429): #{((final_count.to_f / 6429) * 100).round(1)}% complete"
    
    puts "\n🔍 CURRENT DATA STATUS:"
    puts "  🎓 Colleges with graduation rates: #{Condition.where.not(graduation_rate: nil).count}"
    puts "  📝 Colleges with SAT scores: #{Condition.where.not(sat_math_25: nil).count}"
    puts "  🌐 Colleges with websites: #{Condition.where.not(website: nil).count}"
    puts "  💰 Colleges with tuition data: #{Condition.where.not(tuition: nil).count}"
    
    if final_count < 6429
      puts "\n📋 TO COMPLETE IMPORT:"
      puts "  Run this task again: rails import:continue_comprehensive_import"
      puts "  Estimated remaining: #{6429 - final_count} colleges"
    else
      puts "\n🎊 COMPLETE! All colleges imported successfully!"
    end
  end
end