namespace :import do
  desc "Chunked import ALL data from College Scorecard API - splits fields to avoid 414 errors"
  task chunked_comprehensive_college_scorecard: :environment do
    require 'net/http'
    require 'json'
    
    # College Scorecard API
    api_key = ENV['COLLEGE_SCORECARD_API_KEY'] || 'YOUR_API_KEY_HERE'
    
    if api_key == 'YOUR_API_KEY_HERE'
      puts "ERROR: Please set COLLEGE_SCORECARD_API_KEY environment variable"
      puts "Get your free API key from: https://collegescorecard.ed.gov/data/documentation/"
      exit 1
    end
    
    # URLの長さ制限を回避するため、フィールドを複数のチャンクに分割
    field_chunks = [
      # Chunk 1: Basic Info + SAT/ACT
      [
        'id', 'ope6_id', 'school.name', 'school.city', 'school.state', 'school.zip',
        'school.ownership', 'school.hbcu', 'school.tribal', 'school.hsi', 'school.menonly', 'school.womenonly',
        'school.relaffil', 'school.locale', 'school.carnegie_basic', 'school.school_url',
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
      ],
      
      # Chunk 2: Student Demographics + Costs
      [
        'id', 'school.name',
        'latest.student.size', 'latest.student.undergraduate_size',
        'latest.student.retention_rate.four_year.full_time',
        'latest.student.demographics.race_ethnicity.white',
        'latest.student.demographics.race_ethnicity.black',
        'latest.student.demographics.race_ethnicity.hispanic',
        'latest.student.demographics.race_ethnicity.asian',
        'latest.student.demographics.men', 'latest.student.demographics.women',
        'latest.student.demographics.first_generation',
        'latest.cost.tuition.in_state', 'latest.cost.tuition.out_of_state',
        'latest.cost.roomboard.oncampus',
        'latest.cost.avg_net_price.overall', 'latest.cost.avg_net_price.public', 'latest.cost.avg_net_price.private',
        'latest.cost.avg_net_price.by_income_level.0-30000',
        'latest.cost.avg_net_price.by_income_level.30001-48000',
        'latest.cost.avg_net_price.by_income_level.48001-75000',
        'latest.cost.avg_net_price.by_income_level.75001-110000',
        'latest.cost.avg_net_price.by_income_level.110001-plus'
      ],
      
      # Chunk 3: Financial Aid + Completion
      [
        'id', 'school.name',
        'latest.aid.pell_grant_rate', 'latest.aid.federal_loan_rate',
        'latest.aid.median_debt.graduates.overall',
        'latest.completion.completion_rate_4yr_150nt',
        'latest.completion.completion_rate_less_than_4yr_150nt',
        'latest.earnings.6_yrs_after_entry.median',
        'latest.earnings.8_yrs_after_entry.median',
        'latest.earnings.10_yrs_after_entry.median',
        'latest.earnings.6_yrs_after_entry.mean',
        'latest.earnings.10_yrs_after_entry.mean',
        'latest.faculty.salary'
      ],
      
      # Chunk 4: Academic Programs (Major percentages)
      [
        'id', 'school.name',
        'latest.academics.program_percentage.agriculture',
        'latest.academics.program_percentage.resources',
        'latest.academics.program_percentage.architecture',
        'latest.academics.program_percentage.communication',
        'latest.academics.program_percentage.computer',
        'latest.academics.program_percentage.education',
        'latest.academics.program_percentage.engineering',
        'latest.academics.program_percentage.english',
        'latest.academics.program_percentage.biological',
        'latest.academics.program_percentage.mathematics',
        'latest.academics.program_percentage.psychology',
        'latest.academics.program_percentage.social_science',
        'latest.academics.program_percentage.visual_performing',
        'latest.academics.program_percentage.health',
        'latest.academics.program_percentage.business_marketing',
        'latest.academics.program_percentage.history',
        'latest.academics.program_percentage.physical_science',
        'latest.academics.program_percentage.legal'
      ]
    ]
    
    # 統計
    total_schools = 0
    updated_schools = 0
    errors = 0
    per_page = 50
    max_pages = 150
    
    puts "🚀 CHUNKED COMPREHENSIVE COLLEGE SCORECARD IMPORT"
    puts "="*60
    puts "Splitting into #{field_chunks.length} field chunks to avoid URL length limits"
    puts "Target: ALL 5,546 colleges"
    puts "="*60
    
    # 全ページのデータを格納するハッシュ
    all_schools_data = {}
    
    # 各チャンクでデータを取得
    field_chunks.each_with_index do |chunk_fields, chunk_index|
      puts "\n🔄 PROCESSING CHUNK #{chunk_index + 1}/#{field_chunks.length}"
      puts "Fields in chunk: #{chunk_fields.length}"
      puts "="*40
      
      page = 0
      chunk_schools = 0
      
      while page < max_pages
        puts "📄 Chunk #{chunk_index + 1}, Page #{page + 1}"
        
        params = {
          'api_key' => api_key,
          'school.degrees_awarded.predominant' => '3',
          '_fields' => chunk_fields.join(','),
          '_per_page' => per_page,
          '_page' => page
        }
        
        url = "https://api.data.gov/ed/collegescorecard/v1/schools?"
        uri = URI(url)
        uri.query = URI.encode_www_form(params)
        
        # URL長さチェック
        if uri.to_s.length > 8000
          puts "⚠ Warning: URL length is #{uri.to_s.length} characters"
        end
        
        retries = 0
        max_retries = 3
        success = false
        
        while retries < max_retries && !success
          begin
            puts "  🌐 Fetching (attempt #{retries + 1})..."
            
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.open_timeout = 30
            http.read_timeout = 60
            
            response = http.request(Net::HTTP::Get.new(uri))
            
            if response.code == '200'
              data = JSON.parse(response.body)
              schools = data['results'] || []
              
              if schools.empty?
                puts "  ✅ No more schools in chunk #{chunk_index + 1}"
                success = true
                break
              end
              
              puts "  ✅ Got #{schools.length} schools from chunk #{chunk_index + 1}"
              
              # データを統合
              schools.each do |school|
                school_id = school['id'] || school['school.name']
                next unless school_id
                
                if all_schools_data[school_id]
                  # 既存データに新しいフィールドを追加
                  all_schools_data[school_id].merge!(school)
                else
                  # 新しい学校データ
                  all_schools_data[school_id] = school
                end
              end
              
              chunk_schools += schools.length
              success = true
              
            elsif response.code == '414'
              puts "  ❌ URL still too long even after chunking"
              retries = max_retries # Give up on this chunk
            else
              puts "  ⚠ API Error: #{response.code}"
              retries += 1
              sleep(2 ** retries)
            end
            
          rescue => e
            puts "  ⚠ Error: #{e.message}"
            retries += 1
            sleep(2)
          end
        end
        
        unless success
          puts "  ❌ Failed chunk #{chunk_index + 1}, page #{page + 1}"
          break
        end
        
        page += 1
        sleep(1) # API rate limiting
      end
      
      puts "✅ Chunk #{chunk_index + 1} complete: #{chunk_schools} school records"
    end
    
    # 統合されたデータをデータベースに保存
    puts "\n💾 SAVING INTEGRATED DATA TO DATABASE"
    puts "="*40
    
    saved_count = 0
    error_count = 0
    
    all_schools_data.each do |school_id, school|
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
          
          # その他の重要フィールド  
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
          
          # 包括的データをJSONで保存
          condition.comprehensive_data = school.to_json
          
          if condition.save
            saved_count += 1
            if saved_count % 100 == 0
              puts "  ✓ Saved #{saved_count} schools so far..."
            end
          else
            puts "  ❌ Failed to save: #{name}"
            error_count += 1
          end
        end
        
      rescue => e
        puts "  ❌ Error saving: #{school['school.name']} - #{e.message}"
        error_count += 1
      end
    end
    
    puts "\n🎉 CHUNKED IMPORT COMPLETE!"
    puts "="*50
    puts "📊 RESULTS:"
    puts "  🎯 Total unique schools: #{all_schools_data.length}"
    puts "  ✅ Successfully saved: #{saved_count}"
    puts "  ❌ Errors: #{error_count}"
    puts "  📈 Success rate: #{((saved_count.to_f / all_schools_data.length) * 100).round(2)}%"
    puts "\n✨ Your database now includes:"
    puts "  📊 SAT/ACT scores (25th, 75th percentiles)"
    puts "  💰 Comprehensive financial data"
    puts "  👥 Student demographics"
    puts "  💼 Post-graduation earnings"
    puts "  📚 Academic program data"
    puts "  🏫 Campus characteristics"
  end
end

# 使い方:
# export COLLEGE_SCORECARD_API_KEY=your_key
# rails import:chunked_comprehensive_college_scorecard