namespace :survey do
  desc "アンケート回答状況を表示"
  task stats: :environment do
    puts "=== アンケート回答状況 ==="
    puts "総回答数: #{SurveyResponse.count}"
    puts "平均評価: #{SurveyResponse.average_rating}星"
    puts ""
    
    # 評価別集計
    puts "--- 評価別集計 ---"
    SurveyResponse.rating_distribution.each do |rating, count|
      puts "#{rating}星: #{count}件"
    end
    puts ""
    
    # 過去7日間の回答数
    puts "--- 過去7日間の回答数 ---"
    7.downto(0) do |days_ago|
      date = Date.current - days_ago.days
      count = SurveyResponse.where(created_at: date.beginning_of_day..date.end_of_day).count
      puts "#{date.strftime('%Y-%m-%d')}: #{count}件"
    end
    puts ""
    
    # 目的別集計
    puts "--- 目的別集計 ---"
    SurveyResponse.group(:purpose).count.each do |purpose, count|
      display_name = if purpose.blank?
        "未回答"
      else
        response = SurveyResponse.new(purpose: purpose)
        response.purpose_display
      end
      puts "#{display_name}: #{count}件"
    end
    puts ""
    
    # 最新の回答
    puts "--- 最新の回答5件 ---"
    SurveyResponse.recent.limit(5).each do |survey|
      puts "#{survey.created_at.strftime('%Y-%m-%d %H:%M')} - #{survey.rating}星 - #{survey.purpose_display}"
      puts "  フィードバック: #{survey.feedback}" if survey.feedback.present?
    end
  end
  
  desc "アンケートの詳細回答を表示"
  task details: :environment do
    puts "=== 詳細回答一覧 ==="
    SurveyResponse.where.not(feedback: [nil, ""]).recent.each do |survey|
      puts "--- #{survey.created_at.strftime('%Y-%m-%d %H:%M')} (#{survey.rating}星) ---"
      puts "目的: #{survey.purpose_display}"
      puts "フィードバック: #{survey.feedback}"
      puts ""
    end
  end
  
  desc "アンケート統計のサマリーを表示"
  task summary: :environment do
    total = SurveyResponse.count
    if total == 0
      puts "まだアンケート回答がありません。"
      return
    end
    
    puts "=== アンケートサマリー ==="
    puts "総回答数: #{total}"
    puts "平均評価: #{SurveyResponse.average_rating}星"
    
    # 高評価の割合
    high_rating_count = SurveyResponse.where(rating: [4, 5]).count
    high_rating_percentage = (high_rating_count.to_f / total * 100).round(1)
    puts "高評価(4-5星): #{high_rating_percentage}%"
    
    # フィードバックがある割合
    feedback_count = SurveyResponse.where.not(feedback: [nil, ""]).count
    feedback_percentage = (feedback_count.to_f / total * 100).round(1)
    puts "フィードバック記入率: #{feedback_percentage}%"
  end
end