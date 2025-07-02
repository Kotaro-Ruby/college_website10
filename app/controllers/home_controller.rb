class HomeController < ApplicationController
  # 特定のアクションでカスタムレイアウトを使用
  layout 'country_layout', only: [:canada, :australia, :newzealand]
  
  def top
    # Force no cache for this page during development only
    if Rails.env.development?
      response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
      response.headers['Pragma'] = 'no-cache'
      response.headers['Expires'] = '0'
    end
  end
  
  def index
    # セッションクリア（テスト用）
    clear_recently_viewed_for_testing
    
    # 人気大学のデータを取得（例：学生数が多い、または合格率が適度な大学）
    @popular_colleges = Condition.where.not(students: nil, acceptance_rate: nil)
                                .where('acceptance_rate > 0.1 AND acceptance_rate < 0.8')
                                .order(students: :desc)
                                .limit(5)
  end
  
  def search
  end
  
  def about
  end
  
  def knowledge
  end
  
  def degreeseeking
  end
  
  def info
  end
  
  def recruit
  end
  
  def contact
  end

  def send_contact
    name = params[:name]
    email = params[:email]
    category = params[:category]
    message = params[:message]

    if name.present? && email.present? && category.present? && message.present?
      begin
        # メール送信
        mail = ContactMailer.contact_form(name, email, category, message)
        mail.deliver_now
        
        # お問い合わせ内容をファイルに記録（バックアップとして）
        save_contact_to_file(name, email, category, message)
        
        # ログ出力
        Rails.logger.info "=" * 50
        Rails.logger.info "お問い合わせメール送信成功"
        Rails.logger.info "送信者: #{name} (#{email})"
        Rails.logger.info "カテゴリー: #{category}"
        Rails.logger.info "宛先: kotaro.swifty@gmail.com"
        Rails.logger.info "送信時刻: #{Time.current}"
        Rails.logger.info "=" * 50
        
        render json: { 
          status: 'success', 
          message: 'お問い合わせを受け付けました。ご連絡いただきありがとうございます。' 
        }
        
      rescue Net::SMTPAuthenticationError => e
        Rails.logger.error "SMTP認証エラー: #{e.message}"
        save_contact_to_file(name, email, category, message) # ファイルには保存
        render json: { 
          status: 'error', 
          message: 'メール送信に問題が発生しました。お問い合わせ内容は記録されました。' 
        }
        
      rescue Net::TimeoutError => e
        Rails.logger.error "メール送信タイムアウト: #{e.message}"
        save_contact_to_file(name, email, category, message) # ファイルには保存
        render json: { 
          status: 'error', 
          message: 'メール送信がタイムアウトしました。お問い合わせ内容は記録されました。' 
        }
        
      rescue => e
        Rails.logger.error "メール送信エラー: #{e.class.name} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        save_contact_to_file(name, email, category, message) # ファイルには保存
        
        error_message = Rails.env.development? ? 
          "エラー詳細: #{e.message}" : 
          'メール送信に失敗しましたが、お問い合わせ内容は記録されました。'
          
        render json: { status: 'error', message: error_message }
      end
    else
      missing_fields = []
      missing_fields << '名前' unless name.present?
      missing_fields << 'メールアドレス' unless email.present?
      missing_fields << 'カテゴリー' unless category.present?
      missing_fields << 'メッセージ' unless message.present?
      
      render json: { status: 'error', message: "以下の項目を入力してください: #{missing_fields.join(', ')}" }
    end
  end
  
  def canada
  end
  
  def australia
  end
  
  def newzealand
  end
  
  def study_abroad_types
  end
  
  def scholarships
  end
  
  def visa_guide
  end
  
  def english_tests
  end
  
  def majors_careers
  end
  
  def life_guide
  end
  
  def terms
  end
  
  def why_study_abroad
  end

  private

  def save_contact_to_file(name, email, category, message)
    require 'csv'
    
    # ファイルのパスを設定
    contacts_dir = Rails.root.join('storage', 'contacts')
    FileUtils.mkdir_p(contacts_dir) unless Dir.exist?(contacts_dir)
    
    csv_file = contacts_dir.join('contact_submissions.csv')
    txt_file = contacts_dir.join('contact_submissions.txt')
    
    # 現在の日時
    timestamp = Time.current.strftime('%Y-%m-%d %H:%M:%S')
    
    # CSVファイルに記録
    CSV.open(csv_file, 'a', encoding: 'UTF-8') do |csv|
      # ヘッダーを追加（ファイルが新規作成の場合）
      if File.size(csv_file) == 0
        csv << ['日時', '名前', 'メールアドレス', 'カテゴリー', 'メッセージ']
      end
      csv << [timestamp, name, email, category, message]
    end
    
    # テキストファイルに記録（人間が読みやすい形式）
    File.open(txt_file, 'a', encoding: 'UTF-8') do |file|
      file.puts "=" * 80
      file.puts "お問い合わせ受信: #{timestamp}"
      file.puts "=" * 80
      file.puts "名前: #{name}"
      file.puts "メールアドレス: #{email}"
      file.puts "カテゴリー: #{category}"
      file.puts "メッセージ:"
      file.puts message
      file.puts "=" * 80
      file.puts ""
    end
    
    Rails.logger.info "お問い合わせ内容をファイルに保存しました: #{csv_file}"
  rescue => e
    Rails.logger.error "ファイル保存エラー: #{e.message}"
  end
end