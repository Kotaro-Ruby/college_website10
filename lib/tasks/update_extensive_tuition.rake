namespace :update do
  desc "Extensively update tuition for existing colleges with fuzzy matching"
  task extensive_tuition: :environment do
    require 'net/http'
    require 'json'
    require 'dotenv/load'
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    
    unless api_key
      puts "エラー: COLLEGE_SCORECARD_API_KEYが設定されていません"
      return
    end
    
    # 授業料データがない大学を取得（より多くの結果を対象とする）
    conditions = Condition.where(tuition: [nil, 0, 0.0]).limit(500)
    
    puts "更新対象: #{conditions.count}校"
    
    base_url = "https://api.data.gov/ed/collegescorecard/v1/schools"
    
    updated_count = 0
    not_found_count = 0
    
    conditions.find_each.with_index do |condition, index|
      puts "\n[#{index + 1}/#{conditions.count}] 検索中: #{condition.college}"
      
      # 複数の検索パターンを試行
      search_patterns = [
        condition.college,                                    # 完全一致
        condition.college.gsub(/[\-\s]/, ' '),              # ハイフンをスペースに
        condition.college.gsub(/University.*/, 'University'), # University以降をトリム
        condition.college.gsub(/College.*/, 'College'),       # College以降をトリム
        condition.college.split(' ').first(3).join(' '),     # 最初の3単語
        condition.college.split(' ').first(2).join(' ')      # 最初の2単語
      ].uniq
      
      found = false
      
      search_patterns.each do |pattern|
        next if found
        
        params = {
          'api_key' => api_key,
          'school.name' => pattern,
          '_fields' => [
            'school.name',
            'school.ownership',
            'latest.cost.avg_net_price.public',
            'latest.cost.avg_net_price.private',
            'latest.cost.avg_net_price.overall',
            'latest.cost.tuition.out_of_state',
            'latest.cost.tuition.in_state'
          ].join(','),
          '_per_page' => 20
        }
        
        uri = URI(base_url)
        uri.query = URI.encode_www_form(params)
        
        begin
          response = Net::HTTP.get_response(uri)
          
          if response.code == '200'
            data = JSON.parse(response.body)
            results = data['results']
            
            if results && results.any?
              # 名前の類似度でマッチングを改善
              best_match = results.find do |r| 
                school_name = r['school.name'].downcase
                college_name = condition.college.downcase
                
                # 完全一致
                school_name == college_name ||
                # 部分一致（両方向）
                school_name.include?(college_name.split(' ').first) ||
                college_name.include?(school_name.split(' ').first) ||
                # キーワードマッチ
                (school_name.include?('university') && college_name.include?('university')) ||
                (school_name.include?('college') && college_name.include?('college'))
              end
              
              best_match ||= results.first
              
              if best_match
                school = best_match
                ownership_code = school['school.ownership']
                is_public = ownership_code == 1
                
                # Net Priceの決定
                net_price = if is_public
                              school['latest.cost.tuition.out_of_state'] ||
                              school['latest.cost.avg_net_price.public'] || 
                              school['latest.cost.avg_net_price.overall']
                            else
                              school['latest.cost.avg_net_price.private'] || 
                              school['latest.cost.avg_net_price.overall'] ||
                              school['latest.cost.tuition.in_state']
                            end
                
                if net_price && net_price > 0
                  condition.update(tuition: net_price)
                  updated_count += 1
                  puts "  ✓ 更新完了: $#{net_price.to_i.to_s.reverse.gsub(/(\\d{3})(?=\\d)/, '\\\\1,').reverse}"
                  puts "    (マッチ: #{school['school.name']}, パターン: #{pattern})"
                  found = true
                  break
                end
              end
            end
          end
          
          sleep 0.15  # API制限を考慮（より短い間隔）
          
        rescue => e
          puts "  × エラー: #{e.message}"
        end
      end
      
      unless found
        not_found_count += 1
        puts "  × APIで大学が見つかりませんでした"
      end
    end
    
    puts "\n========================================="
    puts "拡張処理完了！"
    puts "更新成功: #{updated_count}校"
    puts "見つからなかった: #{not_found_count}校"
    puts "授業料データがある大学総数: #{Condition.where.not(tuition: [nil, 0]).count}校"
  end
end