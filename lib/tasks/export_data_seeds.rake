namespace :data do
  desc "Export comments and major data to seeds file"
  task export_to_seeds: :environment do
    puts "既存データをシードファイルに出力中..."
    
    # コメントデータの出力
    comments_data = []
    major_data = []
    
    Condition.where.not(comment: [nil, '']).find_each do |college|
      comments_data << {
        college: college.college,
        comment: college.comment
      }
    end
    
    # 専攻データの出力
    major_fields = [
      :pcip_agriculture, :pcip_natural_resources, :pcip_communication,
      :pcip_computer_science, :pcip_education, :pcip_engineering,
      :pcip_foreign_languages, :pcip_english, :pcip_biology,
      :pcip_mathematics, :pcip_psychology, :pcip_sociology,
      :pcip_social_sciences, :pcip_visual_arts, :pcip_business,
      :pcip_health_professions, :pcip_history, :pcip_philosophy,
      :pcip_physical_sciences, :pcip_law
    ]
    
    Condition.where('pcip_business > 0 OR pcip_engineering > 0 OR pcip_computer_science > 0').find_each do |college|
      major_record = { college: college.college }
      
      major_fields.each do |field|
        value = college.send(field)
        major_record[field] = value if value && value > 0
      end
      
      major_data << major_record if major_record.keys.length > 1
    end
    
    # シードファイルの生成
    seed_content = <<~RUBY
      # Auto-generated seed file
      # Generated at: #{Time.current}
      
      puts "コメントデータの追加開始..."
      
      comments_data = #{comments_data.inspect}
      
      comments_data.each do |data|
        college = Condition.find_by(college: data[:college])
        if college && college.comment.blank?
          college.update(comment: data[:comment])
        end
      end
      
      puts "#{comments_data.length}件のコメントデータを処理しました"
      
      puts "専攻データの追加開始..."
      
      major_data = #{major_data.inspect}
      
      major_data.each do |data|
        college_name = data.delete(:college)
        college = Condition.find_by(college: college_name)
        if college
          college.update(data)
        end
      end
      
      puts "#{major_data.length}件の専攻データを処理しました"
      
      puts "シードデータの追加完了！"
    RUBY
    
    # ファイルに書き出し
    File.write(Rails.root.join('db/seeds.rb'), seed_content)
    
    puts "シードファイルが生成されました: db/seeds.rb"
    puts "コメントデータ: #{comments_data.length}件"
    puts "専攻データ: #{major_data.length}件"
    puts ""
    puts "本番環境では 'rails db:seed' で読み込まれます"
  end
end