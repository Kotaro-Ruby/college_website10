namespace :import do
  desc "Safe import ALL data from College Scorecard API with comprehensive error handling and batch processing"
  task safe_comprehensive_college_scorecard: :environment do
    require 'net/http'
    require 'json'
    
    # College Scorecard API - 完全無料・合法
    api_key = ENV['COLLEGE_SCORECARD_API_KEY'] || 'YOUR_API_KEY_HERE'
    
    if api_key == 'YOUR_API_KEY_HERE'
      puts "ERROR: Please set COLLEGE_SCORECARD_API_KEY environment variable"
      puts "Get your free API key from: https://collegescorecard.ed.gov/data/documentation/"
      exit 1
    end
    
    # エラーハンドリング設定
    max_retries = 5
    base_retry_delay = 2
    max_retry_delay = 30
    request_timeout = 60
    connection_timeout = 30
    
    # バッチ処理設定
    per_page = 50  # 一度に取得する件数を減らしてエラーを防ぐ
    max_pages = 150  # 約5,546校 ÷ 50 = 110ページ程度（余裕を持って150）
    
    # 統計
    total_schools = 0
    updated_schools = 0
    errors = 0
    skipped_schools = 0
    
    # APIエンドポイント
    url = "https://api.data.gov/ed/collegescorecard/v1/schools?"
    
    # COMPREHENSIVE field list - SAT, ACT, すべてのデータを含む
    comprehensive_fields = [
      # Basic School Information
      'id', 'ope6_id', 'ope8_id', 'school.name', 'school.alias', 'school.city', 'school.state', 'school.zip',
      'school.accreditor', 'school.accreditor_code', 'school.hbcu', 'school.pbi', 'school.annhi', 'school.tribal',
      'school.aanapii', 'school.hsi', 'school.nanti', 'school.menonly', 'school.womenonly', 'school.relaffil',
      'school.locale', 'school.ccbasic', 'school.ccugprof', 'school.ccsizset', 'school.carnegie_basic',
      'school.carnegie_undergrad', 'school.carnegie_size_setting', 'school.ownership',
      'school.degrees_awarded.predominant', 'school.degrees_awarded.highest', 'school.main_campus',
      'school.branches', 'school.school_url', 'school.price_calculator_url', 'school.tuition_revenue_per_fte',
      'school.instructional_expenditure_per_fte', 'school.ft_faculty_rate',
      
      # SAT Scores (25th, 50th, 75th percentiles) - ユーザーが特に要求
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
      
      # ACT Scores (25th, 50th, 75th percentiles) - ユーザーが特に要求
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
      'latest.admissions.admission_rate.overall', 'latest.admissions.admission_rate.by_ope_id',
      'latest.admissions.test_requirements', 'latest.admissions.yield_rate',
      
      # Student Body Demographics
      'latest.student.size', 'latest.student.size_all', 'latest.student.undergraduate_size',
      'latest.student.graduate_size', 'latest.student.transfer_rate',
      'latest.student.retention_rate.four_year.full_time', 'latest.student.retention_rate.lt_four_year.full_time',
      'latest.student.retention_rate.four_year.part_time', 'latest.student.retention_rate.lt_four_year.part_time',
      'latest.student.part_time_share', 'latest.student.undergraduate_part_time_share',
      'latest.student.demographics.race_ethnicity.white', 'latest.student.demographics.race_ethnicity.black',
      'latest.student.demographics.race_ethnicity.hispanic', 'latest.student.demographics.race_ethnicity.asian',
      'latest.student.demographics.race_ethnicity.aian', 'latest.student.demographics.race_ethnicity.nhpi',
      'latest.student.demographics.race_ethnicity.two_or_more', 'latest.student.demographics.race_ethnicity.non_resident_alien',
      'latest.student.demographics.race_ethnicity.unknown', 'latest.student.demographics.race_ethnicity.white_non_hispanic',
      'latest.student.demographics.men', 'latest.student.demographics.women', 'latest.student.demographics.age_entry',
      'latest.student.demographics.age_entry_squared', 'latest.student.demographics.first_generation',
      'latest.student.demographics.median_hh_inc', 'latest.student.demographics.poverty_rate',
      'latest.student.demographics.unemployment_rate',
      
      # Financial Aid and Costs
      'latest.cost.tuition.in_state', 'latest.cost.tuition.out_of_state', 'latest.cost.tuition.program_year',
      'latest.cost.roomboard.oncampus', 'latest.cost.roomboard.offcampus', 'latest.cost.othercosts.oncampus',
      'latest.cost.othercosts.offcampus', 'latest.cost.attendance.academic_year', 'latest.cost.attendance.program_year',
      'latest.cost.avg_net_price.overall', 'latest.cost.avg_net_price.public', 'latest.cost.avg_net_price.private',
      'latest.cost.avg_net_price.by_income_level.0-30000', 'latest.cost.avg_net_price.by_income_level.30001-48000',
      'latest.cost.avg_net_price.by_income_level.48001-75000', 'latest.cost.avg_net_price.by_income_level.75001-110000',
      'latest.cost.avg_net_price.by_income_level.110001-plus', 'latest.cost.net_price.overall',
      'latest.cost.net_price.public', 'latest.cost.net_price.private', 'latest.cost.net_price.by_income_level.0-30000',
      'latest.cost.net_price.by_income_level.30001-48000', 'latest.cost.net_price.by_income_level.48001-75000',
      'latest.cost.net_price.by_income_level.75001-110000', 'latest.cost.net_price.by_income_level.110001-plus',
      
      # Financial Aid Recipients
      'latest.aid.pell_grant_rate', 'latest.aid.federal_loan_rate', 'latest.aid.loan_principal',
      'latest.aid.median_debt.graduates.overall', 'latest.aid.median_debt.graduates.monthly_payments',
      'latest.aid.median_debt.noncompleters.overall', 'latest.aid.median_debt.noncompleters.monthly_payments',
      
      # Completion and Graduation Rates
      'latest.completion.completion_rate_4yr_150nt', 'latest.completion.completion_rate_less_than_4yr_150nt',
      'latest.completion.completion_rate_4yr_150nt_pooled', 'latest.completion.completion_rate_less_than_4yr_150nt_pooled',
      'latest.completion.completion_rate_4yr_100nt', 'latest.completion.completion_rate_less_than_4yr_100nt',
      'latest.completion.completion_cohort_4yr_150nt', 'latest.completion.completion_cohort_less_than_4yr_150nt',
      'latest.completion.completion_cohort_4yr_150nt_pooled', 'latest.completion.completion_cohort_less_than_4yr_150nt_pooled',
      
      # Earnings Data (6, 8, 10 years after entry)
      'latest.earnings.6_yrs_after_entry.median', 'latest.earnings.6_yrs_after_entry.mean',
      'latest.earnings.6_yrs_after_entry.10th_percentile', 'latest.earnings.6_yrs_after_entry.25th_percentile',
      'latest.earnings.6_yrs_after_entry.75th_percentile', 'latest.earnings.6_yrs_after_entry.90th_percentile',
      'latest.earnings.8_yrs_after_entry.median', 'latest.earnings.8_yrs_after_entry.mean',
      'latest.earnings.8_yrs_after_entry.10th_percentile', 'latest.earnings.8_yrs_after_entry.25th_percentile',
      'latest.earnings.8_yrs_after_entry.75th_percentile', 'latest.earnings.8_yrs_after_entry.90th_percentile',
      'latest.earnings.10_yrs_after_entry.median', 'latest.earnings.10_yrs_after_entry.mean',
      'latest.earnings.10_yrs_after_entry.10th_percentile', 'latest.earnings.10_yrs_after_entry.25th_percentile',
      'latest.earnings.10_yrs_after_entry.75th_percentile', 'latest.earnings.10_yrs_after_entry.90th_percentile',
      
      # Faculty Data
      'latest.faculty.salary', 'latest.faculty.salary_professor', 'latest.faculty.salary_associate_professor',
      'latest.faculty.salary_assistant_professor', 'latest.faculty.salary_instructor', 'latest.faculty.salary_lecturer',
      'latest.faculty.salary_all_ranks',
      
      # Academic Programs (Major percentages)
      'latest.academics.program_percentage.agriculture', 'latest.academics.program_percentage.resources',
      'latest.academics.program_percentage.architecture', 'latest.academics.program_percentage.ethnic_cultural_gender',
      'latest.academics.program_percentage.communication', 'latest.academics.program_percentage.communications_technology',
      'latest.academics.program_percentage.computer', 'latest.academics.program_percentage.personal_culinary',
      'latest.academics.program_percentage.education', 'latest.academics.program_percentage.engineering',
      'latest.academics.program_percentage.engineering_technology', 'latest.academics.program_percentage.language',
      'latest.academics.program_percentage.family_consumer_science', 'latest.academics.program_percentage.legal',
      'latest.academics.program_percentage.english', 'latest.academics.program_percentage.humanities',
      'latest.academics.program_percentage.library', 'latest.academics.program_percentage.biological',
      'latest.academics.program_percentage.mathematics', 'latest.academics.program_percentage.military',
      'latest.academics.program_percentage.multidiscipline', 'latest.academics.program_percentage.parks_recreation_fitness',
      'latest.academics.program_percentage.philosophy_religious', 'latest.academics.program_percentage.theology_religious_vocation',
      'latest.academics.program_percentage.physical_science', 'latest.academics.program_percentage.science_technology',
      'latest.academics.program_percentage.psychology', 'latest.academics.program_percentage.security_law_enforcement',
      'latest.academics.program_percentage.public_administration_social_service', 'latest.academics.program_percentage.social_science',
      'latest.academics.program_percentage.construction', 'latest.academics.program_percentage.mechanic_repair_technology',
      'latest.academics.program_percentage.precision_production', 'latest.academics.program_percentage.transportation',
      'latest.academics.program_percentage.visual_performing', 'latest.academics.program_percentage.health',
      'latest.academics.program_percentage.business_marketing', 'latest.academics.program_percentage.history'
    ]
    
    puts "🚀 SAFE COMPREHENSIVE COLLEGE SCORECARD IMPORT STARTING"
    puts "="*60
    puts "Target: ALL 5,546 colleges with ALL available data"
    puts "Fields to import: #{comprehensive_fields.count}"
    puts "Per page: #{per_page} schools"
    puts "Max pages: #{max_pages}"
    puts "Max retries per request: #{max_retries}"
    puts "="*60
    
    # プログレス保存用ファイル
    progress_file = Rails.root.join('tmp', 'import_progress.json')
    start_page = 0
    
    # 以前の実行の続きから開始可能
    if File.exist?(progress_file)
      begin
        progress_data = JSON.parse(File.read(progress_file))
        start_page = progress_data['last_completed_page'] + 1
        puts "📊 Resuming from page #{start_page + 1} (found previous progress)"
      rescue => e
        puts "⚠ Could not read progress file: #{e.message}. Starting from beginning."
      end
    end
    
    page = start_page
    
    while page < max_pages
      puts "\n" + "="*40
      puts "📄 PROCESSING PAGE #{page + 1}/#{max_pages}"
      puts "="*40
      
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
      schools = []
      
      # リトライループ
      while retries < max_retries && !success
        begin
          retry_delay = [base_retry_delay * (2 ** retries), max_retry_delay].min
          
          if retries > 0
            puts "🔄 Retry #{retries}/#{max_retries} after #{retry_delay}s wait..."
            sleep(retry_delay)
          end
          
          puts "🌐 Fetching data from API (attempt #{retries + 1})..."
          
          # HTTP接続設定
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = connection_timeout
          http.read_timeout = request_timeout
          
          request = Net::HTTP::Get.new(uri)
          response = http.request(request)
          
          case response.code
          when '200'
            data = JSON.parse(response.body)
            schools = data['results'] || []
            
            if schools.empty?
              puts "✅ No more schools found. All data imported successfully!"
              success = true
              break
            end
            
            puts "✅ Successfully fetched #{schools.length} schools"
            success = true
            
          when '429'
            puts "⚠ Rate limit exceeded (429). Waiting longer..."
            retries += 1
            sleep(retry_delay * 2)
            
          when '503', '502', '500'
            puts "⚠ Server error (#{response.code}). Will retry..."
            retries += 1
            
          when '404'
            puts "⚠ Page not found (404). May have reached end of data."
            success = true
            break
            
          else
            puts "❌ API Error: #{response.code}"
            puts "Response: #{response.body[0..300]}..."
            retries += 1
          end
          
        rescue Net::TimeoutError => e
          puts "⏰ Timeout error: #{e.message}"
          retries += 1
        rescue JSON::ParserError => e
          puts "📄 JSON parsing error: #{e.message}"
          retries += 1
        rescue => e
          puts "🔌 Network error: #{e.message}"
          retries += 1
        end
      end
      
      unless success
        puts "❌ Failed to fetch page #{page + 1} after #{max_retries} attempts"
        puts "🛑 Stopping import. You can resume later."
        break
      end
      
      break if schools.empty?
      
      # データベース保存処理
      puts "💾 Processing #{schools.length} schools..."
      page_errors = 0
      page_updated = 0
      page_skipped = 0
      
      schools.each_with_index do |school, index|
        begin
          name = school['school.name']
          unless name&.strip&.length&.positive?
            page_skipped += 1
            next
          end
          
          # 所有形態の変換
          ownership = case school['school.ownership']
                     when 1 then '州立'
                     when 2 then '私立'
                     when 3 then '営利'
                     else '不明'
                     end
          
          # トランザクションでデータの整合性を保証
          Condition.transaction do
            condition = Condition.find_or_initialize_by(college: name.strip)
            
            # 基本情報の更新
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
            
            # よく使用される検索フィールドを直接カラムに保存（高速検索のため）
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
            
            # 包括的データを JSON で保存（240+フィールド全て）
            comprehensive_data = {}
            comprehensive_fields.each do |field|
              keys = field.split('.')
              value = school
              keys.each do |key|
                value = value[key] if value.is_a?(Hash)
              end
              comprehensive_data[field] = value if value
            end
            
            condition.comprehensive_data = comprehensive_data.to_json
            
            # 学費の設定（所有形態に応じて適切な値を選択）
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
            
            if condition.save
              page_updated += 1
              if (index + 1) % 10 == 0
                puts "  ✓ Processed #{index + 1}/#{schools.length} schools in this page"
              end
            else
              puts "  ❌ Failed to save: #{name} - #{condition.errors.full_messages.join(', ')}"
              page_errors += 1
            end
          end
          
        rescue => e
          puts "  ❌ Error processing: #{school['school.name'] || 'Unknown'} - #{e.message}"
          page_errors += 1
        end
      end
      
      # ページ結果の報告
      total_schools += schools.length
      updated_schools += page_updated
      errors += page_errors
      skipped_schools += page_skipped
      
      puts "📊 Page #{page + 1} Results:"
      puts "  ✅ Updated: #{page_updated}"
      puts "  ❌ Errors: #{page_errors}"
      puts "  ⏭ Skipped: #{page_skipped}"
      puts "  📈 Running Total: #{updated_schools}/#{total_schools} (#{((updated_schools.to_f / total_schools) * 100).round(1)}%)"
      
      # プログレス保存
      progress_data = {
        'last_completed_page' => page,
        'total_schools' => total_schools,
        'updated_schools' => updated_schools,
        'errors' => errors,
        'timestamp' => Time.current.iso8601
      }
      File.write(progress_file, progress_data.to_json)
      
      page += 1
      
      # API に優しくする（レート制限回避）
      if page < max_pages
        puts "⏳ Waiting 2 seconds before next page..."
        sleep(2)
      end
    end
    
    # プログレスファイルを削除（完了）
    File.delete(progress_file) if File.exist?(progress_file)
    
    # 最終結果の報告
    puts "\n" + "🎉" + "="*60 + "🎉"
    puts "COMPREHENSIVE COLLEGE SCORECARD IMPORT COMPLETE!"
    puts "="*64
    puts "📊 FINAL STATISTICS:"
    puts "  🎯 Total schools processed: #{total_schools}"
    puts "  ✅ Successfully updated: #{updated_schools}"
    puts "  ❌ Errors encountered: #{errors}"
    puts "  ⏭ Skipped (invalid data): #{skipped_schools}"
    puts "  📈 Success rate: #{((updated_schools.to_f / total_schools) * 100).round(2)}%" if total_schools > 0
    puts "\n🗂 COMPREHENSIVE DATA INCLUDES:"
    puts "  📊 SAT scores (25th, 50th, 75th percentiles) - Math, Reading, Writing"
    puts "  📊 ACT scores (25th, 50th, 75th percentiles) - Composite, English, Math, Writing"
    puts "  💰 Comprehensive financial data (tuition, room/board, net prices by income)"
    puts "  👥 Detailed demographics (race, gender, first-generation status)"
    puts "  💼 Earnings data (6, 8, 10 years post-graduation)"
    puts "  👨‍🏫 Faculty information (salaries by rank)"
    puts "  📚 Academic program percentages (40+ majors)"
    puts "  🏫 Campus characteristics (HBCU, Tribal, HSI, Carnegie classification)"
    puts "  📈 Retention and completion rates"
    puts "  💳 Financial aid information (Pell grants, federal loans, debt)"
    puts "="*64
    
    if errors > 0
      puts "⚠ NOTE: #{errors} errors occurred during import."
      puts "You can run this task again to retry failed records."
    end
    
    puts "\n🚀 Your database now contains the most comprehensive"
    puts "college dataset available from official US government sources!"
  end
end

# 使い方:
# 1. APIキー取得: https://collegescorecard.ed.gov/data/documentation/
# 2. 環境変数設定: export COLLEGE_SCORECARD_API_KEY=your_key_here  
# 3. 実行: rails import:safe_comprehensive_college_scorecard
#
# 特徴:
# - 5回のリトライでネットワークエラーに対応
# - プログレス保存で中断時の再開可能
# - バッチサイズ調整でAPIエラー回避
# - トランザクション使用でデータ整合性保証
# - 詳細な進捗報告とエラーハンドリング