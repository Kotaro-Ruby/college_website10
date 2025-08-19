namespace :import do
  desc "Import student statistics from Excel file"
  task student_statistics: :environment do
    require 'roo'
    
    excel_file = '/Users/kotaro/Downloads/2023 Student summary tables.xlsx'
    xlsx = Roo::Spreadsheet.open(excel_file)
    
    puts "=== オーストラリア39大学の学生数データインポート開始 ==="
    
    # Table 4から学生数データを抽出
    xlsx.sheet('4')
    
    updated_count = 0
    not_found = []
    
    # データのマッピング
    university_mappings = {
      'The University of New South Wales' => 'UNSW',
      'The Australian National University' => 'The Australian National University',
      'Charles Sturt University' => 'Charles Sturt University'
      # 他のマッピングも必要に応じて追加
    }
    
    (7..150).each do |row|
      row_data = xlsx.row(row)
      next unless row_data[1] && row_data[1].to_s.include?('University')
      
      excel_name = row_data[1].to_s.strip
      
      # データベースの大学を検索
      university = nil
      
      # 直接名前で検索
      university = AuUniversity.find_by(name: excel_name)
      
      # マッピングで検索
      if !university && university_mappings[excel_name]
        university = AuUniversity.find_by(name: university_mappings[excel_name])
      end
      
      # UNSWの特別処理
      if !university && excel_name.include?('New South Wales')
        university = AuUniversity.find_by(name: 'UNSW')
      end
      
      # 部分一致で検索
      if !university
        AuUniversity.all.each do |uni|
          if excel_name.include?(uni.name) || uni.name.include?(excel_name.split(' University').first)
            university = uni
            break
          end
        end
      end
      
      if university
        # 学生数データを更新
        university.update!(
          commencing_students_2022: row_data[2].to_i,
          commencing_students_2023: row_data[3].to_i,
          total_students_2022: row_data[7].to_i,
          total_students_2023: row_data[8].to_i,
          student_growth_rate: row_data[10].to_f * 100 # パーセンテージに変換
        )
        
        updated_count += 1
        puts "✓ #{university.name}: 2023年学生数=#{row_data[8]}, 新入生=#{row_data[3]}"
      else
        not_found << excel_name
      end
    end
    
    # Bond UniversityとAustralian Catholic Universityは私立なのでTable 3から取得
    xlsx.sheet('3')
    
    ['Bond University', 'Australian Catholic University'].each do |uni_name|
      (7..50).each do |row|
        row_data = xlsx.row(row)
        if row_data[1] && row_data[1].to_s.include?(uni_name)
          university = AuUniversity.find_by(name: uni_name)
          if university
            university.update!(
              commencing_students_2022: row_data[2].to_i,
              commencing_students_2023: row_data[3].to_i,
              total_students_2022: row_data[7].to_i,
              total_students_2023: row_data[8].to_i,
              student_growth_rate: row_data[10].to_f * 100
            )
            updated_count += 1
            puts "✓ #{university.name}: 2023年学生数=#{row_data[8]}, 新入生=#{row_data[3]}"
          end
          break
        end
      end
    end
    
    puts "\n=== インポート完了 ==="
    puts "更新された大学数: #{updated_count}/39"
    
    if not_found.any?
      puts "\n見つからなかった大学:"
      not_found.each { |name| puts "  - #{name}" }
    end
    
    # 統計情報の表示
    puts "\n=== 統計情報 ==="
    total_students = AuUniversity.sum(:total_students_2023)
    total_commencing = AuUniversity.sum(:commencing_students_2023)
    puts "全学生数（2023年）: #{total_students.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}人"
    puts "新入生数（2023年）: #{total_commencing.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}人"
    
    # トップ5大学
    puts "\n=== 学生数トップ5大学 ==="
    AuUniversity.order(total_students_2023: :desc).limit(5).each_with_index do |uni, i|
      puts "#{i+1}. #{uni.name}: #{uni.total_students_2023}人"
    end
  end
end