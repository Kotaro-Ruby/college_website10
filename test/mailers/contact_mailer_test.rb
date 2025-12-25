require "test_helper"

class ContactMailerTest < ActionMailer::TestCase
  test "contact_form with general question" do
    mail = ContactMailer.contact_form(
      "Test User",
      "test@example.com",
      "general-question",
      "This is a test message"
    )

    assert_equal "[College Spark] 一般的なご質問 - Test User様より", mail.subject
    assert_equal ["collegespark2025@gmail.com"], mail.to
    assert_equal ["collegespark2025@gmail.com"], mail.from
    assert_includes mail.reply_to.first, "test@example.com"
    assert mail.body.encoded.present?
  end

  test "contact_form with site bug report" do
    mail = ContactMailer.contact_form(
      "Bug Reporter",
      "bug@example.com",
      "site-bug",
      "Found a bug on the search page"
    )

    assert_equal "[College Spark] サイトの不具合報告 - Bug Reporter様より", mail.subject
    assert_equal ["collegespark2025@gmail.com"], mail.to
  end

  test "contact_form with data error" do
    mail = ContactMailer.contact_form(
      "Data User",
      "data@example.com",
      "data-error",
      "Wrong tuition data"
    )

    assert_equal "[College Spark] データの間違い - Data User様より", mail.subject
  end

  test "contact_form with feature request" do
    mail = ContactMailer.contact_form(
      "Feature User",
      "feature@example.com",
      "feature-request",
      "Please add dark mode"
    )

    assert_equal "[College Spark] 新機能のご要望 - Feature User様より", mail.subject
  end

  test "contact_form with other category" do
    mail = ContactMailer.contact_form(
      "Other User",
      "other@example.com",
      "other",
      "Other inquiry"
    )

    assert_equal "[College Spark] その他 - Other User様より", mail.subject
  end

  test "contact_form delivers email" do
    assert_emails 1 do
      ContactMailer.contact_form(
        "Test User",
        "test@example.com",
        "general-question",
        "Test message"
      ).deliver_now
    end
  end
end
