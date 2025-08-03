class ApplicationMailer < ActionMailer::Base
  default from: "College Spark <collegespark2025@gmail.com>"
  layout "mailer"
  
  # メール送信前の共通処理
  before_action :set_delivery_options
  
  private
  
  def set_delivery_options
    # 本番環境での送信信頼性を向上
    if Rails.env.production?
      mail.delivery_method.settings.merge!(
        open_timeout: 10,
        read_timeout: 10
      )
    end
  end
end
