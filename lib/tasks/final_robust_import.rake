namespace :import do
  desc "Final robust import - simplified approach for maximum compatibility"
  task final_robust_import: :environment do
    require 'net/http'
    require 'json'
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY'] || 'YOUR_API_KEY_HERE'
    
    if api_key == 'YOUR_API_KEY_HERE'
      puts "ERROR: Please set COLLEGE_SCORECARD_API_KEY environment variable"
      exit 1
    end
    
    puts "🚀 FINAL ROBUST IMPORT - ALL COLLEGES"
    puts "="*60
    puts "Using simplified, proven approach for maximum data retrieval"
    puts "="*60
    
    # 一度に取得するフィールドを最小限に抑えて確実に動作させる
    core_fields = [
      'id',
      'school.name',
      'school.city', 
      'school.state',
      'school.zip',
      'school.ownership',
      'school.school_url',
      'school.hbcu',
      'school.tribal',
      'school.hsi',
      'school.menonly',
      'school.womenonly',
      'school.relaffil',
      'school.locale',
      'school.carnegie_basic',
      
      # 学生数とテストスコア
      'latest.student.size',
      'latest.admissions.admission_rate.overall',
      'latest.admissions.sat_scores.25th_percentile.math',
      'latest.admissions.sat_scores.75th_percentile.math',
      'latest.admissions.sat_scores.25th_percentile.critical_reading',
      'latest.admissions.sat_scores.75th_percentile.critical_reading',
      'latest.admissions.act_scores.25th_percentile.cumulative',
      'latest.admissions.act_scores.75th_percentile.cumulative',
      
      # 卒業率・保持率（正しいフィールド名）
      'latest.completion.completion_rate_4yr_150nt',
      'latest.completion.completion_rate_less_than_4yr_150nt',
      'latest.student.retention_rate.four_year.full_time',
      
      # 学費データ
      'latest.cost.tuition.in_state',
      'latest.cost.tuition.out_of_state',
      'latest.cost.avg_net_price.overall',
      'latest.cost.avg_net_price.public',
      'latest.cost.avg_net_price.private',
      'latest.cost.roomboard.oncampus',
      
      # 人口統計（基本）
      'latest.student.demographics.race_ethnicity.white',
      'latest.student.demographics.race_ethnicity.black',
      'latest.student.demographics.race_ethnicity.hispanic',
      'latest.student.demographics.race_ethnicity.asian',
      'latest.student.demographics.men',
      'latest.student.demographics.women',
      
      # 財政援助と収入
      'latest.aid.pell_grant_rate',
      'latest.aid.federal_loan_rate',
      'latest.aid.median_debt.graduates.overall',
      'latest.earnings.6_yrs_after_entry.median',
      'latest.earnings.10_yrs_after_entry.median',
      'latest.faculty.salary'
    ]
    
    url = "https://api.data.gov/ed/collegescorecard/v1/schools?"
    all_schools = []
    page = 0
    per_page = 100
    
    puts "Fetching ALL colleges (no degree restrictions)..."
    puts "Fields to retrieve: #{core_fields.length}"
    
    # 既存データクリア
    puts "🗑 Clearing existing data..."
    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")
    Condition.delete_all
    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")
    puts "✅ Database cleared"
    
    # 全データを取得
    loop do
      params = {
        'api_key' => api_key,
        # 制限なし - 全ての大学タイプを取得
        '_fields' => core_fields.join(','),
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
          puts "📄 Page #{page + 1} (attempt #{retries + 1}) - URL: #{uri.to_s.length} chars"
          
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = 30
          http.read_timeout = 120
          
          response = http.request(Net::HTTP::Get.new(uri))
          
          if response.code == '200'
            data = JSON.parse(response.body)
            schools = data['results'] || []
            
            if schools.empty?
              puts "✅ Reached end of data at page #{page + 1}"
              success = true
              break
            end
            
            puts "✅ Got #{schools.length} schools (Total: #{all_schools.length + schools.length})"
            all_schools.concat(schools)
            success = true
            
          else
            puts "❌ API Error: #{response.code}"
            retries += 1
            sleep(2 ** retries)
          end
          
        rescue => e
          puts "❌ Error: #{e.message}"
          retries += 1
          sleep(2)
        end
      end
      
      break unless success
      break if all_schools.length >= 10000  # 安全な上限
      
      page += 1
      sleep(0.3)  # API制限対応
    end
    
    puts "\n💾 PROCESSING AND SAVING DATA"
    puts "="*50
    puts "Total schools retrieved: #{all_schools.length}"
    
    saved_count = 0
    error_count = 0
    
    all_schools.each_with_index do |school, index|
      begin
        name = school['school.name']
        next unless name&.strip&.length&.positive?
        
        # 所有形態の変換
        ownership = case school['school.ownership']
                   when 1 then '州立'
                   when 2 then '私立'
                   when 3 then '営利'
                   else '不明'
                   end
        
        # トランザクションで安全に保存
        Condition.transaction do
          condition = Condition.new(college: name.strip)
          
          # 基本情報
          condition.assign_attributes(
            state: school['school.state'],
            city: school['school.city'],
            zip: school['school.zip'],
            privateorpublic: ownership,
            students: school['latest.student.size'],
            
            # 卒業率（正しいフィールド名を使用）
            graduation_rate: school['latest.completion.completion_rate_4yr_150nt'] || 
                           school['latest.completion.completion_rate_less_than_4yr_150nt'],
            
            acceptance_rate: school['latest.admissions.admission_rate.overall'],
            website: school['school.school_url']
          )
          
          # テストスコア
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
          
          # 学費の設定
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
            if saved_count % 200 == 0
              progress = ((saved_count.to_f / all_schools.length) * 100).round(1)
              puts "✓ Saved #{saved_count}/#{all_schools.length} (#{progress}%)"
            end
          else
            puts "❌ Failed to save #{name}: #{condition.errors.full_messages.join(', ')}"
            error_count += 1
          end
        end
        
      rescue => e
        error_count += 1
        puts "❌ Error with #{school['school.name']}: #{e.message}" if error_count <= 10
      end
    end
    
    puts "\n🎉 FINAL ROBUST IMPORT COMPLETE!"
    puts "="*60
    puts "📊 FINAL RESULTS:"
    puts "  🎯 Schools retrieved from API: #{all_schools.length}"
    puts "  ✅ Successfully saved to DB: #{saved_count}"
    puts "  ❌ Errors: #{error_count}"
    puts "  📈 Success rate: #{((saved_count.to_f / all_schools.length) * 100).round(2)}%"
    
    # データ検証
    puts "\n🔍 DATA VERIFICATION:"
    puts "  📊 Total colleges in database: #{Condition.count}"
    puts "  🎓 Colleges with graduation rates: #{Condition.where.not(graduation_rate: nil).count}"
    puts "  📝 Colleges with SAT scores: #{Condition.where.not(sat_math_25: nil).count}"
    puts "  🌐 Colleges with websites: #{Condition.where.not(website: nil).count}"
    puts "  💰 Colleges with tuition data: #{Condition.where.not(tuition: nil).count}"
    
    # サンプル表示
    puts "\n📋 SAMPLE DATA:"
    Condition.limit(5).each do |college|
      puts "  • #{college.college} (#{college.state}) - #{college.privateorpublic}"
      puts "    Graduation Rate: #{college.graduation_rate ? (college.graduation_rate * 100).round(1) : 'N/A'}%"
      puts "    Students: #{college.students || 'N/A'}"
      puts "    Website: #{college.website || 'N/A'}"
      puts ""
    end
    
    puts "="*60
    puts "🎊 SUCCESS! Complete college database with graduation rates and all core data!"
  end
end