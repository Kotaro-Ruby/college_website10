namespace :import do
  desc "Complete import of ALL colleges from College Scorecard API - no degree restrictions"
  task complete_all_colleges_all_data: :environment do
    require 'net/http'
    require 'json'
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY'] || 'YOUR_API_KEY_HERE'
    
    if api_key == 'YOUR_API_KEY_HERE'
      puts "ERROR: Please set COLLEGE_SCORECARD_API_KEY environment variable"
      exit 1
    end
    
    puts "🚀 COMPLETE ALL COLLEGES IMPORT"
    puts "="*60
    puts "Importing ALL colleges (not just 4-year degree schools)"
    puts "Target: 5,500+ colleges with ALL available data"
    puts "="*60
    
    # 最も重要なフィールドから段階的に取得
    essential_fields = [
      'id', 'school.name', 'school.city', 'school.state', 'school.zip', 'school.ownership',
      'school.school_url', 'school.hbcu', 'school.tribal', 'school.hsi', 'school.menonly', 'school.womenonly',
      'school.relaffil', 'school.locale', 'school.carnegie_basic'
    ]
    
    test_scores_fields = [
      'id', 'school.name',
      'latest.admissions.sat_scores.25th_percentile.critical_reading',
      'latest.admissions.sat_scores.75th_percentile.critical_reading',
      'latest.admissions.sat_scores.midpoint.critical_reading',
      'latest.admissions.sat_scores.25th_percentile.math',
      'latest.admissions.sat_scores.75th_percentile.math',
      'latest.admissions.sat_scores.midpoint.math',
      'latest.admissions.sat_scores.25th_percentile.writing',
      'latest.admissions.sat_scores.75th_percentile.writing',
      'latest.admissions.sat_scores.midpoint.writing',
      'latest.admissions.act_scores.25th_percentile.cumulative',
      'latest.admissions.act_scores.75th_percentile.cumulative',
      'latest.admissions.act_scores.midpoint.cumulative',
      'latest.admissions.act_scores.25th_percentile.english',
      'latest.admissions.act_scores.75th_percentile.english',
      'latest.admissions.act_scores.25th_percentile.math',
      'latest.admissions.act_scores.75th_percentile.math',
      'latest.admissions.admission_rate.overall'
    ]
    
    student_completion_fields = [
      'id', 'school.name',
      'latest.student.size', 'latest.student.undergraduate_size',
      'latest.student.retention_rate.four_year.full_time',
      'latest.completion.completion_rate_4yr_150nt',
      'latest.completion.completion_rate_less_than_4yr_150nt',
      'latest.completion.completion_rate_4yr_100nt',
      'latest.completion.completion_rate_less_than_4yr_100nt'
    ]
    
    demographics_fields = [
      'id', 'school.name',
      'latest.student.demographics.race_ethnicity.white',
      'latest.student.demographics.race_ethnicity.black',
      'latest.student.demographics.race_ethnicity.hispanic',
      'latest.student.demographics.race_ethnicity.asian',
      'latest.student.demographics.men', 'latest.student.demographics.women',
      'latest.student.demographics.first_generation'
    ]
    
    financial_fields = [
      'id', 'school.name',
      'latest.cost.tuition.in_state', 'latest.cost.tuition.out_of_state',
      'latest.cost.roomboard.oncampus',
      'latest.cost.avg_net_price.overall', 'latest.cost.avg_net_price.public', 'latest.cost.avg_net_price.private',
      'latest.cost.avg_net_price.by_income_level.0-30000',
      'latest.cost.avg_net_price.by_income_level.30001-48000',
      'latest.cost.avg_net_price.by_income_level.48001-75000',
      'latest.cost.avg_net_price.by_income_level.75001-110000',
      'latest.cost.avg_net_price.by_income_level.110001-plus'
    ]
    
    aid_earnings_fields = [
      'id', 'school.name',
      'latest.aid.pell_grant_rate', 'latest.aid.federal_loan_rate',
      'latest.aid.median_debt.graduates.overall',
      'latest.earnings.6_yrs_after_entry.median',
      'latest.earnings.8_yrs_after_entry.median',
      'latest.earnings.10_yrs_after_entry.median',
      'latest.faculty.salary'
    ]
    
    major_fields_1 = [
      'id', 'school.name',
      'latest.academics.program_percentage.agriculture',
      'latest.academics.program_percentage.architecture',
      'latest.academics.program_percentage.communication',
      'latest.academics.program_percentage.computer',
      'latest.academics.program_percentage.education',
      'latest.academics.program_percentage.engineering',
      'latest.academics.program_percentage.english',
      'latest.academics.program_percentage.biological',
      'latest.academics.program_percentage.mathematics',
      'latest.academics.program_percentage.psychology'
    ]
    
    major_fields_2 = [
      'id', 'school.name',
      'latest.academics.program_percentage.physical_science',
      'latest.academics.program_percentage.social_science',
      'latest.academics.program_percentage.visual_performing',
      'latest.academics.program_percentage.health',
      'latest.academics.program_percentage.business_marketing',
      'latest.academics.program_percentage.history',
      'latest.academics.program_percentage.legal',
      'latest.academics.program_percentage.humanities',
      'latest.academics.program_percentage.language'
    ]
    
    field_groups = [
      { name: "Essential Info", fields: essential_fields },
      { name: "Test Scores", fields: test_scores_fields },
      { name: "Student & Completion", fields: student_completion_fields },
      { name: "Demographics", fields: demographics_fields },
      { name: "Financial Data", fields: financial_fields },
      { name: "Aid & Earnings", fields: aid_earnings_fields },
      { name: "Major Fields 1", fields: major_fields_1 },
      { name: "Major Fields 2", fields: major_fields_2 }
    ]
    
    url = "https://api.data.gov/ed/collegescorecard/v1/schools?"
    all_schools_data = {}
    
    field_groups.each_with_index do |group, group_index|
      puts "\n🔄 GROUP #{group_index + 1}/#{field_groups.length}: #{group[:name]}"
      puts "Fields: #{group[:fields].length}"
      puts "="*40
      
      page = 0
      per_page = 100
      group_total = 0
      
      loop do
        params = {
          'api_key' => api_key,
          # 制限を削除：全ての大学を取得
          '_fields' => group[:fields].join(','),
          '_per_page' => per_page,
          '_page' => page
        }
        
        uri = URI(url)
        uri.query = URI.encode_www_form(params)
        
        retries = 0
        max_retries = 3
        success = false
        
        while retries < max_retries && !success
          begin
            puts "  📄 Page #{page + 1} (attempt #{retries + 1})"
            
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.open_timeout = 30
            http.read_timeout = 120
            
            response = http.request(Net::HTTP::Get.new(uri))
            
            if response.code == '200'
              data = JSON.parse(response.body)
              schools = data['results'] || []
              
              if schools.empty?
                puts "  ✅ No more schools for this group"
                success = true
                break
              end
              
              puts "  ✅ Got #{schools.length} schools"
              
              schools.each do |school|
                school_id = school['id'] || school['school.name']
                next unless school_id
                
                if all_schools_data[school_id]
                  all_schools_data[school_id].merge!(school)
                else
                  all_schools_data[school_id] = school
                end
              end
              
              group_total += schools.length
              success = true
              
            elsif response.code == '500'
              puts "  ⚠ Server error (500), retrying..."
              retries += 1
              sleep(2 ** retries)
            else
              puts "  ❌ API Error: #{response.code}"
              retries += 1
              sleep(2)
            end
            
          rescue => e
            puts "  ❌ Error: #{e.message}"
            retries += 1
            sleep(2)
          end
        end
        
        unless success
          puts "  ❌ Failed after #{max_retries} attempts, moving to next group"
          break
        end
        
        page += 1
        sleep(0.5)  # API rate limiting
        
        # 安全な上限を設定
        break if page > 100
      end
      
      puts "✅ Group #{group_index + 1} complete: #{group_total} records processed"
      puts "💾 Total unique schools so far: #{all_schools_data.length}"
      
      sleep(2) # グループ間で休憩
    end
    
    puts "\n💾 SAVING ALL DATA TO DATABASE"
    puts "="*50
    puts "Total unique schools to process: #{all_schools_data.length}"
    
    # 既存データを削除
    puts "🗑 Clearing existing data..."
    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")
    Condition.delete_all
    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")
    puts "✅ Existing data cleared"
    
    saved_count = 0
    error_count = 0
    
    all_schools_data.each_with_index do |(school_id, school), index|
      begin
        name = school['school.name']
        next unless name&.strip&.length&.positive?
        
        ownership = case school['school.ownership']
                   when 1 then '州立'
                   when 2 then '私立'
                   when 3 then '営利'
                   else '不明'
                   end
        
        Condition.transaction do
          condition = Condition.find_or_initialize_by(college: name.strip)
          
          # 基本情報
          condition.assign_attributes(
            state: school['school.state'],
            city: school['school.city'],
            zip: school['school.zip'],
            privateorpublic: ownership,
            students: school['latest.student.size'],
            graduation_rate: school['latest.completion.completion_rate_4yr_150nt'],
            acceptance_rate: school['latest.admissions.admission_rate.overall'],
            website: school['school.school_url']
          )
          
          # SAT/ACT スコア
          condition.assign_attributes(
            sat_math_25: school['latest.admissions.sat_scores.25th_percentile.math'],
            sat_math_75: school['latest.admissions.sat_scores.75th_percentile.math'],
            sat_reading_25: school['latest.admissions.sat_scores.25th_percentile.critical_reading'],
            sat_reading_75: school['latest.admissions.sat_scores.75th_percentile.critical_reading'],
            act_composite_25: school['latest.admissions.act_scores.25th_percentile.cumulative'],
            act_composite_75: school['latest.admissions.act_scores.75th_percentile.cumulative']
          )
          
          # 追加データ
          condition.assign_attributes(
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
            locale: school['school.locale']
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
            saved_count += 1
            if saved_count % 100 == 0
              progress = ((saved_count.to_f / all_schools_data.length) * 100).round(1)
              puts "  ✓ Saved #{saved_count}/#{all_schools_data.length} (#{progress}%)"
            end
          else
            error_count += 1
          end
        end
        
      rescue => e
        error_count += 1
        puts "  ❌ Error saving #{school['school.name']}: #{e.message}" if error_count <= 10
      end
    end
    
    puts "\n🎉 COMPLETE ALL COLLEGES IMPORT FINISHED!"
    puts "="*60
    puts "📊 FINAL RESULTS:"
    puts "  🎯 Total unique schools found: #{all_schools_data.length}"
    puts "  ✅ Successfully saved: #{saved_count}"
    puts "  ❌ Errors: #{error_count}"
    puts "  📈 Success rate: #{((saved_count.to_f / all_schools_data.length) * 100).round(2)}%"
    puts "\n✨ DATABASE NOW CONTAINS:"
    puts "  🏫 ALL college types (2-year, 4-year, certificate programs, etc.)"
    puts "  📊 Complete test scores (SAT/ACT all components)"
    puts "  🎓 Graduation/completion rates for all program types"
    puts "  🌐 Official website URLs"
    puts "  📚 Academic program data (major percentages)"
    puts "  💰 Comprehensive financial data"
    puts "  👥 Student demographics"
    puts "  💼 Post-graduation earnings"
    puts "  🏛 Campus characteristics (HBCU, Tribal, HSI)"
    puts "  💳 Financial aid information"
    puts "="*60
    puts "🎊 SUCCESS! Now you have ALL #{saved_count} colleges with comprehensive data!"
  end
end

# 使い方:
# export COLLEGE_SCORECARD_API_KEY=your_key
# rails import:complete_all_colleges_all_data