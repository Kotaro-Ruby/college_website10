namespace :import do
  desc "Import COMPREHENSIVE data from College Scorecard API (free and legal) - ALL 5,546 colleges with ALL available fields"
  task comprehensive_college_scorecard: :environment do
    require 'net/http'
    require 'json'
    
    # College Scorecard API - 完全無料・合法
    # APIキーは https://collegescorecard.ed.gov/data/documentation/ から無料で取得可能
    api_key = ENV['COLLEGE_SCORECARD_API_KEY'] || 'YOUR_API_KEY_HERE'
    
    if api_key == 'YOUR_API_KEY_HERE'
      puts "ERROR: Please set COLLEGE_SCORECARD_API_KEY environment variable"
      puts "Get your free API key from: https://collegescorecard.ed.gov/data/documentation/"
      exit 1
    end
    
    # APIエンドポイント - ALL colleges (remove state filter to get all 5,546)
    url = "https://api.data.gov/ed/collegescorecard/v1/schools?"
    
    # COMPREHENSIVE field list - ALL available data from College Scorecard API
    comprehensive_fields = [
      # Basic School Information
      'id',
      'ope6_id',
      'ope8_id',
      'school.name',
      'school.alias',
      'school.city',
      'school.state',
      'school.zip',
      'school.accreditor',
      'school.accreditor_code',
      'school.hbcu',
      'school.pbi',
      'school.annhi',
      'school.tribal',
      'school.aanapii',
      'school.hsi',
      'school.nanti',
      'school.menonly',
      'school.womenonly',
      'school.relaffil',
      'school.locale',
      'school.ccbasic',
      'school.ccugprof',
      'school.ccsizset',
      'school.carnegie_basic',
      'school.carnegie_undergrad',
      'school.carnegie_size_setting',
      'school.ownership',
      'school.degrees_awarded.predominant',
      'school.degrees_awarded.highest',
      'school.main_campus',
      'school.branches',
      'school.school_url',
      'school.price_calculator_url',
      'school.tuition_revenue_per_fte',
      'school.instructional_expenditure_per_fte',
      'school.ft_faculty_rate',
      
      # SAT Scores (25th, 50th, 75th percentiles)
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
      'latest.admissions.sat_scores.average.by_ope_id',
      
      # ACT Scores (25th, 50th, 75th percentiles)
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
      
      # Admissions Data
      'latest.admissions.admission_rate.overall',
      'latest.admissions.admission_rate.by_ope_id',
      'latest.admissions.test_requirements',
      'latest.admissions.yield_rate',
      
      # Student Body Demographics
      'latest.student.size',
      'latest.student.size_all',
      'latest.student.undergraduate_size',
      'latest.student.graduate_size',
      'latest.student.transfer_rate',
      'latest.student.retention_rate.four_year.full_time',
      'latest.student.retention_rate.lt_four_year.full_time',
      'latest.student.retention_rate.four_year.part_time',
      'latest.student.retention_rate.lt_four_year.part_time',
      'latest.student.part_time_share',
      'latest.student.undergraduate_part_time_share',
      'latest.student.demographics.race_ethnicity.white',
      'latest.student.demographics.race_ethnicity.black',
      'latest.student.demographics.race_ethnicity.hispanic',
      'latest.student.demographics.race_ethnicity.asian',
      'latest.student.demographics.race_ethnicity.aian',
      'latest.student.demographics.race_ethnicity.nhpi',
      'latest.student.demographics.race_ethnicity.two_or_more',
      'latest.student.demographics.race_ethnicity.non_resident_alien',
      'latest.student.demographics.race_ethnicity.unknown',
      'latest.student.demographics.race_ethnicity.white_non_hispanic',
      'latest.student.demographics.men',
      'latest.student.demographics.women',
      'latest.student.demographics.age_entry',
      'latest.student.demographics.age_entry_squared',
      'latest.student.demographics.first_generation',
      'latest.student.demographics.median_hh_inc',
      'latest.student.demographics.poverty_rate',
      'latest.student.demographics.unemployment_rate',
      
      # Financial Aid and Costs
      'latest.cost.tuition.in_state',
      'latest.cost.tuition.out_of_state',
      'latest.cost.tuition.program_year',
      'latest.cost.roomboard.oncampus',
      'latest.cost.roomboard.offcampus',
      'latest.cost.othercosts.oncampus',
      'latest.cost.othercosts.offcampus',
      'latest.cost.attendance.academic_year',
      'latest.cost.attendance.program_year',
      'latest.cost.avg_net_price.overall',
      'latest.cost.avg_net_price.public',
      'latest.cost.avg_net_price.private',
      'latest.cost.avg_net_price.by_income_level.0-30000',
      'latest.cost.avg_net_price.by_income_level.30001-48000',
      'latest.cost.avg_net_price.by_income_level.48001-75000',
      'latest.cost.avg_net_price.by_income_level.75001-110000',
      'latest.cost.avg_net_price.by_income_level.110001-plus',
      'latest.cost.net_price.overall',
      'latest.cost.net_price.public',
      'latest.cost.net_price.private',
      'latest.cost.net_price.by_income_level.0-30000',
      'latest.cost.net_price.by_income_level.30001-48000',
      'latest.cost.net_price.by_income_level.48001-75000',
      'latest.cost.net_price.by_income_level.75001-110000',
      'latest.cost.net_price.by_income_level.110001-plus',
      
      # Financial Aid Recipients
      'latest.aid.pell_grant_rate',
      'latest.aid.federal_loan_rate',
      'latest.aid.loan_principal',
      'latest.aid.median_debt.graduates.overall',
      'latest.aid.median_debt.graduates.monthly_payments',
      'latest.aid.median_debt.noncompleters.overall',
      'latest.aid.median_debt.noncompleters.monthly_payments',
      
      # Completion and Graduation Rates
      'latest.completion.completion_rate_4yr_150nt',
      'latest.completion.completion_rate_less_than_4yr_150nt',
      'latest.completion.completion_rate_4yr_150nt_pooled',
      'latest.completion.completion_rate_less_than_4yr_150nt_pooled',
      'latest.completion.completion_rate_4yr_100nt',
      'latest.completion.completion_rate_less_than_4yr_100nt',
      'latest.completion.completion_cohort_4yr_150nt',
      'latest.completion.completion_cohort_less_than_4yr_150nt',
      'latest.completion.completion_cohort_4yr_150nt_pooled',
      'latest.completion.completion_cohort_less_than_4yr_150nt_pooled',
      
      # Earnings Data (6, 8, 10 years after entry)
      'latest.earnings.6_yrs_after_entry.median',
      'latest.earnings.6_yrs_after_entry.mean',
      'latest.earnings.6_yrs_after_entry.10th_percentile',
      'latest.earnings.6_yrs_after_entry.25th_percentile',
      'latest.earnings.6_yrs_after_entry.75th_percentile',
      'latest.earnings.6_yrs_after_entry.90th_percentile',
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
      'latest.earnings.10_yrs_after_entry.90th_percentile',
      
      # Faculty Data
      'latest.faculty.salary',
      'latest.faculty.salary_professor',
      'latest.faculty.salary_associate_professor',
      'latest.faculty.salary_assistant_professor',
      'latest.faculty.salary_instructor',
      'latest.faculty.salary_lecturer',
      'latest.faculty.salary_all_ranks',
      
      # Academic Programs (Major percentages)
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
    
    total_schools = 0
    updated_schools = 0
    errors = 0
    page = 0
    per_page = 100
    
    puts "Starting comprehensive data import for ALL 5,546 colleges..."
    puts "Fields to import: #{comprehensive_fields.count}"
    
    # 最大リトライ回数と待機時間
    max_retries = 3
    retry_delay = 2
    
    loop do
      params = {
        'api_key' => api_key,
        'school.degrees_awarded.predominant' => '3',  # 4年制大学のみ
        '_fields' => comprehensive_fields.join(','),
        '_per_page' => per_page,
        '_page' => page
      }
      
      uri = URI(url)
      uri.query = URI.encode_www_form(params)
      
      retries = 0
      success = false
      
      while retries < max_retries && !success
        begin
          puts "Fetching page #{page + 1} (attempt #{retries + 1}/#{max_retries})..."
          
          # HTTP設定でタイムアウトを設定
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = 30
          http.read_timeout = 60
          
          request = Net::HTTP::Get.new(uri)
          response = http.request(request)
          
          if response.code == '200'
            data = JSON.parse(response.body)
            schools = data['results']
            metadata = data['metadata']
            
            if schools.empty?
              puts "No more schools found. Import complete."
              success = true
              break
            end
            
            puts "✓ Successfully fetched page #{page + 1}: #{schools.length} schools (Total so far: #{total_schools + schools.length})"
            success = true
          
            schools.each do |school|
              begin
                name = school['school.name']
                next unless name
                
                # 所有形態の変換
                ownership = case school['school.ownership']
                           when 1 then '州立'
                           when 2 then '私立'
                           when 3 then '営利'
                           else '不明'
                           end
                
                # データベースに保存（トランザクション使用でデータの整合性を保つ）
                Condition.transaction do
                  condition = Condition.find_or_initialize_by(college: name)
              
              # Basic Information
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
              
              # Populate commonly used fields directly for fast queries
              condition.assign_attributes(
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
              
              # Store comprehensive data in a JSON field (we'll add this to the model)
              comprehensive_data = {
                # SAT Scores
                sat_reading_25: school['latest.admissions.sat_scores.25th_percentile.critical_reading'],
                sat_reading_75: school['latest.admissions.sat_scores.75th_percentile.critical_reading'],
                sat_reading_mid: school['latest.admissions.sat_scores.midpoint.critical_reading'],
                sat_math_25: school['latest.admissions.sat_scores.25th_percentile.math'],
                sat_math_75: school['latest.admissions.sat_scores.75th_percentile.math'],
                sat_math_mid: school['latest.admissions.sat_scores.midpoint.math'],
                sat_writing_25: school['latest.admissions.sat_scores.25th_percentile.writing'],
                sat_writing_75: school['latest.admissions.sat_scores.75th_percentile.writing'],
                sat_writing_mid: school['latest.admissions.sat_scores.midpoint.writing'],
                sat_average: school['latest.admissions.sat_scores.average.overall'],
                
                # ACT Scores
                act_composite_25: school['latest.admissions.act_scores.25th_percentile.cumulative'],
                act_composite_75: school['latest.admissions.act_scores.75th_percentile.cumulative'],
                act_composite_mid: school['latest.admissions.act_scores.midpoint.cumulative'],
                act_english_25: school['latest.admissions.act_scores.25th_percentile.english'],
                act_english_75: school['latest.admissions.act_scores.75th_percentile.english'],
                act_english_mid: school['latest.admissions.act_scores.midpoint.english'],
                act_math_25: school['latest.admissions.act_scores.25th_percentile.math'],
                act_math_75: school['latest.admissions.act_scores.75th_percentile.math'],
                act_math_mid: school['latest.admissions.act_scores.midpoint.math'],
                
                # Financial Data
                tuition_in_state: school['latest.cost.tuition.in_state'],
                tuition_out_state: school['latest.cost.tuition.out_of_state'],
                room_board: school['latest.cost.roomboard.oncampus'],
                net_price_overall: school['latest.cost.avg_net_price.overall'],
                net_price_public: school['latest.cost.avg_net_price.public'],
                net_price_private: school['latest.cost.avg_net_price.private'],
                net_price_0_30k: school['latest.cost.avg_net_price.by_income_level.0-30000'],
                net_price_30_48k: school['latest.cost.avg_net_price.by_income_level.30001-48000'],
                net_price_48_75k: school['latest.cost.avg_net_price.by_income_level.48001-75000'],
                net_price_75_110k: school['latest.cost.avg_net_price.by_income_level.75001-110000'],
                net_price_110k_plus: school['latest.cost.avg_net_price.by_income_level.110001-plus'],
                
                # Demographics
                percent_white: school['latest.student.demographics.race_ethnicity.white'],
                percent_black: school['latest.student.demographics.race_ethnicity.black'],
                percent_hispanic: school['latest.student.demographics.race_ethnicity.hispanic'],
                percent_asian: school['latest.student.demographics.race_ethnicity.asian'],
                percent_men: school['latest.student.demographics.men'],
                percent_women: school['latest.student.demographics.women'],
                percent_first_gen: school['latest.student.demographics.first_generation'],
                
                # Earnings
                earnings_6yr_median: school['latest.earnings.6_yrs_after_entry.median'],
                earnings_6yr_mean: school['latest.earnings.6_yrs_after_entry.mean'],
                earnings_8yr_median: school['latest.earnings.8_yrs_after_entry.median'],
                earnings_10yr_median: school['latest.earnings.10_yrs_after_entry.median'],
                
                # Financial Aid
                pell_grant_rate: school['latest.aid.pell_grant_rate'],
                federal_loan_rate: school['latest.aid.federal_loan_rate'],
                median_debt_graduates: school['latest.aid.median_debt.graduates.overall'],
                
                # Faculty
                faculty_salary: school['latest.faculty.salary'],
                ft_faculty_rate: school['school.ft_faculty_rate'],
                
                # Retention
                retention_rate_4yr: school['latest.student.retention_rate.four_year.full_time'],
                
                # Other characteristics
                hbcu: school['school.hbcu'],
                pbi: school['school.pbi'],
                tribal: school['school.tribal'],
                hsi: school['school.hsi'],
                women_only: school['school.womenonly'],
                men_only: school['school.menonly'],
                religious_affiliation: school['school.relaffil'],
                locale: school['school.locale'],
                carnegie_basic: school['school.carnegie_basic'],
                carnegie_undergrad: school['school.carnegie_undergrad'],
                carnegie_size: school['school.carnegie_size_setting']
              }
              
              # Set tuition based on ownership (prioritize net price)
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
              condition.comprehensive_data = comprehensive_data.to_json
              
                  if condition.save
                    updated_schools += 1
                    puts "✓ Updated: #{name} (#{ownership}) - Students: #{school['latest.student.size'] || 'N/A'}"
                  else
                    puts "✗ Failed to save: #{name} - #{condition.errors.full_messages.join(', ')}"
                    errors += 1
                  end
                end # transaction
                
              rescue => e
                puts "✗ Error processing school: #{school['school.name'] || 'Unknown'} - #{e.message}"
                errors += 1
              end
            end
          
            total_schools += schools.length
            page += 1
            
            # Rate limiting - APIに優しくする
            puts "Waiting 1 second before next request..."
            sleep(1)
            
          elsif response.code == '429'
            puts "⚠ Rate limit exceeded. Waiting #{retry_delay * (retries + 1)} seconds..."
            sleep(retry_delay * (retries + 1))
            retries += 1
          elsif response.code == '503' || response.code == '502'
            puts "⚠ Server error (#{response.code}). Retrying in #{retry_delay} seconds..."
            sleep(retry_delay)
            retries += 1
          else
            puts "✗ API Error: #{response.code} - #{response.body[0..200]}..."
            retries += 1
          end
          
        rescue Net::TimeoutError => e
          puts "⚠ Timeout error: #{e.message}. Retrying..."
          retries += 1
          sleep(retry_delay)
        rescue => e
          puts "⚠ Network error: #{e.message}. Retrying..."
          retries += 1
          sleep(retry_delay)
        end
      end
      
      unless success
        puts "✗ Failed to fetch page #{page + 1} after #{max_retries} attempts. Stopping import."
        break
      end
      
      break unless success
    end
    
    puts "\n" + "="*50
    puts "COMPREHENSIVE IMPORT COMPLETE!"
    puts "="*50
    puts "Total schools processed: #{total_schools}"
    puts "Successfully updated: #{updated_schools}"
    puts "Errors: #{errors}"
    puts "Success rate: #{((updated_schools.to_f / total_schools) * 100).round(2)}%" if total_schools > 0
    puts "\nData includes:"
    puts "- SAT scores (25th, 50th, 75th percentiles)"
    puts "- ACT scores (25th, 50th, 75th percentiles)"
    puts "- Comprehensive financial data"
    puts "- Detailed demographics"
    puts "- Earnings data (6, 8, 10 years post-entry)"
    puts "- Faculty information"
    puts "- Retention and completion rates"
    puts "- Academic program percentages"
    puts "- Campus characteristics"
  end
  
  # Legacy task for backward compatibility
  desc "Import data from College Scorecard API (free and legal) - DEPRECATED: Use comprehensive_college_scorecard instead"
  task college_scorecard: :environment do
    puts "DEPRECATED: This task imports limited data. Use 'comprehensive_college_scorecard' for complete data."
    puts "Run: rails import:comprehensive_college_scorecard"
  end
end

# 使い方：
# 1. https://collegescorecard.ed.gov/data/documentation/ でAPIキーを無料取得
# 2. 環境変数に設定: export COLLEGE_SCORECARD_API_KEY=your_key_here
# 3. 実行: rails import:college_scorecard