require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "password_reset" do
    user = users(:one)
    mail = UserMailer.password_reset(user)
    assert_equal "Password reset", mail.subject
    assert_equal [ user.email ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
