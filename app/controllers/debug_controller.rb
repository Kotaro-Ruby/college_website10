class DebugController < ApplicationController
  def db_status
    total_colleges = Condition.count
    with_names = Condition.where.not(college: [nil, '']).count
    with_comments = Condition.where.not(comment: [nil, '']).count
    with_cities = Condition.where.not(city: [nil, '']).count
    with_states = Condition.where.not(state: [nil, '']).count
    with_majors = Condition.where('pcip_business > 0 OR pcip_engineering > 0 OR pcip_computer_science > 0').count
    
    # Sample records
    sample_colleges = Condition.limit(5).pluck(:college, :city, :state)
    
    render plain: <<~TEXT
      === データベース状況 ===
      総レコード数: #{total_colleges}
      大学名あり: #{with_names}
      都市名あり: #{with_cities}
      州名あり: #{with_states}
      コメントあり: #{with_comments}
      専攻データあり: #{with_majors}
      
      === サンプル大学 ===
      #{sample_colleges.map { |name, city, state| "#{name} - #{city}, #{state}" }.join("\n")}
      
      === 環境情報 ===
      Rails環境: #{Rails.env}
      API Key設定: #{ENV['COLLEGE_SCORECARD_API_KEY'] ? '設定済み' : '未設定'}
    TEXT
  end
end