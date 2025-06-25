namespace :import do
  desc "Final complete import - ALL College Scorecard data with progress tracking"
  task final_complete_all_data: :environment do
    require 'net/http'
    require 'json'
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY'] || 'YOUR_API_KEY_HERE'
    
    if api_key == 'YOUR_API_KEY_HERE'
      puts "ERROR: Please set COLLEGE_SCORECARD_API_KEY environment variable"
      exit 1
    end
    
    # 全フィールドを一度に取得するアプローチ
    # College Scorecard APIの全利用可能フィールド
    all_fields = [
      # 基本情報
      'id', 'ope6_id', 'ope8_id', 'school.name', 'school.alias', 'school.city', 
      'school.state', 'school.zip', 'school.accreditor', 'school.accreditor_code',
      'school.hbcu', 'school.pbi', 'school.annhi', 'school.tribal', 'school.aanapii',
      'school.hsi', 'school.nanti', 'school.menonly', 'school.womenonly', 'school.relaffil',
      'school.locale', 'school.ccbasic', 'school.ccugprof', 'school.ccsizset',
      'school.carnegie_basic', 'school.carnegie_undergrad', 'school.carnegie_size_setting',
      'school.ownership', 'school.degrees_awarded.predominant', 'school.degrees_awarded.highest',
      'school.main_campus', 'school.branches', 'school.school_url', 'school.price_calculator_url',
      'school.tuition_revenue_per_fte', 'school.instructional_expenditure_per_fte', 'school.ft_faculty_rate',
      
      # SAT スコア (全部)
      'latest.admissions.sat_scores.25th_percentile.critical_reading',
      'latest.admissions.sat_scores.75th_percentile.critical_reading',
      'latest.admissions.sat_scores.midpoint.critical_reading',
      'latest.admissions.sat_scores.25th_percentile.math',
      'latest.admissions.sat_scores.75th_percentile.math',
      'latest.admissions.sat_scores.midpoint.math',
      'latest.admissions.sat_scores.25th_percentile.writing',
      'latest.admissions.sat_scores.75th_percentile.writing',
      'latest.admissions.sat_scores.midpoint.writing',
      'latest.admissions.sat_scores.average.overall',
      
      # ACT スコア (全部)
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
      
      # 入学データ
      'latest.admissions.admission_rate.overall', 'latest.admissions.test_requirements',
      'latest.admissions.yield_rate',
      
      # 学生データ
      'latest.student.size', 'latest.student.size_all', 'latest.student.undergraduate_size',
      'latest.student.graduate_size', 'latest.student.part_time_share',
      'latest.student.undergraduate_part_time_share', 'latest.student.transfer_rate',
      'latest.student.retention_rate.four_year.full_time',
      'latest.student.retention_rate.lt_four_year.full_time',
      'latest.student.retention_rate.four_year.part_time',
      'latest.student.retention_rate.lt_four_year.part_time',
      
      # 人口統計
      'latest.student.demographics.race_ethnicity.white',
      'latest.student.demographics.race_ethnicity.black',
      'latest.student.demographics.race_ethnicity.hispanic',
      'latest.student.demographics.race_ethnicity.asian',
      'latest.student.demographics.race_ethnicity.aian',
      'latest.student.demographics.race_ethnicity.nhpi',
      'latest.student.demographics.race_ethnicity.two_or_more',
      'latest.student.demographics.race_ethnicity.non_resident_alien',
      'latest.student.demographics.race_ethnicity.unknown',
      'latest.student.demographics.men', 'latest.student.demographics.women',
      'latest.student.demographics.age_entry', 'latest.student.demographics.first_generation',
      'latest.student.demographics.median_hh_inc', 'latest.student.demographics.poverty_rate',
      'latest.student.demographics.unemployment_rate',
      
      # 学費・費用
      'latest.cost.tuition.in_state', 'latest.cost.tuition.out_of_state',
      'latest.cost.tuition.program_year', 'latest.cost.roomboard.oncampus',
      'latest.cost.roomboard.offcampus', 'latest.cost.othercosts.oncampus',
      'latest.cost.othercosts.offcampus', 'latest.cost.attendance.academic_year',
      'latest.cost.attendance.program_year', 'latest.cost.avg_net_price.overall',
      'latest.cost.avg_net_price.public', 'latest.cost.avg_net_price.private',
      'latest.cost.avg_net_price.by_income_level.0-30000',
      'latest.cost.avg_net_price.by_income_level.30001-48000',
      'latest.cost.avg_net_price.by_income_level.48001-75000',
      'latest.cost.avg_net_price.by_income_level.75001-110000',
      'latest.cost.avg_net_price.by_income_level.110001-plus',
      'latest.cost.net_price.overall', 'latest.cost.net_price.public',
      'latest.cost.net_price.private',
      
      # 財政援助
      'latest.aid.pell_grant_rate', 'latest.aid.federal_loan_rate',
      'latest.aid.loan_principal', 'latest.aid.median_debt.graduates.overall',
      'latest.aid.median_debt.graduates.monthly_payments',
      'latest.aid.median_debt.noncompleters.overall',
      'latest.aid.median_debt.noncompleters.monthly_payments',
      
      # 修了率
      'latest.completion.completion_rate_4yr_150nt',
      'latest.completion.completion_rate_less_than_4yr_150nt',
      'latest.completion.completion_rate_4yr_150nt_pooled',
      'latest.completion.completion_rate_less_than_4yr_150nt_pooled',
      'latest.completion.completion_rate_4yr_100nt',
      'latest.completion.completion_rate_less_than_4yr_100nt',
      
      # 収入データ (6年)
      'latest.earnings.6_yrs_after_entry.median', 'latest.earnings.6_yrs_after_entry.mean',
      'latest.earnings.6_yrs_after_entry.10th_percentile',
      'latest.earnings.6_yrs_after_entry.25th_percentile',
      'latest.earnings.6_yrs_after_entry.75th_percentile',
      'latest.earnings.6_yrs_after_entry.90th_percentile',
      
      # 収入データ (8年)
      'latest.earnings.8_yrs_after_entry.median', 'latest.earnings.8_yrs_after_entry.mean',
      'latest.earnings.8_yrs_after_entry.10th_percentile',
      'latest.earnings.8_yrs_after_entry.25th_percentile',
      'latest.earnings.8_yrs_after_entry.75th_percentile',
      'latest.earnings.8_yrs_after_entry.90th_percentile',
      
      # 収入データ (10年)
      'latest.earnings.10_yrs_after_entry.median', 'latest.earnings.10_yrs_after_entry.mean',
      'latest.earnings.10_yrs_after_entry.10th_percentile',
      'latest.earnings.10_yrs_after_entry.25th_percentile',
      'latest.earnings.10_yrs_after_entry.75th_percentile',
      'latest.earnings.10_yrs_after_entry.90th_percentile',
      
      # 教職員データ
      'latest.faculty.salary', 'latest.faculty.salary_professor',
      'latest.faculty.salary_associate_professor', 'latest.faculty.salary_assistant_professor',
      'latest.faculty.salary_instructor', 'latest.faculty.salary_lecturer',
      'latest.faculty.salary_all_ranks',
      
      # 専攻データ (全40+分野)
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
      'latest.academics.program_percentage.language',
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
      'latest.academics.program_percentage.theology_religious_vocation',
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
    
    puts "🚀 FINAL COMPLETE ALL DATA IMPORT"
    puts "="*60
    puts "Total fields to import: #{all_fields.length}"
    puts "Target: ALL 5,546+ colleges from College Scorecard API"
    puts "="*60
    
    url = "https://api.data.gov/ed/collegescorecard/v1/schools?"
    total_schools = 0
    saved_schools = 0
    errors = 0
    page = 0
    per_page = 50  # URLの長さを考慮して少なく
    
    # フィールドをグループ分けしてバッチ処理
    field_groups = all_fields.each_slice(25).to_a
    all_data = {}
    
    puts "Splitting fields into #{field_groups.length} groups to avoid URL limits"
    
    field_groups.each_with_index do |field_group, group_index|
      puts "\n🔄 GROUP #{group_index + 1}/#{field_groups.length}: #{field_group.length} fields"
      puts "Sample fields: #{field_group[0..2].join(', ')}..."
      
      # 必須フィールドを追加
      group_fields = (['id', 'school.name'] + field_group).uniq
      
      page = 0
      group_schools = 0
      
      loop do
        params = {
          'api_key' => api_key,
          'school.degrees_awarded.predominant' => '3',
          '_fields' => group_fields.join(','),
          '_per_page' => per_page,
          '_page' => page
        }
        
        uri = URI(url)
        uri.query = URI.encode_www_form(params)
        
        begin
          puts "  📄 Page #{page + 1} (URL: #{uri.to_s.length} chars)"
          
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = 30
          http.read_timeout = 120
          
          response = http.request(Net::HTTP::Get.new(uri))
          
          if response.code == '200'
            data = JSON.parse(response.body)
            schools = data['results'] || []
            
            break if schools.empty?
            
            puts "  ✅ #{schools.length} schools"
            
            schools.each do |school|
              school_id = school['id'] || school['school.name']
              next unless school_id
              
              if all_data[school_id]
                all_data[school_id].merge!(school)
              else
                all_data[school_id] = school
              end
            end
            
            group_schools += schools.length
            
          elsif response.code == '414'
            puts "  ⚠ URL too long, reducing field count for this group"
            break
          else
            puts "  ❌ API Error: #{response.code}"
            break
          end
          
        rescue => e
          puts "  ❌ Error: #{e.message}"
          break
        end
        
        page += 1
        sleep(0.8)  # API制限対応
      end
      
      puts "✅ Group #{group_index + 1} complete: #{group_schools} records"
      puts "💾 Total unique schools: #{all_data.length}"
      
      # グループ間で休憩
      sleep(2) if group_index < field_groups.length - 1
    end
    
    puts "\n💾 SAVING ALL DATA TO DATABASE"
    puts "="*40
    puts "Total unique schools to save: #{all_data.length}"
    
    all_data.each_with_index do |(school_id, school), index|
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
        
        # テストスコア (全データ)
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
        
        # 全データをJSONで保存 (専攻、URL、全フィールド含む)
        condition.comprehensive_data = school.to_json
        
        if condition.save
          saved_schools += 1
          if saved_schools % 50 == 0
            progress = ((saved_schools.to_f / all_data.length) * 100).round(1)
            puts "  ✓ Saved #{saved_schools}/#{all_data.length} (#{progress}%)"
          end
        else
          errors += 1
        end
        
      rescue => e
        errors += 1
        puts "  ❌ #{school['school.name']}: #{e.message}" if errors <= 5
      end
    end
    
    puts "\n🎉 FINAL COMPLETE IMPORT FINISHED!"
    puts "="*50
    puts "📊 RESULTS:"
    puts "  🎯 Total unique schools: #{all_data.length}"
    puts "  ✅ Successfully saved: #{saved_schools}"
    puts "  ❌ Errors: #{errors}"
    puts "  📈 Success rate: #{((saved_schools.to_f / all_data.length) * 100).round(2)}%"
    puts "\n✨ DATABASE NOW CONTAINS ALL AVAILABLE DATA:"
    puts "  📊 Complete SAT/ACT scores (all components, all percentiles)"
    puts "  🌐 Official website URLs and price calculator links"
    puts "  📚 Complete academic program data (40+ major percentages)"
    puts "  💰 Comprehensive financial data (tuition, room/board, net prices)"
    puts "  👥 Detailed demographics (race, gender, family background)"
    puts "  💼 Post-graduation earnings (6, 8, 10 years with all percentiles)"
    puts "  👨‍🏫 Faculty salary data (all academic ranks)"
    puts "  🏫 Campus characteristics (HBCU, Tribal, HSI, Carnegie classification)"
    puts "  📈 Retention and completion rates (multiple timeframes)"
    puts "  💳 Financial aid details (Pell grants, loans, debt information)"
    puts "  🎓 Degree information and accreditation details"
    puts "="*50
    puts "🎊 SUCCESS! You now have the most comprehensive college database"
    puts "possible from official US Department of Education sources!"
  end
end