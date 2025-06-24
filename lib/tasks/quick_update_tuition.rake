namespace :update do
  desc "Quick update tuition for specific colleges"
  task quick_tuition: :environment do
    require 'net/http'
    require 'json'
    require 'dotenv/load'
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    
    # 4年制大学のみを対象とし、小さなバッチで処理
    conditions = Condition.where(tuition: [nil, 0, 0.0])
                         .where("college LIKE ? OR college LIKE ? OR college LIKE ?", 
                               "%University%", "%College%", "%Institute%")
                         .limit(100)
    
    puts "4年制大学の更新対象: #{conditions.count}校"
    
    base_url = "https://api.data.gov/ed/collegescorecard/v1/schools"
    updated_count = 0
    
    conditions.each_with_index do |condition, index|
      puts "\n[#{index + 1}/#{conditions.count}] #{condition.college}"
      
      params = {
        'api_key' => api_key,
        'school.name' => condition.college,
        'school.degrees_awarded.predominant' => '3',  # 4年制大学のみ
        '_fields' => 'school.name,school.ownership,latest.cost.avg_net_price.public,latest.cost.avg_net_price.private,latest.cost.avg_net_price.overall,latest.cost.tuition.out_of_state,latest.cost.tuition.in_state',
        '_per_page' => 5
      }
      
      uri = URI(base_url)
      uri.query = URI.encode_www_form(params)
      
      begin
        response = Net::HTTP.get_response(uri)
        
        if response.code == '200'
          data = JSON.parse(response.body)
          results = data['results']
          
          if results && results.any?
            school = results.first
            ownership_code = school['school.ownership']
            is_public = ownership_code == 1
            
            net_price = if is_public
                          school['latest.cost.tuition.out_of_state'] ||
                          school['latest.cost.avg_net_price.public'] || 
                          school['latest.cost.avg_net_price.overall']
                        else
                          school['latest.cost.avg_net_price.private'] || 
                          school['latest.cost.avg_net_price.overall']
                        end
            
            if net_price && net_price > 0
              condition.update(tuition: net_price)
              updated_count += 1
              puts "  ✓ $#{net_price.to_i.to_s.reverse.gsub(/(\\d{3})(?=\\d)/, '\\\\1,').reverse} (#{school['school.name']})"
            else
              puts "  - 授業料データなし"
            end
          else
            puts "  × 見つからず"
          end
        end
        
        sleep 0.3
        
      rescue => e
        puts "  × エラー: #{e.message}"
        sleep 1
      end
    end
    
    puts "\n========================================="
    puts "更新完了: #{updated_count}校"
    puts "授業料データ総数: #{Condition.where.not(tuition: [nil, 0]).count}校"
    puts "カバー率: #{(Condition.where.not(tuition: [nil, 0]).count.to_f / Condition.count * 100).round(1)}%"
  end
end