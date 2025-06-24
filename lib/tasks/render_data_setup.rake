namespace :render do
  desc "Setup data for Render deployment - run this manually after deployment"
  task setup_data: :environment do
    puts "=== Render用データセットアップ開始 ==="
    
    # 0. 基本大学データの確認・作成
    total_colleges = Condition.count
    if total_colleges < 50
      puts "基本大学データが不足しています。サンプルデータを作成中..."
      sample_colleges = [
        {college: 'Harvard University', state: 'Massachusetts', tuition: 54000, students: 22000, privateorpublic: 'Private', 
         GPA: 3.9, acceptance_rate: 5.0, graduation_rate: 98.0, city: 'Cambridge', Division: 'I'},
        {college: 'Stanford University', state: 'California', tuition: 56000, students: 17000, privateorpublic: 'Private',
         GPA: 3.8, acceptance_rate: 4.3, graduation_rate: 97.0, city: 'Stanford', Division: 'I'},
        {college: 'MIT', state: 'Massachusetts', tuition: 53000, students: 11500, privateorpublic: 'Private',
         GPA: 3.9, acceptance_rate: 6.7, graduation_rate: 96.0, city: 'Cambridge', Division: 'III'},
        {college: 'University of California-Berkeley', state: 'California', tuition: 43000, students: 45000, privateorpublic: 'Public',
         GPA: 3.7, acceptance_rate: 16.8, graduation_rate: 92.0, city: 'Berkeley', Division: 'I'},
        {college: 'Yale University', state: 'Connecticut', tuition: 59000, students: 13500, privateorpublic: 'Private',
         GPA: 3.9, acceptance_rate: 6.5, graduation_rate: 97.0, city: 'New Haven', Division: 'I'},
        {college: 'Princeton University', state: 'New Jersey', tuition: 56000, students: 5400, privateorpublic: 'Private',
         GPA: 3.9, acceptance_rate: 5.8, graduation_rate: 97.0, city: 'Princeton', Division: 'I'},
        {college: 'Columbia University', state: 'New York', tuition: 61000, students: 31000, privateorpublic: 'Private',
         GPA: 3.8, acceptance_rate: 6.1, graduation_rate: 95.0, city: 'New York', Division: 'I'},
        {college: 'University of Chicago', state: 'Illinois', tuition: 59000, students: 17000, privateorpublic: 'Private',
         GPA: 3.8, acceptance_rate: 7.4, graduation_rate: 95.0, city: 'Chicago', Division: 'III'},
        {college: 'University of Pennsylvania', state: 'Pennsylvania', tuition: 58000, students: 25000, privateorpublic: 'Private',
         GPA: 3.8, acceptance_rate: 8.4, graduation_rate: 96.0, city: 'Philadelphia', Division: 'I'},
        {college: 'University of Michigan-Ann Arbor', state: 'Michigan', tuition: 51000, students: 48000, privateorpublic: 'Public',
         GPA: 3.7, acceptance_rate: 23.0, graduation_rate: 93.0, city: 'Ann Arbor', Division: 'I'},
        {college: 'Ohio State University', state: 'Ohio', tuition: 32000, students: 65000, privateorpublic: 'Public',
         GPA: 3.6, acceptance_rate: 54.0, graduation_rate: 84.0, city: 'Columbus', Division: 'I'},
        {college: 'University of Texas at Austin', state: 'Texas', tuition: 40000, students: 51000, privateorpublic: 'Public',
         GPA: 3.7, acceptance_rate: 32.0, graduation_rate: 87.0, city: 'Austin', Division: 'I'},
        {college: 'University of Florida', state: 'Florida', tuition: 28000, students: 52000, privateorpublic: 'Public',
         GPA: 3.6, acceptance_rate: 30.0, graduation_rate: 90.0, city: 'Gainesville', Division: 'I'},
        {college: 'New York University', state: 'New York', tuition: 58000, students: 51000, privateorpublic: 'Private',
         GPA: 3.7, acceptance_rate: 16.0, graduation_rate: 85.0, city: 'New York', Division: 'I'},
        {college: 'Boston University', state: 'Massachusetts', tuition: 58000, students: 35000, privateorpublic: 'Private',
         GPA: 3.7, acceptance_rate: 19.0, graduation_rate: 87.0, city: 'Boston', Division: 'I'}
      ]
      
      created_count = 0
      sample_colleges.each do |college_data|
        unless Condition.find_by(college: college_data[:college])
          Condition.create!(college_data)
          created_count += 1
        end
      end
      puts "✓ #{created_count}校の基本大学データを作成しました"
      total_colleges = Condition.count
    end

    # 1. 基本統計の確認
    colleges_with_tuition = Condition.where.not(tuition: [nil, 0]).count
    colleges_with_comments = Condition.where.not(comment: [nil, '']).count
    colleges_with_majors = Condition.where('pcip_business > 0 OR pcip_engineering > 0 OR pcip_computer_science > 0').count
    
    puts "現在のデータ状況:"
    puts "  総大学数: #{total_colleges}"
    puts "  授業料データ: #{colleges_with_tuition} (#{(colleges_with_tuition.to_f / total_colleges * 100).round(1)}%)"
    puts "  コメントデータ: #{colleges_with_comments} (#{(colleges_with_comments.to_f / total_colleges * 100).round(1)}%)"
    puts "  専攻データ: #{colleges_with_majors} (#{(colleges_with_majors.to_f / total_colleges * 100).round(1)}%)"
    
    # 2. 環境変数の確認
    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    puts "\nCollege Scorecard API Key: #{api_key ? '設定済み' : '未設定'}"
    
    if api_key.nil?
      puts "⚠️  College Scorecard API Keyが設定されていません"
      puts "   Render環境変数でCOLLEGE_SCORECARD_API_KEY=eFbenl6AhOp1FYATeuHHTa4nXQZYsRi7w3JNxcBl を設定してください"
    end
    
    # 3. コメント追加（高速）
    if colleges_with_comments < total_colleges * 0.5
      puts "\n=== コメント追加開始 ==="
      require_relative '../college_comment_generator'
      
      comment_count = 0
      Condition.where(comment: [nil, '']).limit(1000).find_each do |college|
        comment_data = {
          students: college.students,
          acceptance_rate: college.acceptance_rate,
          ownership: college.privateorpublic,
          school_type: college.school_type
        }
        
        comment = CollegeCommentGenerator.generate_comment_for_college(college.college, comment_data)
        college.update(comment: comment)
        comment_count += 1
        
        if comment_count % 100 == 0
          puts "  コメント追加進捗: #{comment_count}"
        end
      end
      puts "  ✓ #{comment_count}件のコメントを追加しました"
    else
      puts "\n✓ コメントは既に十分追加されています"
    end
    
    # 4. 授業料データ追加（APIを使用）
    if api_key && colleges_with_tuition < total_colleges * 0.3
      puts "\n=== 授業料データ追加開始 ==="
      require 'net/http'
      require 'json'
      
      tuition_count = 0
      Condition.where(tuition: [nil, 0]).limit(200).find_each.with_index do |college, index|
        begin
          # College Scorecard APIから授業料データを取得
          uri = URI('https://api.data.gov/ed/collegescorecard/v1/schools.json')
          
          params = {
            'api_key' => api_key,
            'school.name' => college.college,
            '_fields' => 'school.name,latest.cost.avg_net_price.overall,latest.cost.tuition.out_of_state,latest.cost.tuition.in_state',
            '_per_page' => 1
          }
          
          uri.query = URI.encode_www_form(params)
          
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          request = Net::HTTP::Get.new(uri)
          
          response = http.request(request)
          
          if response.code == '200'
            data = JSON.parse(response.body)
            schools = data['results']
            
            if schools && !schools.empty?
              school = schools.first
              
              tuition = school['latest.cost.avg_net_price.overall'] ||
                       school['latest.cost.tuition.out_of_state'] ||
                       school['latest.cost.tuition.in_state']
              
              if tuition && tuition > 0
                college.update(tuition: tuition)
                tuition_count += 1
                puts "  ✓ #{college.college}: $#{tuition.to_i}"
              end
            end
          end
          
          sleep(0.1) # API制限対策
          
        rescue => e
          puts "  × #{college.college}: #{e.message}"
        end
        
        if (index + 1) % 50 == 0
          puts "  授業料データ進捗: #{index + 1}/200"
        end
      end
      puts "  ✓ #{tuition_count}件の授業料データを追加しました"
    else
      puts "\n✓ 授業料データは既に十分追加されているか、API Keyが未設定です"
    end
    
    # 5. 専攻データ追加（限定的）
    if api_key && colleges_with_majors < total_colleges * 0.1
      puts "\n=== 専攻データ追加開始（50校限定）==="
      require_relative '../college_major_importer'
      
      major_count = 0
      Condition.where('pcip_business IS NULL OR pcip_business = 0').limit(50).find_each.with_index do |college, index|
        puts "  #{index + 1}/50: #{college.college}"
        
        if CollegeMajorImporter.fetch_and_update_major_data(college.college, api_key)
          major_count += 1
          puts "    ✓ 成功"
        else
          puts "    × 失敗"
        end
        
        sleep(0.2) # API制限対策
      end
      puts "  ✓ #{major_count}件の専攻データを追加しました"
    else
      puts "\n✓ 専攻データは既に十分追加されているか、API Keyが未設定です"
    end
    
    # 6. 最終統計
    puts "\n=== 最終統計 ==="
    final_total = Condition.count
    final_tuition = Condition.where.not(tuition: [nil, 0]).count
    final_comments = Condition.where.not(comment: [nil, '']).count
    final_majors = Condition.where('pcip_business > 0 OR pcip_engineering > 0 OR pcip_computer_science > 0').count
    
    puts "  総大学数: #{final_total}"
    puts "  授業料データ: #{final_tuition} (#{(final_tuition.to_f / final_total * 100).round(1)}%)"
    puts "  コメントデータ: #{final_comments} (#{(final_comments.to_f / final_total * 100).round(1)}%)"
    puts "  専攻データ: #{final_majors} (#{(final_majors.to_f / final_total * 100).round(1)}%)"
    
    puts "\n=== セットアップ完了 ==="
    puts "ブラウザでページを再読み込みして確認してください。"
  end
  
  desc "Quick setup - comments only"
  task quick_setup: :environment do
    puts "=== 高速セットアップ（コメントのみ）==="
    
    require_relative '../college_comment_generator'
    
    total = Condition.where(comment: [nil, '']).count
    puts "コメント追加対象: #{total}校"
    
    count = 0
    Condition.where(comment: [nil, '']).find_each do |college|
      comment_data = {
        students: college.students,
        acceptance_rate: college.acceptance_rate,
        ownership: college.privateorpublic,
        school_type: college.school_type
      }
      
      comment = CollegeCommentGenerator.generate_comment_for_college(college.college, comment_data)
      college.update(comment: comment)
      count += 1
      
      if count % 500 == 0
        puts "進捗: #{count}/#{total}"
      end
    end
    
    puts "✓ #{count}件のコメントを追加しました"
    puts "現在のコメント数: #{Condition.where.not(comment: [nil, '']).count}校"
  end
end