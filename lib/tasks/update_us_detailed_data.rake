namespace :import do
  desc "Update US universities with detailed data (demographics, test scores, earnings)"
  task update_detailed_data: :environment do
    puts "=== アメリカ大学の詳細データ更新 ==="
    
    compressed_file = Rails.root.join('db', 'college_data_compressed.json.gz')
    
    unless File.exist?(compressed_file)
      puts "エラー: 圧縮データファイルが見つかりません"
      puts "ファイル: #{compressed_file}"
      return
    end
    
    begin
      require 'zlib'
      require 'json'
      
      # 現在のデータ数を確認
      current_count = Condition.count
      puts "現在のデータ数: #{current_count}"
      
      # 詳細データがある大学の数を確認
      with_demographics = Condition.where.not(percent_white: nil).count
      with_test_scores = Condition.where.not(sat_math_25: nil).count
      with_earnings = Condition.where.not(earnings_6yr_median: nil).count
      
      puts "現在の詳細データ:"
      puts "  人口統計データあり: #{with_demographics}"
      puts "  テストスコアあり: #{with_test_scores}"
      puts "  収入データあり: #{with_earnings}"
      puts ""
      
      # 圧縮ファイルを展開
      puts "圧縮ファイルを読み込み中..."
      compressed_data = File.read(compressed_file)
      json_data = Zlib::Inflate.inflate(compressed_data)
      data = JSON.parse(json_data)
      
      colleges_data = data['data']
      total_count = colleges_data.size
      
      puts "データソース: #{total_count}校"
      puts "更新開始..."
      
      updated_count = 0
      skipped_count = 0
      error_count = 0
      
      # バッチ処理
      batch_size = 100
      
      colleges_data.each_slice(batch_size).with_index do |batch, batch_index|
        batch.each do |college_data|
          begin
            # 大学名で既存レコードを検索
            college_name = college_data['c']
            existing = Condition.find_by(college: college_name)
            
            if existing
              update_data = {}
              
              # 詳細データ (add) を追加
              if college_data['add']
                update_data.merge!(college_data['add'])
              end
              
              # 専攻データ (maj) を追加
              if college_data['maj']
                update_data.merge!(college_data['maj'])
              end
              
              # データがある場合のみ更新
              if update_data.any?
                existing.update!(update_data)
                updated_count += 1
              else
                skipped_count += 1
              end
            else
              skipped_count += 1
            end
            
          rescue => e
            error_count += 1
            puts "エラー: #{college_data['c']} - #{e.message}" if error_count <= 10
          end
        end
        
        # 進捗表示
        processed = (batch_index + 1) * batch_size
        percentage = [(processed.to_f / total_count * 100).round(1), 100.0].min
        puts "進捗: #{[processed, total_count].min}/#{total_count} (#{percentage}%)"
        
        # メモリ管理
        if (batch_index + 1) % 10 == 0
          GC.start
        end
      end
      
      # 更新後の状態を確認
      after_demographics = Condition.where.not(percent_white: nil).count
      after_test_scores = Condition.where.not(sat_math_25: nil).count
      after_earnings = Condition.where.not(earnings_6yr_median: nil).count
      
      puts ""
      puts "=== 更新完了 ==="
      puts "更新: #{updated_count}校"
      puts "スキップ: #{skipped_count}校"
      puts "エラー: #{error_count}校"
      puts ""
      puts "詳細データ (更新後):"
      puts "  人口統計データ: #{with_demographics} → #{after_demographics}"
      puts "  テストスコア: #{with_test_scores} → #{after_test_scores}"
      puts "  収入データ: #{with_earnings} → #{after_earnings}"
      
    rescue => e
      puts "エラーが発生しました: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
  end
end