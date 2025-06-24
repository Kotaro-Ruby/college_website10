namespace :update do
  desc "Update tuition for major colleges only"
  task major_colleges_tuition: :environment do
    require 'net/http'
    require 'json'
    require 'dotenv/load'
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    
    # 主要な大学のリスト（データベースの大学名に合わせる）
    major_colleges = [
      "Ohio State University",
      "University of Michigan",
      "University of Florida", 
      "Harvard University",
      "Stanford University",
      "MIT",
      "Yale University",
      "Princeton University",
      "Columbia University",
      "University of California-Berkeley",
      "UCLA",
      "New York University",
      "University of Texas at Austin",
      "University of Pennsylvania",
      "Duke University",
      "Northwestern University",
      "University of Chicago",
      "Cornell University",
      "Johns Hopkins University",
      "University of Southern California"
    ]
    
    base_url = "https://api.data.gov/ed/collegescorecard/v1/schools"
    updated_count = 0
    
    major_colleges.each_with_index do |college_name, index|
      puts "\n[#{index + 1}/#{major_colleges.length}] 検索中: #{college_name}"
      
      # データベースから大学を検索
      condition = Condition.find_by("LOWER(college) LIKE ?", "%#{college_name.downcase}%")
      
      if condition
        puts "  DBで見つかりました: #{condition.college}"
        
        # APIで検索
        params = {
          'api_key' => api_key,
          'school.name' => college_name,
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
        
        response = Net::HTTP.get_response(uri)
        
        if response.code == '200'
          data = JSON.parse(response.body)
          results = data['results']
          
          if results && results.any?
            school = results.first
            ownership_code = school['school.ownership']
            is_public = ownership_code == 1
            
            # Net Priceの決定
            net_price = if is_public
                          # 州立：out-of-state学生向け料金を優先
                          school['latest.cost.tuition.out_of_state'] ||
                          school['latest.cost.avg_net_price.public'] || 
                          school['latest.cost.avg_net_price.overall']
                        else
                          # 私立：net priceを使用
                          school['latest.cost.avg_net_price.private'] || 
                          school['latest.cost.avg_net_price.overall'] ||
                          school['latest.cost.tuition.in_state']
                        end
            
            if net_price && net_price > 0
              condition.update(tuition: net_price)
              updated_count += 1
              puts "  ✓ 更新完了: $#{net_price.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
              puts "    タイプ: #{is_public ? '州立（Out-of-State）' : '私立（Net Price）'}"
            end
          end
        end
      else
        puts "  × DBで見つかりませんでした"
      end
      
      sleep 0.2
    end
    
    puts "\n========================================="
    puts "主要大学の授業料更新完了！"
    puts "更新成功: #{updated_count}校"
  end
  
  desc "Manual update single college"
  task :manual_college, [:db_id, :tuition] => :environment do |t, args|
    condition = Condition.find(args[:db_id])
    condition.update(tuition: args[:tuition].to_f)
    puts "Updated #{condition.college}: $#{args[:tuition]}"
  end
end