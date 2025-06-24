namespace :update do
  desc "Update tuition in smaller batches"
  task :batch_tuition, [:batch_size] => :environment do |t, args|
    require 'net/http'
    require 'json'
    require 'dotenv/load'
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    batch_size = (args[:batch_size] || 100).to_i
    
    unless api_key
      puts "エラー: COLLEGE_SCORECARD_API_KEYが設定されていません"
      return
    end
    
    # 授業料データがない大学を取得
    conditions = Condition.where(tuition: [nil, 0, 0.0]).limit(batch_size)
    
    puts "更新対象: #{conditions.count}校 (バッチサイズ: #{batch_size})"
    
    base_url = "https://api.data.gov/ed/collegescorecard/v1/schools"
    
    updated_count = 0
    not_found_count = 0
    
    conditions.find_each.with_index do |condition, index|
      puts "\n[#{index + 1}/#{conditions.count}] 検索中: #{condition.college}"
      
      # シンプルな検索パターン
      search_patterns = [
        condition.college,                                    # 完全一致
        condition.college.gsub(/[\-\s]+/, ' ').strip,        # 正規化
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
          '_per_page' => 10
        }
        
        uri = URI(base_url)
        uri.query = URI.encode_www_form(params)
        
        begin
          response = Net::HTTP.get_response(uri)
          
          if response.code == '200'
            data = JSON.parse(response.body)
            results = data['results']
            
            if results && results.any?
              # 最初の結果を使用
              school = results.first
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
                puts "    (マッチ: #{school['school.name']})"
                found = true
                break
              end
            end
          end
          
          sleep 0.2  # API制限を考慮
          
        rescue => e
          puts "  × エラー: #{e.message}"
          sleep 1
        end
      end
      
      unless found
        not_found_count += 1
        puts "  × APIで大学が見つかりませんでした"
      end
    end
    
    puts "\n========================================="
    puts "バッチ処理完了！"
    puts "更新成功: #{updated_count}校"
    puts "見つからなかった: #{not_found_count}校"
    puts "授業料データがある大学総数: #{Condition.where.not(tuition: [nil, 0]).count}校"
    puts "全体のカバー率: #{(Condition.where.not(tuition: [nil, 0]).count.to_f / Condition.count * 100).round(1)}%"
  end
end