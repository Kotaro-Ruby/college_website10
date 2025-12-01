namespace :import do
  desc "Add missing major data to existing colleges"
  task add_missing_data: :environment do
    require 'net/http'
    require 'json'
    require 'dotenv/load'
    require_relative '../college_major_importer'

    api_key = ENV['COLLEGE_SCORECARD_API_KEY']

    unless api_key
      puts "エラー: COLLEGE_SCORECARD_API_KEYが設定されていません"
      return
    end

    puts "既存大学の不足データを補完開始..."

    colleges_without_majors = Condition.where('pcip_business IS NULL OR pcip_business = 0')

    puts "専攻データがない大学: #{colleges_without_majors.count}校"

    major_added = 0

    # 専攻データの追加（最大500校まで）
    puts "\n=== 専攻データの追加 ==="
    colleges_without_majors.limit(500).find_each.with_index do |college, index|
      puts "#{index + 1}/500: #{college.college} の専攻データを取得中..."
      
      if CollegeMajorImporter.fetch_and_update_major_data(college.college, api_key)
        major_added += 1
        puts "  ✓ 成功"
      else
        puts "  × 失敗"
      end
      
      # API制限対策
      sleep(0.2)
    end
    
    puts "\n=== 補完完了 ==="
    puts "追加した専攻データ数: #{major_added}"
    
    # 最終統計
    total_colleges = Condition.count
    colleges_with_comments = Condition.where.not(comment: [nil, '']).count
    colleges_with_majors = Condition.where('pcip_business > 0 OR pcip_engineering > 0 OR pcip_computer_science > 0').count
    
    puts "\n=== 最終統計 ==="
    puts "総大学数: #{total_colleges}"
    puts "コメント付き: #{colleges_with_comments} (#{(colleges_with_comments.to_f / total_colleges * 100).round(1)}%)"
    puts "専攻データ付き: #{colleges_with_majors} (#{(colleges_with_majors.to_f / total_colleges * 100).round(1)}%)"
  end
  
end