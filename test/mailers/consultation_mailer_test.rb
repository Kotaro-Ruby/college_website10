require "test_helper"

class ConsultationMailerTest < ActionMailer::TestCase
  setup do
    @consultation = consultations(:pending_consultation)
  end

  test "new_consultation_notification" do
    mail = ConsultationMailer.new_consultation_notification(@consultation)

    assert_equal "[College Spark] 新しい無料相談予約 - #{@consultation.name}さん", mail.subject
    assert_equal ["collegespark2025@gmail.com"], mail.to
    assert_equal ["collegespark2025@gmail.com"], mail.from
    assert mail.body.encoded.present?
  end

  test "confirmation_to_user" do
    skip "Template not implemented yet"
  end

  test "new_consultation_notification delivers email" do
    assert_emails 1 do
      ConsultationMailer.new_consultation_notification(@consultation).deliver_now
    end
  end

  test "confirmation_to_user delivers email" do
    skip "Template not implemented yet"
  end
end
