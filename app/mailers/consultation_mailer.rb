class ConsultationMailer < ApplicationMailer
  default from: "College Spark <collegespark2025@gmail.com>"

  def new_consultation_notification(consultation)
    @consultation = consultation
    mail(
      to: "collegespark2025@gmail.com",
      subject: "[College Spark] 新しい無料相談予約 - #{@consultation.name}さん"
    )
  end

  def confirmation_to_user(consultation)
    @consultation = consultation
    mail(
      to: @consultation.email,
      subject: "[College Spark] 無料相談のご予約確認"
    )
  end
end
