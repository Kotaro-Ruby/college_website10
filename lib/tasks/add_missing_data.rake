namespace :import do
  desc "Add missing comments and major data to existing colleges"
  task add_missing_data: :environment do
    require 'net/http'
    require 'json'
    require 'dotenv/load'
    require_relative '../college_comment_generator'
    require_relative '../college_major_importer'
    
    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    
    unless api_key
      puts "エラー: COLLEGE_SCORECARD_API_KEYが設定されていません"
      return
    end
    
    puts "既存大学の不足データを補完開始..."
    
    # コメントがない大学の数をカウント
    colleges_without_comments = Condition.where(comment: [nil, ''])
    colleges_without_majors = Condition.where('pcip_business IS NULL OR pcip_business = 0')
    
    puts "コメントがない大学: #{colleges_without_comments.count}校"
    puts "専攻データがない大学: #{colleges_without_majors.count}校"
    
    comment_added = 0
    major_added = 0
    
    # 1. コメントの追加
    puts "\n=== コメントの追加 ==="
    colleges_without_comments.find_each.with_index do |college, index|
      comment_data = {
        students: college.students,
        acceptance_rate: college.acceptance_rate,
        ownership: college.privateorpublic,
        school_type: college.school_type
      }
      
      comment = CollegeCommentGenerator.generate_comment_for_college(college.college, comment_data)
      college.update(comment: comment)
      comment_added += 1
      
      if (index + 1) % 100 == 0
        puts "コメント追加進捗: #{index + 1}/#{colleges_without_comments.count}"
      end
    end
    
    # 2. 専攻データの追加（最大500校まで）
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
    puts "追加したコメント数: #{comment_added}"
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
  
  desc "Add comments only to colleges without comments"
  task add_comments_only: :environment do
    require_relative '../college_comment_generator'
    
    puts "コメント追加開始..."
    
    colleges_without_comments = Condition.where(comment: [nil, ''])
    total_to_update = colleges_without_comments.count
    updated_count = 0
    
    puts "対象大学数: #{total_to_update}校"
    
    colleges_without_comments.find_each.with_index do |college, index|
      comment_data = {
        students: college.students,
        acceptance_rate: college.acceptance_rate,
        ownership: college.privateorpublic,
        school_type: college.school_type
      }
      
      comment = CollegeCommentGenerator.generate_comment_for_college(college.college, comment_data)
      college.update(comment: comment)
      updated_count += 1
      
      if (index + 1) % 200 == 0
        puts "進捗: #{index + 1}/#{total_to_update} (#{((index + 1).to_f / total_to_update * 100).round(1)}%)"
      end
    end
    
    puts "\\nコメント追加完了！"
    puts "更新された大学数: #{updated_count}校"
    puts "現在のコメント数: #{Condition.where.not(comment: [nil, '']).count}校"
  end
end