class DebugController < ApplicationController
  def db_status
    begin
      # Database connection test
      ActiveRecord::Base.connection.execute("SELECT 1")
      db_connected = true
    rescue => e
      db_connected = false
      db_error = e.message
    end
    
    # Basic counts
    total_colleges = Condition.count rescue "ERROR"
    with_names = Condition.where.not(college: [nil, '']).count rescue "ERROR"
    with_comments = Condition.where.not(comment: [nil, '']).count rescue "ERROR"
    with_cities = Condition.where.not(city: [nil, '']).count rescue "ERROR"
    with_states = Condition.where.not(state: [nil, '']).count rescue "ERROR"
    with_majors = Condition.where('pcip_business > 0 OR pcip_engineering > 0 OR pcip_computer_science > 0').count rescue "ERROR"
    
    # Sample records
    sample_colleges = Condition.limit(5).pluck(:college, :city, :state) rescue ["ERROR"]
    
    # Check tables exist
    tables = ActiveRecord::Base.connection.tables rescue ["ERROR"]
    conditions_table_exists = tables.include?('conditions')
    
    # Check for Excel file
    excel_file_path = Rails.root.join('public', 'college_data.xlsx')
    excel_file_exists = File.exist?(excel_file_path)
    excel_file_size = excel_file_exists ? File.size(excel_file_path) : 0
    
    # Check for seed file
    seed_file_path = Rails.root.join('db', 'seeds.rb')
    seed_file_exists = File.exist?(seed_file_path)
    seed_file_size = seed_file_exists ? File.size(seed_file_path) : 0
    
    # Environment variables
    database_url = ENV['DATABASE_URL']
    api_key = ENV['COLLEGE_SCORECARD_API_KEY']
    
    render plain: <<~TEXT
      === データベース接続 ===
      接続状態: #{db_connected ? 'OK' : 'ERROR'}
      #{db_connected ? '' : "エラー: #{db_error}"}
      データベースURL: #{database_url ? 'あり' : 'なし'}
      
      === テーブル情報 ===
      全テーブル: #{tables.join(', ')}
      conditionsテーブル: #{conditions_table_exists ? '存在' : '存在しない'}
      
      === データ状況 ===
      総レコード数: #{total_colleges}
      大学名あり: #{with_names}
      都市名あり: #{with_cities}
      州名あり: #{with_states}
      コメントあり: #{with_comments}
      専攻データあり: #{with_majors}
      
      === サンプル大学 ===
      #{sample_colleges.is_a?(Array) ? sample_colleges.map { |name, city, state| "#{name} - #{city}, #{state}" }.join("\n") : sample_colleges}
      
      === ファイル状況 ===
      Excelファイル: #{excel_file_exists ? "存在 (#{excel_file_size} bytes)" : '存在しない'}
      シードファイル: #{seed_file_exists ? "存在 (#{seed_file_size} bytes)" : '存在しない'}
      
      === 環境情報 ===
      Rails環境: #{Rails.env}
      API Key: #{api_key ? '設定済み' : '未設定'}
      
      === Railsルート ===
      Root: #{Rails.root}
    TEXT
  end
  
  def manual_import
    if params[:secret] != 'import123'
      render plain: "アクセス拒否"
      return
    end
    
    begin
      # Manual Excel import
      require 'roo'
      
      file_path = Rails.root.join('public', 'college_data.xlsx')
      
      if File.exist?(file_path)
        xlsx = Roo::Spreadsheet.open(file_path)
        sheet = xlsx.sheet(0)
        headers = sheet.row(1).map(&:to_s).map(&:downcase).map(&:strip)
        
        imported = 0
        (2..sheet.last_row).each do |row_num|
          college_name = sheet.cell(row_num, headers.index('college') + 1) rescue nil
          next if college_name.blank?
          
          condition = Condition.find_or_initialize_by(college: college_name.to_s.strip)
          
          # Basic data mapping
          condition.city = sheet.cell(row_num, headers.index('city') + 1) rescue nil
          condition.state = sheet.cell(row_num, headers.index('state') + 1) rescue nil
          condition.privateorpublic = sheet.cell(row_num, headers.index('private or public') + 1) rescue nil
          condition.students = sheet.cell(row_num, headers.index('students') + 1).to_i rescue nil
          
          if condition.save
            imported += 1
          end
          
          break if imported >= 100  # Limit for safety
        end
        
        render plain: "手動インポート完了: #{imported}件の大学データを追加"
      else
        render plain: "Excelファイルが見つかりません"
      end
      
    rescue => e
      render plain: "エラー: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
    end
  end
end