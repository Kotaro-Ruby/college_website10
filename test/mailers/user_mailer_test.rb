require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "password_reset" do
    user = users(:one)
    mail = UserMailer.password_reset(user)
    assert_equal "[College Spark] パスワードリセットのご案内", mail.subject
    assert_equal [ user.email ], mail.to
    assert_equal [ "collegespark2025@gmail.com" ], mail.from
    # Check that the email has content (not empty)
    assert mail.body.encoded.present?
  end
end
