namespace :import do
  desc "Import overseas student data from Excel file"
  task overseas_students: :environment do
    require 'roo'
    
    excel_file = '/Users/kotaro/Downloads/2023 Section 7 - Overseas students.xlsx'
    xlsx = Roo::Spreadsheet.open(excel_file)
    
    puts "=== 留学生データインポート開始 ==="
    
    # 1. 39大学の留学生EFTSLデータをインポート
    xlsx.sheet('7.5')
    puts "\n=== 大学別留学生EFTSL ==="
    
    updated_count = 0
    (5..200).each do |row|
      row_data = xlsx.row(row)
      if row_data[1] && row_data[1].to_s.include?('University')
        uni_name = row_data[1].to_s.strip.gsub(/<[^>]*>/, '')
        
        # データ位置
        commencing_eftsl = row_data[2].to_f
        total_eftsl = (row_data[3] || row_data[4]).to_f
        
        # データベースの大学を検索
        university = nil
        
        # 特殊なマッピング
        if uni_name.include?('New South Wales')
          university = AuUniversity.find_by(name: 'UNSW')
        elsif uni_name.include?('CQUniversity')
          university = AuUniversity.find_by(name: 'CQUniversity Australia')
        else
          # 直接検索
          university = AuUniversity.find_by(name: uni_name)
          
          # 部分一致で検索
          if !university
            AuUniversity.all.each do |uni|
              if uni_name.include?(uni.name) || uni.name.include?(uni_name)
                university = uni
                break
              end
            end
          end
        end
        
        if university && university.total_students_2023 && university.total_students_2023 > 0
          # EFTSL比率から実際の留学生数を推定（概算）
          # 注: これは推定値です。正確な数値ではありません
          overseas_ratio = total_eftsl / (university.total_students_2023 * 0.8) # 平均0.8 EFTSL/学生と仮定
          overseas_students_estimate = (university.total_students_2023 * overseas_ratio).to_i
          overseas_commencing_estimate = (university.commencing_students_2023 * (commencing_eftsl / total_eftsl)).to_i if university.commencing_students_2023
          
          university.update!(
            overseas_students_2023: overseas_students_estimate,
            overseas_commencing_2023: overseas_commencing_estimate,
            overseas_percentage: (overseas_ratio * 100).round(1)
          )
          
          updated_count += 1
          puts "✓ #{university.name}: EFTSL=#{total_eftsl}, 推定留学生=#{overseas_students_estimate}人 (#{university.overseas_percentage}%)"
        end
      end
    end
    
    puts "\n更新された大学数: #{updated_count}/39"
    
    # 2. 国別留学生データをインポート
    xlsx.sheet('7.4')
    puts "\n=== 国別留学生データ ==="
    
    # 既存データをクリア
    OverseasStudentCountry.destroy_all
    
    countries = []
    (5..300).each do |row|
      row_data = xlsx.row(row)
      if row_data[1] && row_data[2] && row_data[2].to_s != '< 5'
        country = row_data[1].to_s.strip
        count = row_data[2].to_i
        countries << {country: country, count: count} if count > 0
      end
    end
    
    # ソートしてランキングを付ける
    total = countries.sum { |c| c[:count] }
    countries.sort_by! { |c| -c[:count] }
    
    countries.each_with_index do |c, i|
      OverseasStudentCountry.create!(
        country: c[:country],
        student_count: c[:count],
        percentage: (c[:count].to_f / total * 100).round(2),
        rank: i + 1
      )
      
      if i < 20
        puts "#{i+1}. #{c[:country]}: #{c[:count]}人 (#{(c[:count].to_f / total * 100).round(1)}%)"
      end
    end
    
    puts "\nインポートした国数: #{countries.size}"
    puts "総留学生数: #{total.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}人"
    
    # 3. 統計情報の表示
    puts "\n=== 留学生比率トップ5大学 ==="
    AuUniversity.where.not(overseas_percentage: nil)
                .order(overseas_percentage: :desc)
                .limit(5)
                .each_with_index do |uni, i|
      puts "#{i+1}. #{uni.name}: #{uni.overseas_percentage}%"
    end
  end
end