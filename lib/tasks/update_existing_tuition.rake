namespace :update do
  desc "Update tuition for existing colleges in database"
  task existing_tuition: :environment do
    require 'net/http'
    require 'json'
    require 'dotenv/load'  # .envファイルを読み込む
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    
    unless api_key
      puts "エラー: COLLEGE_SCORECARD_API_KEYが設定されていません"
      return
    end
    
    # 授業料データがない、または0円の大学を取得
    conditions = Condition.where(tuition: [nil, 0, 0.0])
    
    puts "更新対象: #{conditions.count}校"
    
    base_url = "https://api.data.gov/ed/collegescorecard/v1/schools"
    
    updated_count = 0
    not_found_count = 0
    
    conditions.find_each.with_index do |condition, index|
      puts "\n[#{index + 1}/#{conditions.count}] 検索中: #{condition.college}"
      
      # 大学名で検索（完全一致を試みる）
      params = {
        'api_key' => api_key,
        'school.name' => condition.college,
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
            # 最も名前が近い結果を選択
            best_match = results.find { |r| r['school.name'].downcase == condition.college.downcase }
            best_match ||= results.first
            
            school = best_match
            ownership_code = school['school.ownership']
            is_public = ownership_code == 1
            
            # Net Priceの決定
            net_price = if is_public
                          school['latest.cost.avg_net_price.public'] || 
                          school['latest.cost.tuition.out_of_state'] ||
                          school['latest.cost.avg_net_price.overall']
                        else
                          school['latest.cost.avg_net_price.private'] || 
                          school['latest.cost.avg_net_price.overall'] ||
                          school['latest.cost.tuition.in_state']
                        end
            
            if net_price && net_price > 0
              condition.update(tuition: net_price)
              updated_count += 1
              puts "  ✓ 更新完了: $#{net_price.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
              puts "    (マッチ: #{school['school.name']})"
            else
              puts "  × 授業料データが見つかりませんでした"
            end
          else
            not_found_count += 1
            puts "  × APIで大学が見つかりませんでした"
          end
        else
          puts "  × APIエラー: #{response.code}"
        end
        
        sleep 0.1  # API制限を考慮
        
      rescue => e
        puts "  × エラー: #{e.message}"
      end
    end
    
    puts "\n========================================="
    puts "処理完了！"
    puts "更新成功: #{updated_count}校"
    puts "見つからなかった: #{not_found_count}校"
    puts "授業料データがある大学総数: #{Condition.where.not(tuition: [nil, 0]).count}校"
  end
  
  desc "Search and update specific college tuition"
  task :college_tuition, [:college_name] => :environment do |t, args|
    require 'net/http'
    require 'json'
    require 'dotenv/load'
    
    college_name = args[:college_name]
    
    unless college_name
      puts "使用方法: rails update:college_tuition['大学名']"
      return
    end
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    
    # 大学を検索
    condition = Condition.find_by("LOWER(college) LIKE ?", "%#{college_name.downcase}%")
    
    if condition
      puts "Found: #{condition.college}"
      
      # APIで検索
      base_url = "https://api.data.gov/ed/collegescorecard/v1/schools"
      params = {
        'api_key' => api_key,
        'school.name' => condition.college,
        '_fields' => 'school.name,school.ownership,latest.cost.avg_net_price.public,latest.cost.avg_net_price.private,latest.cost.avg_net_price.overall,latest.cost.tuition.out_of_state,latest.cost.tuition.in_state'
      }
      
      uri = URI(base_url)
      uri.query = URI.encode_www_form(params)
      
      response = Net::HTTP.get_response(uri)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        puts "API Results: #{data['results'].length} matches"
        
        data['results'].each_with_index do |school, i|
          puts "#{i + 1}. #{school['school.name']}"
          puts "   Public Net Price: $#{school['latest.cost.avg_net_price.public']}"
          puts "   Private Net Price: $#{school['latest.cost.avg_net_price.private']}"
          puts "   Out-of-State Tuition: $#{school['latest.cost.tuition.out_of_state']}"
        end
      end
    else
      puts "大学が見つかりませんでした: #{college_name}"
    end
  end
end