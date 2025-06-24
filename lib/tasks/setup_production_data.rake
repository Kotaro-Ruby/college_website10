namespace :college_data do
  desc "Setup all production data (comments, majors, and detailed programs)"
  task setup_production: :environment do
    puts "=== 本番環境データセットアップを開始します ==="
    
    start_time = Time.current
    
    # 1. コメントの追加
    puts "\n1. 大学コメントの追加を開始..."
    begin
      Rake::Task['college_data:add_comments'].invoke
      puts "✓ コメント追加完了"
    rescue => e
      puts "✗ コメント追加でエラー: #{e.message}"
    end
    
    # 2. 専攻データのインポート
    puts "\n2. 専攻データのインポートを開始..."
    begin
      Rake::Task['college_data:import_major_data'].invoke
      puts "✓ 専攻データインポート完了"
    rescue => e
      puts "✗ 専攻データインポートでエラー: #{e.message}"
    end
    
    # 3. 詳細プログラムデータのインポート（オプション）
    puts "\n3. 詳細プログラムデータのインポートを開始..."
    puts "注意: このタスクは時間がかかる場合があります（10-20分）"
    
    begin
      # 環境変数でスキップできるオプション
      if ENV['SKIP_DETAILED_PROGRAMS'] == 'true'
        puts "SKIP_DETAILED_PROGRAMS=trueが設定されているため、詳細プログラムデータをスキップします"
      else
        Rake::Task['college_data:import_full_program_data'].invoke
        puts "✓ 詳細プログラムデータインポート完了"
      end
    rescue => e
      puts "✗ 詳細プログラムデータインポートでエラー: #{e.message}"
      puts "このエラーはスキップして続行します..."
    end
    
    # 最終統計
    puts "\n=== セットアップ完了統計 ==="
    total_colleges = Condition.count
    colleges_with_comments = Condition.where.not(comment: [nil, '']).count
    colleges_with_majors = Condition.where('pcip_business > 0 OR pcip_engineering > 0 OR pcip_computer_science > 0').count
    detailed_programs_count = DetailedProgram.count rescue 0
    
    puts "総大学数: #{total_colleges}"
    puts "コメント付き大学数: #{colleges_with_comments} (#{(colleges_with_comments.to_f / total_colleges * 100).round(1)}%)"
    puts "専攻データ付き大学数: #{colleges_with_majors} (#{(colleges_with_majors.to_f / total_colleges * 100).round(1)}%)"
    puts "詳細プログラム数: #{detailed_programs_count}"
    
    end_time = Time.current
    duration = ((end_time - start_time) / 60).round(1)
    puts "\n総実行時間: #{duration}分"
    puts "=== セットアップ完了 ==="
  end
  
  desc "Setup production data without detailed programs (faster)"
  task setup_production_fast: :environment do
    puts "=== 高速本番環境データセットアップを開始します ==="
    
    ENV['SKIP_DETAILED_PROGRAMS'] = 'true'
    Rake::Task['college_data:setup_production'].invoke
  end
end