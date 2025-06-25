namespace :import do
  desc "Import college data from compressed file"
  task from_compressed: :environment do
    puts "=== 圧縮データからのインポート開始 ==="
    
    compressed_file = Rails.root.join('tmp', 'college_data_compressed.json.gz')
    
    # tmpディレクトリにファイルがない場合、dbディレクトリからコピー
    unless File.exist?(compressed_file)
      db_file = Rails.root.join('db', 'college_data_compressed.json.gz')
      if File.exist?(db_file)
        puts "tmpディレクトリにファイルをコピー中..."
        FileUtils.cp(db_file, compressed_file)
      else
        puts "エラー: 圧縮データファイルが見つかりません"
        return
      end
    end
    
    begin
      require 'zlib'
      require 'json'
      
      # 現在のデータ数を確認
      current_count = Condition.count
      puts "現在のデータ数: #{current_count}"
      
      # 圧縮ファイルを展開
      puts "圧縮ファイルを読み込み中..."
      compressed_data = File.read(compressed_file)
      json_data = Zlib::Inflate.inflate(compressed_data)
      data = JSON.parse(json_data)
      
      colleges_data = data['data']
      total_count = colleges_data.size
      
      puts "インポート対象: #{total_count}校"
      puts "エクスポート日時: #{data['export_date']}"
      puts ""
      puts "インポート開始..."
      
      imported_count = 0
      updated_count = 0
      error_count = 0
      
      colleges_data.each_with_index do |college_data, index|
        begin
          # 短縮フィールド名を元に戻す
          full_data = {
            college: college_data['c'],
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
          
          # Major分野のデータも追加（存在する場合）
          if college_data['maj']
            full_data.merge!(college_data['maj'])
          end
          
          # 既存のレコードを確認
          existing_college = Condition.find_by(college: full_data[:college])
          
          if existing_college
            # 更新
            existing_college.update!(full_data)
            updated_count += 1
          else
            # 新規作成
            Condition.create!(full_data)
            imported_count += 1
          end
          
          if (index + 1) % 500 == 0
            puts "進捗: #{index + 1}/#{total_count} (#{((index + 1).to_f / total_count * 100).round(1)}%)"
          end
          
        rescue => e
          error_count += 1
          puts "エラー: #{college_data['c']} - #{e.message}" if error_count <= 10
        end
      end
      
      final_count = Condition.count
      
      puts ""
      puts "=== インポート完了 ==="
      puts "新規作成: #{imported_count}校"
      puts "更新: #{updated_count}校"
      puts "エラー: #{error_count}校"
      puts "最終データ数: #{final_count}校"
      
      # 一時ファイルを削除
      File.delete(compressed_file) if File.exist?(compressed_file)
      puts "一時ファイルを削除しました"
      
    rescue => e
      puts "インポートエラーが発生しました: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
  end
end