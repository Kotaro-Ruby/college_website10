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
      
      # 大量データを効率的に処理するためバッチ処理を使用
      batch_size = 500
      
      colleges_data.each_slice(batch_size).with_index do |batch, batch_index|
        batch_records = []
        
        batch.each do |college_data|
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
            
            # 詳細データを追加（存在する場合）
            if college_data['add']
              full_data.merge!(college_data['add'])
            end
            
            # 専攻データを追加（存在する場合）
            if college_data['maj']
              full_data.merge!(college_data['maj'])
            end
            
            batch_records << full_data
            
          rescue => e
            error_count += 1
            puts "エラー: #{college_data['c']} - #{e.message}" if error_count <= 10
          end
        end
        
        # バッチで一括処理（upsert使用）
        if batch_records.any?
          begin
            # PostgreSQLのupsertを使用して効率的に処理
            batch_records.each do |record|
              existing_college = Condition.find_by(college: record[:college])
              
              if existing_college
                existing_college.update!(record)
                updated_count += 1
              else
                Condition.create!(record)
                imported_count += 1
              end
            end
            
            processed = (batch_index + 1) * batch_size
            percentage = [(processed.to_f / total_count * 100).round(1), 100.0].min
            puts "進捗: #{[processed, total_count].min}/#{total_count} (#{percentage}%)"
            
            # メモリ使用量を抑えるため、定期的にGCを実行
            if (batch_index + 1) % 10 == 0
              GC.start
            end
            
          rescue => e
            puts "バッチ処理エラー: #{e.message}"
            error_count += batch_records.size
          end
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