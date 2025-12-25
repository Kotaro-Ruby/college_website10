require "test_helper"

class ConsultationTest < ActiveSupport::TestCase
  # ===========================================
  # フィクスチャの読み込みテスト
  # ===========================================
  test "fixtures are loaded correctly" do
    assert_not_nil consultations(:pending_consultation)
    assert_not_nil consultations(:confirmed_consultation)
    assert_not_nil consultations(:completed_consultation)
    assert_not_nil consultations(:cancelled_consultation)
  end

  # ===========================================
  # バリデーションのテスト
  # ===========================================
  test "valid consultation with all required attributes" do
    consultation = Consultation.new(
      name: "テスト太郎",
      email: "test@example.com",
      phone: "090-1234-5678",
      preferred_date: Date.tomorrow,
      preferred_time: "14:00",
      timezone: "Asia/Tokyo",
      consultation_type: "general",
      message: "相談内容です"
    )
    assert consultation.valid?
  end

  test "invalid without name" do
    consultation = Consultation.new(
      email: "test@example.com",
      phone: "090-1234-5678",
      preferred_date: Date.tomorrow,
      preferred_time: "14:00",
      timezone: "Asia/Tokyo",
      consultation_type: "general",
      message: "相談内容"
    )
    assert_not consultation.valid?
    assert_includes consultation.errors[:name], "can't be blank"
  end

  test "invalid without email" do
    consultation = Consultation.new(
      name: "テスト",
      phone: "090-1234-5678",
      preferred_date: Date.tomorrow,
      preferred_time: "14:00",
      timezone: "Asia/Tokyo",
      consultation_type: "general",
      message: "相談内容"
    )
    assert_not consultation.valid?
    assert_includes consultation.errors[:email], "can't be blank"
  end

  test "invalid with malformed email" do
    consultation = Consultation.new(
      name: "テスト",
      email: "invalid-email",
      phone: "090-1234-5678",
      preferred_date: Date.tomorrow,
      preferred_time: "14:00",
      timezone: "Asia/Tokyo",
      consultation_type: "general",
      message: "相談内容"
    )
    assert_not consultation.valid?
  end

  test "invalid without phone" do
    consultation = Consultation.new(
      name: "テスト",
      email: "test@example.com",
      preferred_date: Date.tomorrow,
      preferred_time: "14:00",
      timezone: "Asia/Tokyo",
      consultation_type: "general",
      message: "相談内容"
    )
    assert_not consultation.valid?
    assert_includes consultation.errors[:phone], "can't be blank"
  end

  test "invalid with invalid consultation_type" do
    consultation = Consultation.new(
      name: "テスト",
      email: "test@example.com",
      phone: "090-1234-5678",
      preferred_date: Date.tomorrow,
      preferred_time: "14:00",
      timezone: "Asia/Tokyo",
      consultation_type: "invalid_type",
      message: "相談内容"
    )
    assert_not consultation.valid?
    assert_includes consultation.errors[:consultation_type], "is not included in the list"
  end

  test "valid consultation types" do
    valid_types = %w[general university_selection application_support scholarship visa other]
    valid_types.each do |type|
      consultation = Consultation.new(
        name: "テスト",
        email: "test@example.com",
        phone: "090-1234-5678",
        preferred_date: Date.tomorrow,
        preferred_time: "14:00",
        timezone: "Asia/Tokyo",
        consultation_type: type,
        message: "相談内容"
      )
      assert consultation.valid?, "#{type} should be valid"
    end
  end

  # ===========================================
  # スコープのテスト
  # ===========================================
  test "pending scope returns pending consultations" do
    Consultation.pending.each do |c|
      assert_equal "pending", c.status
    end
  end

  test "confirmed scope returns confirmed consultations" do
    Consultation.confirmed.each do |c|
      assert_equal "confirmed", c.status
    end
  end

  test "completed scope returns completed consultations" do
    Consultation.completed.each do |c|
      assert_equal "completed", c.status
    end
  end

  test "cancelled scope returns cancelled consultations" do
    Consultation.cancelled.each do |c|
      assert_equal "cancelled", c.status
    end
  end

  test "upcoming scope returns future consultations" do
    Consultation.upcoming.each do |c|
      assert c.preferred_date >= Date.today
    end
  end

  # ===========================================
  # 表示メソッドのテスト
  # ===========================================
  test "consultation_type_display returns japanese name" do
    consultation = consultations(:pending_consultation)
    assert_equal "大学留学全般", consultation.consultation_type_display
  end

  test "consultation_type_display for university_selection" do
    consultation = consultations(:confirmed_consultation)
    assert_equal "大学選び", consultation.consultation_type_display
  end

  test "status_display returns japanese status" do
    assert_equal "予約確認中", consultations(:pending_consultation).status_display
    assert_equal "予約確定", consultations(:confirmed_consultation).status_display
    assert_equal "相談完了", consultations(:completed_consultation).status_display
    assert_equal "キャンセル", consultations(:cancelled_consultation).status_display
  end

  # ===========================================
  # 日時候補のテスト
  # ===========================================
  test "datetime_candidates_list returns empty array when nil" do
    consultation = consultations(:pending_consultation)
    assert_equal [], consultation.datetime_candidates_list
  end

  test "datetime_candidates_list parses JSON correctly" do
    consultation = Consultation.new(
      datetime_candidates: '[{"date": "2025-01-01", "time": "10:00"}]'
    )
    candidates = consultation.datetime_candidates_list
    assert_equal 1, candidates.size
    assert_equal "2025-01-01", candidates.first["date"]
  end

  test "datetime_candidates_list handles invalid JSON" do
    consultation = Consultation.new(datetime_candidates: "invalid json")
    assert_equal [], consultation.datetime_candidates_list
  end

  test "datetime_candidates_display returns formatted string" do
    consultation = consultations(:pending_consultation)
    display = consultation.datetime_candidates_display
    assert_includes display, consultation.preferred_time
  end
end
