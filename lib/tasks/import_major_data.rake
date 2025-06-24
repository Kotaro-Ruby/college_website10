namespace :college_data do
  desc "Import major data from College Scorecard API"
  task import_major_data: :environment do
    require 'net/http'
    require 'json'
    require 'uri'

    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    base_url = 'https://api.data.gov/ed/collegescorecard/v1/schools.json'
    
    if api_key.nil?
      puts "ERROR: COLLEGE_SCORECARD_API_KEY not found in environment variables"
      exit 1
    end

    # 人気の専攻分野のマッピング（College Scorecard APIのフィールド名）
    major_fields = {
      'business_marketing' => 'pcip_business',                # 経営学
      'engineering' => 'pcip_engineering',                    # 工学
      'computer' => 'pcip_computer_science',                  # コンピューターサイエンス
      'health' => 'pcip_health_professions',                  # 健康・医療
      'education' => 'pcip_education',                        # 教育学
      'biological' => 'pcip_biology',                         # 生物学
      'psychology' => 'pcip_psychology',                      # 心理学
      'social_science' => 'pcip_sociology'                    # 社会学・社会科学
    }

    def fetch_schools(api_key, page = 0, per_page = 100)
      uri = URI('https://api.data.gov/ed/collegescorecard/v1/schools.json')
      
      # 人気の専攻分野に絞ってリクエスト
      program_fields = [
        'latest.academics.program_percentage.business_marketing',
        'latest.academics.program_percentage.engineering',
        'latest.academics.program_percentage.computer',
        'latest.academics.program_percentage.health',
        'latest.academics.program_percentage.education',
        'latest.academics.program_percentage.biological',
        'latest.academics.program_percentage.psychology',
        'latest.academics.program_percentage.social_science'
      ].join(',')
      
      params = {
        'api_key' => api_key,
        '_page' => page,
        '_per_page' => per_page,
        '_fields' => "id,school.name,#{program_fields}",
        'school.operating' => '1'       # 運営中の学校のみ
      }
      
      uri.query = URI.encode_www_form(params)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      
      response = http.request(request)
      
      if response.code == '200'
        JSON.parse(response.body)
      else
        puts "API request failed with status: #{response.code}"
        puts "Response: #{response.body}"
        nil
      end
    end

    imported_count = 0
    updated_count = 0
    page = 0
    per_page = 100
    
    puts "専攻データのインポートを開始します..."
    
    loop do
      puts "ページ #{page + 1} を処理中..."
      
      data = fetch_schools(api_key, page, per_page)
      break unless data && data['results']
      
      schools = data['results']
      break if schools.empty?
      
      
      schools.each do |school|
        school_name = school['school.name']
        next unless school_name && school_name.strip.length > 0
        
        # データベース内の該当する大学を検索
        condition = Condition.find_by("LOWER(REPLACE(college, ' ', '')) = ?", 
                                     school_name.downcase.gsub(/\s+/, ''))
        
        if condition
          update_data = {}
          
          # 各専攻分野のデータを取得
          major_fields.each do |api_field, db_field|
            field_key = "latest.academics.program_percentage.#{api_field}"
            value = school[field_key]
            if value.is_a?(Numeric) && value >= 0 && value <= 1
              update_data[db_field] = value
            end
          end
          
          # データが存在する場合のみ更新
          if update_data.any?
            begin
              condition.update!(update_data)
              updated_count += 1
              
              # 進捗表示（10件ごと）
              if updated_count % 10 == 0
                puts "  更新済み: #{updated_count}件"
              end
            rescue => e
              puts "  エラー: #{condition.college} - #{e.message}"
            end
          end
        end
      end
      
      imported_count += schools.length
      puts "  処理済み: #{imported_count}件のAPIレコード"
      
      # 次のページへ
      page += 1
      
      # APIの制限を避けるため、少し待機
      sleep(0.1)
      
      # データが少ない場合は終了
      break if schools.length < per_page
      
      # テスト用制限を削除して全データを処理
      # break if page >= 4
    end
    
    puts "\n専攻データのインポートが完了しました！"
    puts "合計処理レコード数: #{imported_count}"
    puts "データベース更新件数: #{updated_count}"
    
    # 統計情報を表示
    puts "\n=== 専攻データ統計 ==="
    major_fields.each do |api_field, db_field|
      count = Condition.where.not(db_field => nil).count
      if count > 0
        japanese_name = case db_field
                       when 'pcip_agriculture' then '農業・農学'
                       when 'pcip_natural_resources' then '天然資源・環境科学'
                       when 'pcip_communication' then 'コミュニケーション学'
                       when 'pcip_computer_science' then 'コンピューターサイエンス'
                       when 'pcip_education' then '教育学'
                       when 'pcip_engineering' then '工学'
                       when 'pcip_foreign_languages' then '外国語・文学'
                       when 'pcip_english' then '英語・文学'
                       when 'pcip_biology' then '生物学'
                       when 'pcip_mathematics' then '数学・統計学'
                       when 'pcip_psychology' then '心理学'
                       when 'pcip_sociology' then '社会学'
                       when 'pcip_social_sciences' then '社会科学'
                       when 'pcip_visual_arts' then '視覚・舞台芸術'
                       when 'pcip_business' then '経営学'
                       when 'pcip_health_professions' then '健康・医療'
                       when 'pcip_history' then '歴史学'
                       when 'pcip_philosophy' then '哲学・宗教学'
                       when 'pcip_physical_sciences' then '物理科学'
                       when 'pcip_law' then '法学・刑事司法'
                       else db_field
                       end
        puts "#{japanese_name}: #{count}校"
      end
    end
  end
end