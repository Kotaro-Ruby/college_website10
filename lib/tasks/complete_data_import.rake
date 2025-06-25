namespace :import do
  desc "Complete comprehensive import - ALL available College Scorecard API fields"
  task complete_all_data: :environment do
    require 'net/http'
    require 'json'
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY'] || 'YOUR_API_KEY_HERE'
    
    if api_key == 'YOUR_API_KEY_HERE'
      puts "ERROR: Please set COLLEGE_SCORECARD_API_KEY environment variable"
      exit 1
    end
    
    # 複数のチャンクに分けて、College Scorecard APIの全フィールドを取得
    field_chunks = [
      # Chunk 1: Basic Info + Test Scores (URL制限を避けるため分割)
      [
        'id', 'school.name', 'school.city', 'school.state', 'school.zip', 'school.ownership',
        'school.hbcu', 'school.tribal', 'school.hsi', 'school.menonly', 'school.womenonly',
        'school.relaffil', 'school.locale', 'school.carnegie_basic', 'school.carnegie_undergrad',
        'school.carnegie_size_setting', 'school.school_url', 'school.price_calculator_url',
        'school.ft_faculty_rate', 'school.tuition_revenue_per_fte',
        'latest.admissions.sat_scores.25th_percentile.critical_reading',
        'latest.admissions.sat_scores.75th_percentile.critical_reading',
        'latest.admissions.sat_scores.midpoint.critical_reading',
        'latest.admissions.sat_scores.25th_percentile.math',
        'latest.admissions.sat_scores.75th_percentile.math',
        'latest.admissions.sat_scores.midpoint.math',
        'latest.admissions.sat_scores.25th_percentile.writing',
        'latest.admissions.sat_scores.75th_percentile.writing',
        'latest.admissions.sat_scores.midpoint.writing',
        'latest.admissions.sat_scores.average.overall'
      ],
      
      # Chunk 2: ACT Scores + Admissions
      [
        'id', 'school.name',
        'latest.admissions.act_scores.25th_percentile.cumulative',
        'latest.admissions.act_scores.75th_percentile.cumulative',
        'latest.admissions.act_scores.midpoint.cumulative',
        'latest.admissions.act_scores.25th_percentile.english',
        'latest.admissions.act_scores.75th_percentile.english',
        'latest.admissions.act_scores.midpoint.english',
        'latest.admissions.act_scores.25th_percentile.math',
        'latest.admissions.act_scores.75th_percentile.math',
        'latest.admissions.act_scores.midpoint.math',
        'latest.admissions.act_scores.25th_percentile.writing',
        'latest.admissions.act_scores.75th_percentile.writing',
        'latest.admissions.act_scores.midpoint.writing',
        'latest.admissions.admission_rate.overall',
        'latest.admissions.test_requirements',
        'latest.admissions.yield_rate'
      ],
      
      # Chunk 3: Student Demographics + Size
      [
        'id', 'school.name',
        'latest.student.size', 'latest.student.size_all',
        'latest.student.undergraduate_size', 'latest.student.graduate_size',
        'latest.student.part_time_share', 'latest.student.undergraduate_part_time_share',
        'latest.student.retention_rate.four_year.full_time',
        'latest.student.retention_rate.lt_four_year.full_time',
        'latest.student.retention_rate.four_year.part_time',
        'latest.student.retention_rate.lt_four_year.part_time',
        'latest.student.transfer_rate',
        'latest.student.demographics.race_ethnicity.white',
        'latest.student.demographics.race_ethnicity.black',
        'latest.student.demographics.race_ethnicity.hispanic',
        'latest.student.demographics.race_ethnicity.asian',
        'latest.student.demographics.race_ethnicity.aian',
        'latest.student.demographics.race_ethnicity.nhpi',
        'latest.student.demographics.race_ethnicity.two_or_more',
        'latest.student.demographics.race_ethnicity.non_resident_alien',
        'latest.student.demographics.race_ethnicity.unknown'
      ],
      
      # Chunk 4: More Demographics + Family Info
      [
        'id', 'school.name',
        'latest.student.demographics.men', 'latest.student.demographics.women',
        'latest.student.demographics.age_entry', 'latest.student.demographics.age_entry_squared',
        'latest.student.demographics.first_generation',
        'latest.student.demographics.median_hh_inc',
        'latest.student.demographics.poverty_rate',
        'latest.student.demographics.unemployment_rate'
      ],
      
      # Chunk 5: Costs + Tuition
      [
        'id', 'school.name',
        'latest.cost.tuition.in_state', 'latest.cost.tuition.out_of_state',
        'latest.cost.tuition.program_year',
        'latest.cost.roomboard.oncampus', 'latest.cost.roomboard.offcampus',
        'latest.cost.othercosts.oncampus', 'latest.cost.othercosts.offcampus',
        'latest.cost.attendance.academic_year', 'latest.cost.attendance.program_year',
        'latest.cost.avg_net_price.overall', 'latest.cost.avg_net_price.public',
        'latest.cost.avg_net_price.private'
      ],
      
      # Chunk 6: Net Price by Income Level
      [
        'id', 'school.name',
        'latest.cost.avg_net_price.by_income_level.0-30000',
        'latest.cost.avg_net_price.by_income_level.30001-48000',
        'latest.cost.avg_net_price.by_income_level.48001-75000',
        'latest.cost.avg_net_price.by_income_level.75001-110000',
        'latest.cost.avg_net_price.by_income_level.110001-plus',
        'latest.cost.net_price.overall', 'latest.cost.net_price.public',
        'latest.cost.net_price.private',
        'latest.cost.net_price.by_income_level.0-30000',
        'latest.cost.net_price.by_income_level.30001-48000',
        'latest.cost.net_price.by_income_level.48001-75000',
        'latest.cost.net_price.by_income_level.75001-110000',
        'latest.cost.net_price.by_income_level.110001-plus'
      ],
      
      # Chunk 7: Financial Aid
      [
        'id', 'school.name',
        'latest.aid.pell_grant_rate', 'latest.aid.federal_loan_rate',
        'latest.aid.loan_principal',
        'latest.aid.median_debt.graduates.overall',
        'latest.aid.median_debt.graduates.monthly_payments',
        'latest.aid.median_debt.noncompleters.overall',
        'latest.aid.median_debt.noncompleters.monthly_payments'
      ],
      
      # Chunk 8: Completion Rates
      [
        'id', 'school.name',
        'latest.completion.completion_rate_4yr_150nt',
        'latest.completion.completion_rate_less_than_4yr_150nt',
        'latest.completion.completion_rate_4yr_150nt_pooled',
        'latest.completion.completion_rate_less_than_4yr_150nt_pooled',
        'latest.completion.completion_rate_4yr_100nt',
        'latest.completion.completion_rate_less_than_4yr_100nt',
        'latest.completion.completion_cohort_4yr_150nt',
        'latest.completion.completion_cohort_less_than_4yr_150nt',
        'latest.completion.completion_cohort_4yr_150nt_pooled',
        'latest.completion.completion_cohort_less_than_4yr_150nt_pooled'
      ],
      
      # Chunk 9: Earnings (6 years)
      [
        'id', 'school.name',
        'latest.earnings.6_yrs_after_entry.median',
        'latest.earnings.6_yrs_after_entry.mean',
        'latest.earnings.6_yrs_after_entry.10th_percentile',
        'latest.earnings.6_yrs_after_entry.25th_percentile',
        'latest.earnings.6_yrs_after_entry.75th_percentile',
        'latest.earnings.6_yrs_after_entry.90th_percentile'
      ],
      
      # Chunk 10: Earnings (8 & 10 years)
      [
        'id', 'school.name',
        'latest.earnings.8_yrs_after_entry.median',
        'latest.earnings.8_yrs_after_entry.mean',
        'latest.earnings.8_yrs_after_entry.10th_percentile',
        'latest.earnings.8_yrs_after_entry.25th_percentile',
        'latest.earnings.8_yrs_after_entry.75th_percentile',
        'latest.earnings.8_yrs_after_entry.90th_percentile',
        'latest.earnings.10_yrs_after_entry.median',
        'latest.earnings.10_yrs_after_entry.mean',
        'latest.earnings.10_yrs_after_entry.10th_percentile',
        'latest.earnings.10_yrs_after_entry.25th_percentile',
        'latest.earnings.10_yrs_after_entry.75th_percentile',
        'latest.earnings.10_yrs_after_entry.90th_percentile'
      ],
      
      # Chunk 11: Faculty Data
      [
        'id', 'school.name',
        'latest.faculty.salary', 'latest.faculty.salary_professor',
        'latest.faculty.salary_associate_professor',
        'latest.faculty.salary_assistant_professor',
        'latest.faculty.salary_instructor', 'latest.faculty.salary_lecturer',
        'latest.faculty.salary_all_ranks'
      ],
      
      # Chunk 12: Academic Programs (Majors) - Part 1
      [
        'id', 'school.name',
        'latest.academics.program_percentage.agriculture',
        'latest.academics.program_percentage.resources',
        'latest.academics.program_percentage.architecture',
        'latest.academics.program_percentage.ethnic_cultural_gender',
        'latest.academics.program_percentage.communication',
        'latest.academics.program_percentage.communications_technology',
        'latest.academics.program_percentage.computer',
        'latest.academics.program_percentage.personal_culinary',
        'latest.academics.program_percentage.education',
        'latest.academics.program_percentage.engineering',
        'latest.academics.program_percentage.engineering_technology',
        'latest.academics.program_percentage.language'
      ],
      
      # Chunk 13: Academic Programs (Majors) - Part 2
      [
        'id', 'school.name',
        'latest.academics.program_percentage.family_consumer_science',
        'latest.academics.program_percentage.legal',
        'latest.academics.program_percentage.english',
        'latest.academics.program_percentage.humanities',
        'latest.academics.program_percentage.library',
        'latest.academics.program_percentage.biological',
        'latest.academics.program_percentage.mathematics',
        'latest.academics.program_percentage.military',
        'latest.academics.program_percentage.multidiscipline',
        'latest.academics.program_percentage.parks_recreation_fitness',
        'latest.academics.program_percentage.philosophy_religious',
        'latest.academics.program_percentage.theology_religious_vocation'
      ],
      
      # Chunk 14: Academic Programs (Majors) - Part 3
      [
        'id', 'school.name',
        'latest.academics.program_percentage.physical_science',
        'latest.academics.program_percentage.science_technology',
        'latest.academics.program_percentage.psychology',
        'latest.academics.program_percentage.security_law_enforcement',
        'latest.academics.program_percentage.public_administration_social_service',
        'latest.academics.program_percentage.social_science',
        'latest.academics.program_percentage.construction',
        'latest.academics.program_percentage.mechanic_repair_technology',
        'latest.academics.program_percentage.precision_production',
        'latest.academics.program_percentage.transportation',
        'latest.academics.program_percentage.visual_performing',
        'latest.academics.program_percentage.health',
        'latest.academics.program_percentage.business_marketing',
        'latest.academics.program_percentage.history'
      ]
    ]
    
    puts "🚀 COMPLETE COMPREHENSIVE DATA IMPORT"
    puts "="*60
    puts "Fetching ALL available College Scorecard API data"
    puts "Total chunks: #{field_chunks.length}"
    puts "Estimated total fields: #{field_chunks.map(&:length).sum}"
    puts "="*60
    
    # 全データを統合するハッシュ
    all_schools_data = {}
    total_schools_found = 0
    
    # 各チャンクを順次処理
    field_chunks.each_with_index do |chunk_fields, chunk_index|
      puts "\n🔄 PROCESSING CHUNK #{chunk_index + 1}/#{field_chunks.length}"
      puts "Fields in this chunk: #{chunk_fields.length}"
      puts "Sample fields: #{chunk_fields[0..2].join(', ')}..."
      puts "="*40
      
      page = 0
      chunk_schools = 0
      
      while page < 200  # 安全な上限
        params = {
          'api_key' => api_key,
          'school.degrees_awarded.predominant' => '3',
          '_fields' => chunk_fields.join(','),
          '_per_page' => 100,
          '_page' => page
        }
        
        url = "https://api.data.gov/ed/collegescorecard/v1/schools?"
        uri = URI(url)
        uri.query = URI.encode_www_form(params)
        
        begin
          puts "  📄 Fetching page #{page + 1} (URL: #{uri.to_s.length} chars)..."
          
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = 30
          http.read_timeout = 90
          
          response = http.request(Net::HTTP::Get.new(uri))
          
          if response.code == '200'
            data = JSON.parse(response.body)
            schools = data['results'] || []
            
            if schools.empty?
              puts "  ✅ No more schools in chunk #{chunk_index + 1}"
              break
            end
            
            puts "  ✅ Got #{schools.length} schools"
            
            # データを統合
            schools.each do |school|
              school_id = school['id'] || school['school.name']
              next unless school_id
              
              if all_schools_data[school_id]
                # 既存データにマージ
                all_schools_data[school_id].merge!(school)
              else
                # 新規データ
                all_schools_data[school_id] = school
                total_schools_found += 1
              end
            end
            
            chunk_schools += schools.length
            
          else
            puts "  ❌ API Error: #{response.code}"
            if response.code == '414'
              puts "  ⚠ URL too long even with chunking"
            end
            break
          end
          
        rescue => e
          puts "  ❌ Error: #{e.message}"
          break
        end
        
        page += 1
        sleep(0.5) # API rate limiting
      end
      
      puts "✅ Chunk #{chunk_index + 1} complete: #{chunk_schools} school records"
      puts "💾 Total unique schools so far: #{all_schools_data.length}"
      
      # チャンク間でちょっと休憩
      sleep(2)
    end
    
    # 統合データをデータベースに保存
    puts "\n💾 SAVING COMPLETE INTEGRATED DATA"
    puts "="*50
    puts "Total unique schools to save: #{all_schools_data.length}"
    
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
          
          # 基本情報の完全更新
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
          
          # SAT/ACT 完全スコア
          condition.assign_attributes(
            sat_math_25: school['latest.admissions.sat_scores.25th_percentile.math'],
            sat_math_75: school['latest.admissions.sat_scores.75th_percentile.math'],
            sat_reading_25: school['latest.admissions.sat_scores.25th_percentile.critical_reading'],
            sat_reading_75: school['latest.admissions.sat_scores.75th_percentile.critical_reading'],
            act_composite_25: school['latest.admissions.act_scores.25th_percentile.cumulative'],
            act_composite_75: school['latest.admissions.act_scores.75th_percentile.cumulative']
          )
          
          # 全ての拡張フィールド
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
          
          # 全データをJSONで保存（専攻データ、ウェブサイト等すべて含む）
          condition.comprehensive_data = school.to_json
          
          if condition.save
            saved_count += 1
            if saved_count % 100 == 0
              puts "  ✓ Saved #{saved_count}/#{all_schools_data.length} (#{((saved_count.to_f / all_schools_data.length) * 100).round(1)}%)"
            end
          else
            error_count += 1
          end
        end
        
      rescue => e
        error_count += 1
        puts "  ❌ Error saving #{school['school.name']}: #{e.message}" if error_count <= 5
      end
    end
    
    puts "\n🎉 COMPLETE COMPREHENSIVE IMPORT FINISHED!"
    puts "="*60
    puts "📊 FINAL RESULTS:"
    puts "  🎯 Total unique schools processed: #{all_schools_data.length}"
    puts "  ✅ Successfully saved: #{saved_count}"
    puts "  ❌ Errors: #{error_count}"
    puts "  📈 Success rate: #{((saved_count.to_f / all_schools_data.length) * 100).round(2)}%"
    puts "\n✨ YOUR DATABASE NOW CONTAINS:"
    puts "  📊 Complete SAT/ACT scores (all components & percentiles)"
    puts "  💰 Comprehensive financial data (tuition, room/board, net prices)"
    puts "  👥 Detailed student demographics (race, gender, family income)"
    puts "  💼 Post-graduation earnings (6, 8, 10 years with percentiles)"
    puts "  👨‍🏫 Faculty salary data (all ranks)"
    puts "  📚 Academic program percentages (40+ major fields)"
    puts "  🏫 Campus characteristics (HBCU, Tribal, HSI, Carnegie, locale)"
    puts "  📈 Retention and completion rates (multiple timeframes)"
    puts "  💳 Financial aid data (Pell grants, loans, debt details)"
    puts "  🌐 Official website URLs and price calculators"
    puts "  🎓 Degree levels and program information"
    puts "="*60
    puts "🎊 CONGRATULATIONS! You now have the most comprehensive"
    puts "college database possible from official US government sources!"
  end
end

# 使い方:
# export COLLEGE_SCORECARD_API_KEY=your_key
# rails import:complete_all_data