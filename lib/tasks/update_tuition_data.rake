namespace :update do
  desc "Update tuition data with Net Price from College Scorecard (free API)"
  task tuition: :environment do
    require 'net/http'
    require 'json'
    
    # College Scorecard API - 無料で取得可能
    # https://collegescorecard.ed.gov/data/documentation/ でAPIキーを取得
    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    
    unless api_key
      puts "エラー: COLLEGE_SCORECARD_API_KEYが設定されていません"
      puts "以下の手順でAPIキーを設定してください："
      puts "1. https://collegescorecard.ed.gov/data/documentation/ でAPIキーを取得"
      puts "2. export COLLEGE_SCORECARD_API_KEY=your_key_here"
      return
    end
    
    # 既存の大学のリストを取得
    conditions_without_tuition = Condition.where(tuition: nil).or(Condition.where(tuition: 0))
    
    puts "授業料データがない大学数: #{conditions_without_tuition.count}"
    
    # APIエンドポイント
    base_url = "https://api.data.gov/ed/collegescorecard/v1/schools"
    
    # バッチ処理で大学名を検索
    conditions_without_tuition.find_each.with_index do |condition, index|
      puts "\n[#{index + 1}/#{conditions_without_tuition.count}] 検索中: #{condition.college}"
      
      # 大学名で検索
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
        ].join(',')
      }
      
      uri = URI(base_url)
      uri.query = URI.encode_www_form(params)
      
      begin
        response = Net::HTTP.get_response(uri)
        
        if response.code == '200'
          data = JSON.parse(response.body)
          results = data['results']
          
          if results && results.any?
            school = results.first  # 最初の結果を使用
            
            # 所有形態の確認
            ownership_code = school['school.ownership']
            is_public = ownership_code == 1
            
            # Net Priceの決定
            net_price = if is_public
                          # 州立大学：out-of-state学生向けのnet price
                          school['latest.cost.avg_net_price.public'] || 
                          school['latest.cost.tuition.out_of_state'] ||
                          school['latest.cost.avg_net_price.overall']
                        else
                          # 私立大学：私立のnet price
                          school['latest.cost.avg_net_price.private'] || 
                          school['latest.cost.avg_net_price.overall'] ||
                          school['latest.cost.tuition.in_state']
                        end
            
            if net_price && net_price > 0
              condition.update(tuition: net_price)
              puts "  ✓ 更新完了: $#{net_price.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
            else
              puts "  × 授業料データが見つかりませんでした"
            end
          else
            puts "  × 大学が見つかりませんでした"
          end
        else
          puts "  × APIエラー: #{response.code}"
        end
        
        # API利用制限を考慮
        sleep 0.1
        
      rescue => e
        puts "  × エラー: #{e.message}"
      end
    end
    
    puts "\n処理完了！"
    puts "授業料データがある大学数: #{Condition.where.not(tuition: nil).where.not(tuition: 0).count}"
  end
  
  desc "Update tuition for specific state"
  task :tuition_by_state, [:state] => :environment do |t, args|
    require 'net/http'
    require 'json'
    
    state = args[:state] || 'OH'  # デフォルトはオハイオ州
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    
    unless api_key
      puts "エラー: COLLEGE_SCORECARD_API_KEYが設定されていません"
      return
    end
    
    puts "#{state}州の大学の授業料を更新中..."
    
    # 州の全大学を取得
    url = "https://api.data.gov/ed/collegescorecard/v1/schools"
    params = {
      'api_key' => api_key,
      'school.state' => state,
      'school.degrees_awarded.predominant' => '3',  # 4年制大学
      '_fields' => [
        'school.name',
        'school.ownership',
        'latest.cost.avg_net_price.public',
        'latest.cost.avg_net_price.private',
        'latest.cost.avg_net_price.overall',
        'latest.cost.tuition.out_of_state',
        'latest.cost.tuition.in_state'
      ].join(','),
      '_per_page' => 100
    }
    
    uri = URI(url)
    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      schools = data['results']
      
      schools.each do |school|
        name = school['school.name']
        ownership_code = school['school.ownership']
        is_public = ownership_code == 1
        
        # Net Priceの決定
        net_price = if is_public
                      school['latest.cost.avg_net_price.public'] || 
                      school['latest.cost.tuition.out_of_state']
                    else
                      school['latest.cost.avg_net_price.private'] || 
                      school['latest.cost.avg_net_price.overall']
                    end
        
        if net_price && net_price > 0
          condition = Condition.find_by(college: name)
          if condition
            condition.update(tuition: net_price)
            puts "✓ #{name}: $#{net_price.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
          end
        end
      end
    end
  end
end

# 使い方:
# 1. APIキーを取得: https://collegescorecard.ed.gov/data/documentation/
# 2. 環境変数を設定: export COLLEGE_SCORECARD_API_KEY=your_key_here
# 3. 全大学の授業料を更新: rails update:tuition
# 4. 特定の州のみ更新: rails update:tuition_by_state[CA]