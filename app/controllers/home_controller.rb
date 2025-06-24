class HomeController < ApplicationController
  # 特定のアクションでカスタムレイアウトを使用
  layout 'country_layout', only: [:canada, :australia, :newzealand]
  
  def top
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
        mail = ContactMailer.contact_form(name, email, category, message)
        mail.deliver_now
        
        # お問い合わせ内容をファイルに記録
        save_contact_to_file(name, email, category, message)
        
        # 開発環境では詳細情報をログに出力
        if Rails.env.development?
          Rails.logger.info "=" * 50
          Rails.logger.info "お問い合わせメール送信成功"
          Rails.logger.info "送信者: #{name} (#{email})"
          Rails.logger.info "カテゴリー: #{category}"
          Rails.logger.info "メッセージ: #{message}"
          Rails.logger.info "宛先: kotaro.swifty@gmail.com"
          Rails.logger.info "件名: [College Spark] お問い合わせ: #{category}"
          Rails.logger.info "=" * 50
        else
          Rails.logger.info "お問い合わせメール送信成功: #{name} (#{email})"
        end
        
        render json: { status: 'success', message: 'お問い合わせを受け付けました。' }
      rescue => e
        Rails.logger.error "メール送信エラー: #{e.class.name} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # 開発環境では詳細なエラーを、本番環境では汎用メッセージを返す
        error_message = Rails.env.development? ? "エラー詳細: #{e.message}" : 'メール送信に失敗しました。しばらく後でもう一度お試しください。'
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
  
  def terms
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