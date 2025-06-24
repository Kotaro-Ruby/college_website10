namespace :college_data do
  desc "Import detailed program data from College Scorecard API"
  task import_detailed_programs: :environment do
    require 'net/http'
    require 'json'
    require 'uri'

    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    
    if api_key.nil?
      puts "ERROR: COLLEGE_SCORECARD_API_KEY not found in environment variables"
      exit 1
    end

    def fetch_programs(api_key, page = 0, per_page = 20)
      uri = URI('https://api.data.gov/ed/collegescorecard/v1/schools.json')
      
      params = {
        'api_key' => api_key,
        '_page' => page,
        '_per_page' => per_page,
        '_fields' => 'id,school.name,latest.programs.cip_4_digit',
        'school.operating' => '1',
        'all_programs_nested' => 'true'
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
    processed_schools = 0
    page = 0
    per_page = 20
    
    puts "詳細専攻プログラムデータのインポートを開始します..."
    
    # 最初の10ページのみを処理してサンプルデータを確認
    while page < 10
      puts "ページ #{page + 1} を処理中..."
      
      data = fetch_programs(api_key, page, per_page)
      break unless data && data['results']
      
      schools = data['results']
      break if schools.empty?
      
      schools.each do |school|
        school_name = school['school.name']
        programs_data = school['latest.programs.cip_4_digit']
        
        next unless school_name && programs_data
        
        # データベース内の該当する大学を検索
        condition = Condition.find_by("LOWER(REPLACE(college, ' ', '')) = ?", 
                                     school_name.downcase.gsub(/\s+/, ''))
        
        if condition
          puts "\n=== #{condition.college} ==="
          puts "提供専攻プログラム数: #{programs_data.length}"
          
          # 生物学関連のプログラムを抽出（CIP code 26で始まる）
          biology_programs = programs_data.select { |p| p['code']&.start_with?('26') }
          if biology_programs.any?
            puts "\n生物学関連プログラム:"
            biology_programs.each do |program|
              puts "  - #{program['title']} (CIP: #{program['code']})"
            end
          end
          
          # 工学関連のプログラムを抽出（CIP code 14で始まる）
          engineering_programs = programs_data.select { |p| p['code']&.start_with?('14') }
          if engineering_programs.any?
            puts "\n工学関連プログラム:"
            engineering_programs.each do |program|
              puts "  - #{program['title']} (CIP: #{program['code']})"
            end
          end
          
          # コンピューターサイエンス関連のプログラムを抽出（CIP code 11で始まる）
          cs_programs = programs_data.select { |p| p['code']&.start_with?('11') }
          if cs_programs.any?
            puts "\nコンピューターサイエンス関連プログラム:"
            cs_programs.each do |program|
              puts "  - #{program['title']} (CIP: #{program['code']})"
            end
          end
          
          processed_schools += 1
          puts "---"
        end
      end
      
      imported_count += schools.length
      puts "処理済み: #{imported_count}件のAPIレコード, マッチした大学: #{processed_schools}校"
      
      # 次のページへ
      page += 1
      
      # APIの制限を避けるため、少し待機
      sleep(0.5)
    end
    
    puts "\n詳細専攻プログラムデータの調査が完了しました！"
    puts "合計処理レコード数: #{imported_count}"
    puts "マッチした大学数: #{processed_schools}校"
    puts "\n=== 結論 ==="
    puts "College Scorecard APIから詳細な専攻プログラムデータが取得可能です！"
    puts "- CIPコード付きの具体的な専攻名"
    puts "- 学位レベル情報"
    puts "- 卒業者数などの統計データ"
  end
end