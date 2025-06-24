namespace :import do
  desc "Import fresh college data from College Scorecard with tuition, comments, and major data"
  task fresh_colleges: :environment do
    require 'net/http'
    require 'json'
    require 'dotenv/load'
    require_relative '../college_comment_generator'
    require_relative '../college_major_importer'
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    
    unless api_key
      puts "エラー: COLLEGE_SCORECARD_API_KEYが設定されていません"
      return
    end
    
    # 全米50州のリスト（人口順）
    states = ['CA', 'TX', 'FL', 'NY', 'PA', 'IL', 'OH', 'GA', 'NC', 'MI', 
              'NJ', 'VA', 'WA', 'AZ', 'MA', 'TN', 'IN', 'MO', 'MD', 'WI', 
              'CO', 'MN', 'SC', 'AL', 'LA', 'KY', 'OR', 'OK', 'CT', 'UT',
              'IA', 'NV', 'AR', 'MS', 'KS', 'NM', 'NE', 'ID', 'WV', 'HI',
              'NH', 'ME', 'RI', 'MT', 'DE', 'SD', 'ND', 'AK', 'VT', 'WY']
    
    base_url = "https://api.data.gov/ed/collegescorecard/v1/schools"
    total_added = 0
    
    states.each do |state|
      puts "\n#{state}州の大学を取得中..."
      
      params = {
        'api_key' => api_key,
        'school.state' => state,
        'school.degrees_awarded.predominant' => '3',  # 4年制大学
        '_fields' => [
          'school.name',
          'school.city',
          'school.state',
          'school.zip',
          'school.school_url',
          'school.ownership',
          'latest.student.size',
          'latest.cost.avg_net_price.public',
          'latest.cost.avg_net_price.private',
          'latest.cost.avg_net_price.overall',
          'latest.cost.tuition.out_of_state',
          'latest.cost.tuition.in_state',
          'latest.completion.completion_rate_4yr_150nt',
          'latest.admissions.admission_rate.overall',
          'latest.admissions.sat_scores.average.overall'
        ].join(','),
        '_per_page' => 50,
        '_sort' => 'latest.student.size:desc'  # 学生数が多い順
      }
      
      uri = URI(base_url)
      uri.query = URI.encode_www_form(params)
      
      response = Net::HTTP.get_response(uri)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        schools = data['results']
        
        schools.each do |school|
          name = school['school.name']
          ownership_code = school['school.ownership']
          
          # 所有形態の判定
          ownership = case ownership_code
                     when 1 then '州立'
                     when 2 then '私立'
                     when 3 then '営利'
                     else '不明'
                     end
          
          # Net Priceの決定
          is_public = ownership_code == 1
          net_price = if is_public
                        school['latest.cost.tuition.out_of_state'] ||
                        school['latest.cost.avg_net_price.public'] ||
                        school['latest.cost.avg_net_price.overall']
                      else
                        school['latest.cost.avg_net_price.private'] ||
                        school['latest.cost.avg_net_price.overall'] ||
                        school['latest.cost.tuition.in_state']
                      end
          
          # 州名を日本語形式に変換
          state_jp = case state
                     when 'CA' then 'カリフォルニア州'
                     when 'TX' then 'テキサス州'
                     when 'FL' then 'フロリダ州'
                     when 'NY' then 'ニューヨーク州'
                     when 'PA' then 'ペンシルベニア州'
                     when 'IL' then 'イリノイ州'
                     when 'OH' then 'オハイオ州'
                     when 'GA' then 'ジョージア州'
                     when 'NC' then 'ノースカロライナ州'
                     when 'MI' then 'ミシガン州'
                     when 'NJ' then 'ニュージャージー州'
                     when 'VA' then 'バージニア州'
                     when 'WA' then 'ワシントン州'
                     when 'AZ' then 'アリゾナ州'
                     when 'MA' then 'マサチューセッツ州'
                     when 'TN' then 'テネシー州'
                     when 'IN' then 'インディアナ州'
                     when 'MO' then 'ミズーリ州'
                     when 'MD' then 'メリーランド州'
                     when 'WI' then 'ウィスコンシン州'
                     when 'CO' then 'コロラド州'
                     when 'MN' then 'ミネソタ州'
                     when 'SC' then 'サウスカロライナ州'
                     when 'AL' then 'アラバマ州'
                     when 'LA' then 'ルイジアナ州'
                     when 'KY' then 'ケンタッキー州'
                     when 'OR' then 'オレゴン州'
                     when 'OK' then 'オクラホマ州'
                     when 'CT' then 'コネチカット州'
                     when 'UT' then 'ユタ州'
                     when 'IA' then 'アイオワ州'
                     when 'NV' then 'ネバダ州'
                     when 'AR' then 'アーカンソー州'
                     when 'MS' then 'ミシシッピ州'
                     when 'KS' then 'カンザス州'
                     when 'NM' then 'ニューメキシコ州'
                     when 'NE' then 'ネブラスカ州'
                     when 'ID' then 'アイダホ州'
                     when 'WV' then 'ウェストバージニア州'
                     when 'HI' then 'ハワイ州'
                     when 'NH' then 'ニューハンプシャー州'
                     when 'ME' then 'メイン州'
                     when 'RI' then 'ロードアイランド州'
                     when 'MT' then 'モンタナ州'
                     when 'DE' then 'デラウェア州'
                     when 'SD' then 'サウスダコタ州'
                     when 'ND' then 'ノースダコタ州'
                     when 'AK' then 'アラスカ州'
                     when 'VT' then 'バーモント州'
                     when 'WY' then 'ワイオミング州'
                     else "#{state}州"
                     end
          
          # データベースに保存または更新
          condition = Condition.find_or_initialize_by(college: name)
          
          if condition.new_record? || condition.tuition.nil? || condition.tuition == 0
            # 基本データの更新
            college_data = {
              state: state_jp,
              city: school['school.city'],
              zip: school['school.zip'],
              privateorpublic: ownership,
              students: school['latest.student.size'],
              tuition: net_price,
              graduation_rate: school['latest.completion.completion_rate_4yr_150nt'],
              acceptance_rate: school['latest.admissions.admission_rate.overall']
            }
            
            # コメントがない場合は生成
            if condition.comment.blank?
              comment_data = {
                students: school['latest.student.size'],
                acceptance_rate: school['latest.admissions.admission_rate.overall'],
                ownership: ownership
              }
              college_data[:comment] = CollegeCommentGenerator.generate_comment_for_college(name, comment_data)
            end
            
            condition.update(college_data)
            
            # 専攻データの取得と更新（非同期的に実行）
            if condition.pcip_business.nil? || condition.pcip_business == 0
              puts "    専攻データを取得中..."
              if CollegeMajorImporter.fetch_and_update_major_data(name, api_key)
                puts "    ✓ 専攻データ追加完了"
              else
                puts "    × 専攻データ取得失敗"
              end
            end
            
            total_added += 1
            puts "  ✓ #{name}: $#{net_price ? net_price.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse : 'N/A'} [コメント・専攻データ付き]"
          end
        end
      else
        puts "  × APIエラー: #{response.code}"
      end
      
      sleep 0.5  # API制限対策
    end
    
    puts "\n========================================="
    puts "インポート完了！"
    puts "追加/更新した大学数: #{total_added}"
    puts "授業料データがある大学総数: #{Condition.where.not(tuition: [nil, 0]).count}"
    puts "コメント付き大学総数: #{Condition.where.not(comment: [nil, '']).count}"
    puts "専攻データ付き大学総数: #{Condition.where('pcip_business > 0 OR pcip_engineering > 0 OR pcip_computer_science > 0').count}"
    puts "========================================="
  end
end