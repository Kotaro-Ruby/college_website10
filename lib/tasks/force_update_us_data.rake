namespace :import do
  desc "Force update all US university data from compressed file"
  task force_update_all: :environment do
    puts "=== 全アメリカ大学データの強制更新 ==="
    puts "警告: このタスクは全てのデータを上書きします"
    
    compressed_file = Rails.root.join('db', 'college_data_compressed.json.gz')
    
    unless File.exist?(compressed_file)
      puts "エラー: 圧縮データファイルが見つかりません"
      return
    end
    
    begin
      require 'zlib'
      require 'json'
      
      # 圧縮ファイルを展開
      puts "圧縮ファイルを読み込み中..."
      compressed_data = File.read(compressed_file)
      json_data = Zlib::Inflate.inflate(compressed_data)
      data = JSON.parse(json_data)
      
      colleges_data = data['data']
      total_count = colleges_data.size
      
      puts "データソース: #{total_count}校"
      puts "強制更新開始..."
      
      updated_count = 0
      created_count = 0
      error_count = 0
      
      # 進捗表示用
      progress_interval = 100
      
      colleges_data.each_with_index do |college_data, index|
        begin
          college_name = college_data['c']
          
          # 全データを構築
          full_data = {
            college: college_name,
            state: college_data['s'],
            tuition: college_data['t'],
            students: college_data['st'],
            privateorpublic: college_data['p'],
            GPA: college_data['g'],
            acceptance_rate: college_data['a'],
            graduation_rate: college_data['gr'],
            city: college_data['ci'],
            Division: college_data['d'],
            comment: college_data['co']
          }
          
          # 詳細データを追加
          if college_data['add']
            full_data.merge!(college_data['add'])
          end
          
          # 専攻データを追加
          if college_data['maj']
            full_data.merge!(college_data['maj'])
          end
          
          # upsert（存在すれば更新、なければ作成）
          existing = Condition.find_by(college: college_name)
          
          if existing
            existing.update!(full_data)
            updated_count += 1
          else
            Condition.create!(full_data)
            created_count += 1
          end
          
          # 進捗表示
          if (index + 1) % progress_interval == 0
            percentage = ((index + 1).to_f / total_count * 100).round(1)
            puts "進捗: #{index + 1}/#{total_count} (#{percentage}%)"
          end
          
        rescue => e
          error_count += 1
          puts "エラー: #{college_data['c']} - #{e.message}" if error_count <= 10
        end
      end
      
      # 最終統計
      final_count = Condition.count
      with_demographics = Condition.where.not(percent_white: nil).count
      with_test_scores = Condition.where.not(sat_math_25: nil).count
      with_earnings = Condition.where.not(earnings_6yr_median: nil).count
      
      puts ""
      puts "=== 強制更新完了 ==="
      puts "更新: #{updated_count}校"
      puts "新規作成: #{created_count}校"
      puts "エラー: #{error_count}校"
      puts "最終データ数: #{final_count}校"
      puts ""
      puts "詳細データ状況:"
      puts "  人口統計データあり: #{with_demographics} (#{(with_demographics * 100.0 / final_count).round(1)}%)"
      puts "  テストスコアあり: #{with_test_scores} (#{(with_test_scores * 100.0 / final_count).round(1)}%)"
      puts "  収入データあり: #{with_earnings} (#{(with_earnings * 100.0 / final_count).round(1)}%)"
      
    rescue => e
      puts "エラーが発生しました: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
  end
  
  desc "Check specific university data"
  task :check_university, [:name] => :environment do |t, args|
    name = args[:name] || "Ohio Northern University"
    
    puts "=== #{name} のデータ確認 ==="
    
    uni = Condition.find_by(college: name)
    
    if uni
      puts "データベース内のデータ:"
      puts "  基本情報:"
      puts "    州: #{uni.state}"
      puts "    授業料: #{uni.tuition}"
      puts "    学生数: #{uni.students}"
      puts "  人口統計:"
      puts "    白人: #{uni.percent_white || 'なし'}"
      puts "    黒人: #{uni.percent_black || 'なし'}"
      puts "    ヒスパニック: #{uni.percent_hispanic || 'なし'}"
      puts "    アジア系: #{uni.percent_asian || 'なし'}"
      puts "  テストスコア:"
      puts "    SAT Math 25%: #{uni.sat_math_25 || 'なし'}"
      puts "    SAT Reading 25%: #{uni.sat_reading_25 || 'なし'}"
      puts "    ACT Composite 25%: #{uni.act_composite_25 || 'なし'}"
      puts "  収入:"
      puts "    6年後: #{uni.earnings_6yr_median || 'なし'}"
      puts "    10年後: #{uni.earnings_10yr_median || 'なし'}"
    else
      puts "データベースに見つかりません"
    end
    
    # 圧縮ファイルのデータも確認
    require 'zlib'
    require 'json'
    
    compressed_file = Rails.root.join('db', 'college_data_compressed.json.gz')
    if File.exist?(compressed_file)
      compressed_data = File.read(compressed_file)
      json_data = Zlib::Inflate.inflate(compressed_data)
      data = JSON.parse(json_data)
      
      source_data = data['data'].find { |d| d['c'] == name }
      
      if source_data
        puts ""
        puts "圧縮ファイル内のデータ:"
        puts "  基本情報:"
        puts "    州: #{source_data['s']}"
        puts "    授業料: #{source_data['t']}"
        puts "    学生数: #{source_data['st']}"
        
        if source_data['add']
          puts "  詳細データ:"
          puts "    percent_white: #{source_data['add']['percent_white'] || 'なし'}"
          puts "    sat_math_25: #{source_data['add']['sat_math_25'] || 'なし'}"
          puts "    earnings_6yr_median: #{source_data['add']['earnings_6yr_median'] || 'なし'}"
        else
          puts "  詳細データなし"
        end
      else
        puts "圧縮ファイルに見つかりません"
      end
    end
  end
end