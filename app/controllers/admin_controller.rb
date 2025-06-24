class AdminController < ApplicationController
  # 一時的なセットアップ用コントローラー
  # セットアップ完了後は削除してください
  
  def setup_data
    # セキュリティのため、特定のパラメータでのみ実行
    if params[:secret] != 'setup123'
      render plain: "アクセス拒否"
      return
    end
    
    begin
      require_relative '../../lib/college_comment_generator'
      
      # 現在の状況を確認
      total_colleges = Condition.count
      colleges_with_comments = Condition.where.not(comment: [nil, '']).count
      colleges_with_tuition = Condition.where.not(tuition: [nil, 0]).count
      
      result = []
      result << "=== セットアップ開始 ==="
      result << "総大学数: #{total_colleges}"
      result << "コメント付き: #{colleges_with_comments}"
      result << "授業料データ付き: #{colleges_with_tuition}"
      result << ""
      
      # 基本大学データの作成（大学数が少ない場合）
      if total_colleges < 20
        result << "=== 基本大学データ作成中 ==="
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
        
        result << "✓ #{created_count}校の基本大学データを作成しました"
        total_colleges = Condition.count
        result << "新しい総大学数: #{total_colleges}"
        result << ""
      else
        result << "✓ 基本大学データは十分あります（#{total_colleges}校）"
        result << ""
      end
      
      # コメント追加
      if colleges_with_comments < total_colleges
        result << "=== コメント追加中 ==="
        comment_count = 0
        
        Condition.where(comment: [nil, '']).limit(2000).find_each do |college|
          comment_data = {
            students: college.students,
            acceptance_rate: college.acceptance_rate,
            ownership: college.privateorpublic,
            school_type: college.school_type
          }
          
          comment = CollegeCommentGenerator.generate_comment_for_college(college.college, comment_data)
          college.update(comment: comment)
          comment_count += 1
          
          if comment_count % 200 == 0
            result << "進捗: #{comment_count}件"
          end
        end
        
        result << "✓ #{comment_count}件のコメントを追加しました"
      else
        result << "✓ コメントは既に追加済みです"
      end
      
      # 授業料データ追加（APIキーがある場合）
      api_key = ENV['COLLEGE_SCORECARD_API_KEY']
      if api_key && colleges_with_tuition < total_colleges * 0.5
        result << ""
        result << "=== 授業料データ追加中（100校限定）==="
        
        tuition_count = 0
        Condition.where(tuition: [nil, 0]).limit(100).find_each.with_index do |college, index|
          begin
            require 'net/http'
            require 'json'
            
            uri = URI('https://api.data.gov/ed/collegescorecard/v1/schools.json')
            
            params = {
              'api_key' => api_key,
              'school.name' => college.college,
              '_fields' => 'school.name,latest.cost.avg_net_price.overall,latest.cost.tuition.out_of_state',
              '_per_page' => 1
            }
            
            uri.query = URI.encode_www_form(params)
            
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.read_timeout = 10
            request = Net::HTTP::Get.new(uri)
            
            response = http.request(request)
            
            if response.code == '200'
              data = JSON.parse(response.body)
              schools = data['results']
              
              if schools && !schools.empty?
                school = schools.first
                tuition = school['latest.cost.avg_net_price.overall'] || school['latest.cost.tuition.out_of_state']
                
                if tuition && tuition > 0
                  college.update(tuition: tuition)
                  tuition_count += 1
                end
              end
            end
            
            sleep(0.1) if (index + 1) % 10 == 0  # API制限対策
            
          rescue => e
            result << "× #{college.college}: #{e.message}"
          end
          
          if (index + 1) % 25 == 0
            result << "授業料進捗: #{index + 1}/100"
          end
        end
        
        result << "✓ #{tuition_count}件の授業料データを追加しました"
      else
        result << "✓ 授業料データはスキップしました（API Key未設定または既に追加済み）"
      end
      
      # 最終結果
      final_comments = Condition.where.not(comment: [nil, '']).count
      final_tuition = Condition.where.not(tuition: [nil, 0]).count
      
      result << ""
      result << "=== セットアップ完了 ==="
      result << "コメント付き大学: #{final_comments}/#{total_colleges} (#{(final_comments.to_f / total_colleges * 100).round(1)}%)"
      result << "授業料データ付き大学: #{final_tuition}/#{total_colleges} (#{(final_tuition.to_f / total_colleges * 100).round(1)}%)"
      result << ""
      result << "ブラウザでページを再読み込みして確認してください。"
      result << "セットアップ完了後は、このadmin_controller.rbとルートを削除してください。"
      
      render plain: result.join("\n")
      
    rescue => e
      render plain: "エラーが発生しました: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    end
  end
  
  def status
    if params[:secret] != 'setup123'
      render plain: "アクセス拒否"
      return
    end
    
    total = Condition.count
    comments = Condition.where.not(comment: [nil, '']).count
    tuition = Condition.where.not(tuition: [nil, 0]).count
    majors = Condition.where('pcip_business > 0 OR pcip_engineering > 0 OR pcip_computer_science > 0').count
    
    result = []
    result << "=== データベース状況 ==="
    result << "総大学数: #{total}"
    result << "コメント付き: #{comments} (#{(comments.to_f / total * 100).round(1)}%)"
    result << "授業料データ付き: #{tuition} (#{(tuition.to_f / total * 100).round(1)}%)"
    result << "専攻データ付き: #{majors} (#{(majors.to_f / total * 100).round(1)}%)"
    result << ""
    result << "API Key設定: #{ENV['COLLEGE_SCORECARD_API_KEY'] ? '設定済み' : '未設定'}"
    
    render plain: result.join("\n")
  end
end