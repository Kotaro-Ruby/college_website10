class ApplicationMailer < ActionMailer::Base
  default from: "College Spark <collegespark2025@gmail.com>"
  layout "mailer"

  # メール送信前の共通処理
  before_action :log_delivery_setup
  after_action :log_delivery_attempt

  private

  def log_delivery_setup
    # 本番環境でのメール送信設定確認
    if Rails.env.production?
      Rails.logger.info "=== EMAIL DELIVERY SETUP ==="
      Rails.logger.info "Gmail username present: #{ENV['GMAIL_USERNAME'].present?}"
      Rails.logger.info "Gmail app password present: #{ENV['GMAIL_APP_PASSWORD'].present?}"
      Rails.logger.info "Gmail username value: #{ENV['GMAIL_USERNAME']}" if ENV["GMAIL_USERNAME"].present?
    end
  end

  def log_delivery_attempt
    if mail
      Rails.logger.info "=== EMAIL DELIVERY ATTEMPT ==="
      Rails.logger.info "To: #{mail.to}"
      Rails.logger.info "Subject: #{mail.subject}"
      Rails.logger.info "From: #{mail.from}"
      Rails.logger.info "Delivery method: #{mail.delivery_method.class.name}"
    end
  end
end
