namespace :college_data do
  desc "Import missing major fields from College Scorecard API"
  task import_missing_majors: :environment do
    require 'net/http'
    require 'json'
    require 'uri'

    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    
    if api_key.nil?
      puts "ERROR: COLLEGE_SCORECARD_API_KEY not found in environment variables"
      exit 1
    end

    # 不足している専攻分野のマッピング（正しいPCIPコード使用）
    missing_major_fields = {
      'PCIP03' => 'pcip_natural_resources',           # 天然資源・環境科学
      'PCIP09' => 'pcip_communication',               # コミュニケーション学  
      'PCIP16' => 'pcip_foreign_languages',           # 外国語・文学
      'PCIP40' => 'pcip_physical_sciences'            # 物理科学
    }

    def fetch_schools_missing(api_key, page = 0, per_page = 100)
      uri = URI('https://api.data.gov/ed/collegescorecard/v1/schools.json')
      
      # 不足している専攻分野をリクエスト（正しいPCIPコード使用）
      program_fields = [
        'latest.academics.program_percentage.PCIP03',
        'latest.academics.program_percentage.PCIP09',
        'latest.academics.program_percentage.PCIP16',
        'latest.academics.program_percentage.PCIP40'
      ].join(',')
      
      params = {
        'api_key' => api_key,
        '_page' => page,
        '_per_page' => per_page,
        '_fields' => "id,school.name,#{program_fields}",
        'school.operating' => '1'
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
    
    puts "不足している専攻データのインポートを開始します..."
    
    loop do
      puts "ページ #{page + 1} を処理中..."
      
      data = fetch_schools_missing(api_key, page, per_page)
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
          
          # 各不足専攻分野のデータを取得
          missing_major_fields.each do |pcip_code, db_field|
            field_key = "latest.academics.program_percentage.#{pcip_code}"
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
    end
    
    puts "\n不足専攻データのインポートが完了しました！"
    puts "合計処理レコード数: #{imported_count}"
    puts "データベース更新件数: #{updated_count}"
    
    # 統計情報を表示
    puts "\n=== 最終専攻データ統計 ==="
    all_major_fields = {
      'pcip_agriculture' => '農業・農学',
      'pcip_natural_resources' => '天然資源・環境科学',
      'pcip_communication' => 'コミュニケーション学',
      'pcip_computer_science' => 'コンピューターサイエンス',
      'pcip_education' => '教育学',
      'pcip_engineering' => '工学',
      'pcip_foreign_languages' => '外国語・文学',
      'pcip_english' => '英語・文学',
      'pcip_biology' => '生物学',
      'pcip_mathematics' => '数学・統計学',
      'pcip_psychology' => '心理学',
      'pcip_sociology' => '社会学',
      'pcip_social_sciences' => '社会科学',
      'pcip_visual_arts' => '視覚・舞台芸術',
      'pcip_business' => '経営学',
      'pcip_health_professions' => '健康・医療',
      'pcip_history' => '歴史学',
      'pcip_philosophy' => '哲学・宗教学',
      'pcip_physical_sciences' => '物理科学',
      'pcip_law' => '法学・刑事司法'
    }
    
    total_schools = Condition.count
    all_major_fields.each do |db_field, japanese_name|
      count = Condition.where.not(db_field => nil).count
      percentage = total_schools > 0 ? (count.to_f / total_schools * 100).round(1) : 0
      puts "#{japanese_name}: #{count}校 (#{percentage}%)"
    end
  end
end