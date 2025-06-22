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
        ContactMailer.contact_form(name, email, category, message).deliver_now
        render json: { status: 'success', message: 'お問い合わせを受け付けました。' }
      rescue => e
        Rails.logger.error "メール送信エラー: #{e.message}"
        render json: { status: 'error', message: 'メール送信に失敗しました。' }
      end
    else
      render json: { status: 'error', message: 'すべての項目を入力してください。' }
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
end