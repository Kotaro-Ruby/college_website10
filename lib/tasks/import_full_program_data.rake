namespace :college_data do
  desc "Import comprehensive program data from College Scorecard API"
  task import_full_program_data: :environment do
    require 'net/http'
    require 'json'
    require 'uri'

    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    
    if api_key.nil?
      puts "ERROR: COLLEGE_SCORECARD_API_KEY not found in environment variables"
      exit 1
    end

    # 英語専攻名から日本語への翻訳マップ
    def translate_program_title(title)
      translations = {
        # Biology
        'Biology, General.' => '生物学（一般）',
        'Biochemistry, Biophysics and Molecular Biology.' => '生化学・生物物理学・分子生物学',
        'Botany/Plant Biology.' => '植物学・植物生物学',
        'Cell/Cellular Biology and Anatomical Sciences.' => '細胞生物学・解剖学',
        'Microbiological Sciences and Immunology.' => '微生物学・免疫学',
        'Zoology/Animal Biology.' => '動物学・動物生物学',
        'Genetics.' => '遺伝学',
        'Physiology, Pathology and Related Sciences.' => '生理学・病理学・関連科学',
        'Pharmacology and Toxicology.' => '薬理学・毒性学',
        'Biomathematics, Bioinformatics, and Computational Biology.' => '生物数学・バイオインフォマティクス・計算生物学',
        'Biotechnology.' => 'バイオテクノロジー',
        'Ecology, Evolution, Systematics, and Population Biology.' => '生態学・進化学・系統学・個体群生物学',
        'Molecular Medicine.' => '分子医学',
        'Neurobiology and Neurosciences.' => '神経生物学・神経科学',
        'Biological and Biomedical Sciences, Other.' => '生物学・生物医学科学（その他）',

        # Engineering
        'Engineering, General.' => '工学（一般）',
        'Aerospace, Aeronautical and Astronautical Engineering.' => '航空宇宙工学',
        'Agricultural Engineering.' => '農業工学',
        'Architectural Engineering.' => '建築工学',
        'Biomedical/Medical Engineering.' => '生物医学工学・医用工学',
        'Chemical Engineering.' => '化学工学',
        'Civil Engineering.' => '土木工学',
        'Computer Engineering.' => 'コンピュータ工学',
        'Electrical, Electronics and Communications Engineering.' => '電気・電子・通信工学',
        'Engineering Physics.' => '工学物理学',
        'Engineering Science.' => '工学科学',
        'Environmental/Environmental Health Engineering.' => '環境工学・環境保健工学',
        'Materials Engineering' => '材料工学',
        'Mechanical Engineering.' => '機械工学',
        'Metallurgical Engineering.' => '冶金工学',
        'Mining and Mineral Engineering.' => '鉱業・鉱物工学',
        'Naval Architecture and Marine Engineering.' => '船舶建築学・海洋工学',
        'Petroleum Engineering.' => '石油工学',
        'Systems Engineering.' => 'システム工学',
        'Construction Engineering.' => '建設工学',
        'Industrial Engineering.' => '産業工学',
        'Manufacturing Engineering.' => '製造工学',
        'Polymer/Plastics Engineering.' => 'ポリマー・プラスチック工学',
        'Geological/Geophysical Engineering.' => '地質・地球物理工学',
        'Mechatronics, Robotics, and Automation Engineering.' => 'メカトロニクス・ロボティクス・自動化工学',
        'Biological/Biosystems Engineering.' => '生物工学・バイオシステム工学',
        'Energy Systems Engineering.' => 'エネルギーシステム工学',
        'Engineering, Other.' => '工学（その他）',

        # Computer Science
        'Computer and Information Sciences, General.' => 'コンピュータ・情報科学（一般）',
        'Computer Programming.' => 'コンピュータプログラミング',
        'Information Science/Studies.' => '情報科学・情報学',
        'Computer Systems Analysis.' => 'コンピュータシステム分析',
        'Computer Science.' => 'コンピュータサイエンス',
        'Computer Software and Media Applications.' => 'コンピュータソフトウェア・メディアアプリケーション',
        'Computer Systems Networking and Telecommunications.' => 'コンピュータシステムネットワーキング・通信',
        'Computer/Information Technology Administration and Management.' => 'コンピュータ・IT管理・マネジメント',
        'Computer and Information Sciences and Support Services, Other.' => 'コンピュータ・情報科学・サポートサービス（その他）'
      }
      
      translations[title] || title
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
    total_programs_imported = 0
    page = 0
    per_page = 20
    
    puts "詳細専攻プログラムデータの完全インポートを開始します..."
    
    loop do
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
          programs_count = 0
          
          programs_data.each do |program|
            cip_code = program['code']
            program_title = program['title']
            credential_level = program.dig('credential', 'level')
            credential_title = program.dig('credential', 'title')
            graduates_count = program.dig('counts', 'ipeds_awards1') || 0
            
            next unless cip_code && program_title
            
            # 既存のプログラムをチェック
            existing_program = DetailedProgram.find_by(
              condition: condition,
              cip_code: cip_code
            )
            
            unless existing_program
              major_category = DetailedProgram.determine_category_from_cip(cip_code)
              program_title_jp = translate_program_title(program_title)
              
              DetailedProgram.create!(
                condition: condition,
                cip_code: cip_code,
                program_title: program_title,
                program_title_jp: program_title_jp,
                credential_level: credential_level,
                credential_title: credential_title,
                graduates_count: graduates_count.to_i,
                major_category: major_category
              )
              
              programs_count += 1
              total_programs_imported += 1
            end
          end
          
          if programs_count > 0
            puts "  #{condition.college}: #{programs_count}プログラム追加"
            processed_schools += 1
          end
        end
      end
      
      imported_count += schools.length
      puts "  処理済み: #{imported_count}件のAPIレコード"
      
      # 進捗表示（10ページごと）
      if (page + 1) % 10 == 0
        puts "\n=== 中間統計 (#{page + 1}ページ処理済み) ==="
        puts "処理済み大学数: #{processed_schools}校"
        puts "インポート済みプログラム数: #{total_programs_imported}件"
        puts ""
      end
      
      # 次のページへ
      page += 1
      
      # APIの制限を避けるため、少し待機
      sleep(0.1)
      
      # データが少ない場合は終了
      break if schools.length < per_page
    end
    
    puts "\n詳細専攻プログラムデータの完全インポートが完了しました！"
    puts "合計処理レコード数: #{imported_count}"
    puts "処理済み大学数: #{processed_schools}校"
    puts "インポート済みプログラム数: #{total_programs_imported}件"
    
    # 最終統計情報を表示
    puts "\n=== 最終統計 ==="
    categories = DetailedProgram.group(:major_category).count
    categories.each do |category, count|
      puts "#{category}: #{count}プログラム"
    end
    
    # 学位レベル別統計
    puts "\n=== 学位レベル別統計 ==="
    levels = DetailedProgram.joins(:condition).group(:credential_level).count
    levels.each do |level, count|
      level_name = DetailedProgram::CREDENTIAL_LEVELS[level] || 'Unknown'
      puts "#{level_name}: #{count}プログラム"
    end
  end
end