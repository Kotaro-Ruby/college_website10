namespace :data do
  desc "Fetch NCAA data for universities"
  task fetch_ncaa: :environment do
    require 'net/http'
    require 'json'
    
    # 例: Wikipedia APIを使用してNCAA情報を取得
    def fetch_ncaa_info(college_name)
      # ここに実際のAPI呼び出しやスクレイピングロジックを実装
      # 例として、固定データを返す
      case college_name
      when /Ohio State/
        { division: "Division I", conference: "Big Ten" }
      when /Harvard/
        { division: "Division I", conference: "Ivy League" }
      when /MIT/
        { division: "Division III", conference: "NEWMAC" }
      else
        { division: nil, conference: nil }
      end
    end
    
    Condition.find_each do |condition|
      ncaa_info = fetch_ncaa_info(condition.college)
      
      if ncaa_info[:division]
        condition.update(Division: ncaa_info[:division])
        puts "Updated #{condition.college}: #{ncaa_info[:division]}"
      end
      
      sleep 0.5 # APIレート制限を考慮
    end
  end
end