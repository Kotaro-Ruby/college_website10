namespace :import do
  desc "Import data from College Scorecard API (free and legal)"
  task college_scorecard: :environment do
    require 'net/http'
    require 'json'
    
    # College Scorecard API - 完全無料・合法
    # APIキーは https://collegescorecard.ed.gov/data/documentation/ から無料で取得可能
    api_key = ENV['COLLEGE_SCORECARD_API_KEY'] || 'YOUR_API_KEY_HERE'
    
    # 主要な大学のデータを取得（例：オハイオ州）
    state = 'OH'  # 州コードで検索
    
    # APIエンドポイント
    url = "https://api.data.gov/ed/collegescorecard/v1/schools?"
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
        'school.ownership',  # 1=Public, 2=Private nonprofit, 3=Private for-profit
        'latest.student.size',
        'latest.cost.tuition.in_state',
        'latest.cost.tuition.out_of_state',
        'latest.cost.avg_net_price.public',
        'latest.cost.avg_net_price.private',
        'latest.cost.avg_net_price.overall',
        'latest.completion.completion_rate_4yr_150nt',
        'latest.admissions.admission_rate.overall',
        'latest.student.demographics.men',
        'latest.student.demographics.women'
      ].join(','),
      '_per_page' => 100
    }
    
    uri = URI(url)
    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      schools = data['results']
      
      puts "Found #{schools.length} schools"
      
      schools.each do |school|
        # 学校名
        name = school['school.name']
        
        # 所有形態の変換
        ownership = case school['school.ownership']
                   when 1 then '州立'
                   when 2 then '私立'
                   when 3 then '営利'
                   else '不明'
                   end
        
        # Net Priceの決定（州立/私立で異なる）
        # 州立大学：out-of-state授業料を使用（ただし、net priceがあればそちらを優先）
        # 私立大学：net priceを使用
        net_price = if ownership == '州立'
                      # 州立大学の場合：公立のnet price、なければout-of-state授業料
                      school['latest.cost.avg_net_price.public'] || 
                      school['latest.cost.tuition.out_of_state'] || 
                      school['latest.cost.avg_net_price.overall']
                    else
                      # 私立大学の場合：私立のnet price、なければ全体のnet price
                      school['latest.cost.avg_net_price.private'] || 
                      school['latest.cost.avg_net_price.overall'] ||
                      school['latest.cost.tuition.in_state']
                    end
        
        # データベースに保存
        condition = Condition.find_or_initialize_by(college: name)
        condition.update(
          state: school['school.state'],
          city: school['school.city'],
          zip: school['school.zip'],
          privateorpublic: ownership,
          students: school['latest.student.size'],
          tuition: net_price,  # Net Priceを授業料として保存
          graduation_rate: school['latest.completion.completion_rate_4yr_150nt'],
          acceptance_rate: school['latest.admissions.admission_rate.overall'],
          url: school['school.school_url']
        )
        
        puts "Updated: #{name} - Net Price: $#{net_price ? net_price.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse : 'N/A'}"
      end
    else
      puts "Error: #{response.code} - #{response.body}"
    end
  end
end

# 使い方：
# 1. https://collegescorecard.ed.gov/data/documentation/ でAPIキーを無料取得
# 2. 環境変数に設定: export COLLEGE_SCORECARD_API_KEY=your_key_here
# 3. 実行: rails import:college_scorecard