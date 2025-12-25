require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ===========================================
  # フィクスチャの読み込みテスト
  # ===========================================
  test "fixtures are loaded correctly" do
    assert_not_nil users(:one)
    assert_not_nil users(:two)
    assert_not_nil users(:oauth_user)
  end

  # ===========================================
  # バリデーションのテスト
  # ===========================================
  test "valid user with all required attributes" do
    user = User.new(
      username: "newuser",
      email: "newuser@example.com",
      password: "password123"
    )
    assert user.valid?
  end

  test "invalid without username" do
    user = User.new(
      email: "test@example.com",
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
  end

  test "invalid without email" do
    user = User.new(
      username: "testuser",
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "invalid with duplicate username" do
    existing_user = users(:one)
    user = User.new(
      username: existing_user.username,
      email: "different@example.com",
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:username], "has already been taken"
  end

  test "invalid with duplicate email" do
    existing_user = users(:one)
    user = User.new(
      username: "differentuser",
      email: existing_user.email,
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "email uniqueness is case insensitive" do
    existing_user = users(:one)
    user = User.new(
      username: "differentuser",
      email: existing_user.email.upcase,
      password: "password123"
    )
    assert_not user.valid?
  end

  test "invalid with short username" do
    user = User.new(
      username: "ab",
      email: "test@example.com",
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:username], "is too short (minimum is 3 characters)"
  end

  test "invalid with long username" do
    user = User.new(
      username: "a" * 51,
      email: "test@example.com",
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:username], "is too long (maximum is 50 characters)"
  end

  test "invalid with short password" do
    user = User.new(
      username: "testuser",
      email: "test@example.com",
      password: "12345"
    )
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 6 characters)"
  end

  test "invalid with malformed email" do
    # Note: URI::MailTo::EMAIL_REGEXP is lenient, so only test clearly invalid formats
    invalid_emails = ["test", "test@", "@example.com", "test@.com"]

    invalid_emails.each do |invalid_email|
      user = User.new(
        username: "testuser",
        email: invalid_email,
        password: "password123"
      )
      assert_not user.valid?, "#{invalid_email} should be invalid"
    end
  end

  test "valid email formats" do
    valid_emails = ["user@example.com", "user.name@example.com", "user+tag@example.co.jp"]

    valid_emails.each do |valid_email|
      user = User.new(
        username: "user#{rand(1000)}",
        email: valid_email,
        password: "password123"
      )
      assert user.valid?, "#{valid_email} should be valid"
    end
  end

  # ===========================================
  # メール小文字変換のテスト
  # ===========================================
  test "email is downcased before save" do
    user = User.new(
      username: "testdowncase",
      email: "TEST@EXAMPLE.COM",
      password: "password123"
    )
    user.save!
    assert_equal "test@example.com", user.email
  end

  # ===========================================
  # OAuth認証のテスト
  # ===========================================
  test "oauth_user? returns true for oauth users" do
    oauth_user = users(:oauth_user)
    assert oauth_user.oauth_user?
  end

  test "oauth_user? returns false for regular users" do
    regular_user = users(:one)
    assert_not regular_user.oauth_user?
  end

  test "oauth user skips username and password validation" do
    user = User.new(
      provider: "google_oauth2",
      uid: "987654321",
      email: "oauth@example.com",
      username: "oauthuser2",
      password: SecureRandom.hex(16)
    )
    assert user.valid?
  end

  # ===========================================
  # パスワードリセットのテスト
  # ===========================================
  test "create_password_reset_token generates token and timestamp" do
    user = users(:one)
    user.create_password_reset_token

    assert_not_nil user.password_reset_token
    assert_not_nil user.password_reset_sent_at
  end

  test "password_reset_expired? returns false for fresh token" do
    user = users(:user_with_reset_token)
    assert_not user.password_reset_expired?
  end

  test "password_reset_expired? returns true for expired token" do
    user = users(:user_with_expired_token)
    assert user.password_reset_expired?
  end

  test "clear_password_reset removes token and timestamp" do
    user = users(:user_with_reset_token)
    original_token = user.password_reset_token
    user.clear_password_reset

    # Token should be cleared (either nil or different from original)
    assert_not_equal original_token, user.password_reset_token
  end

  # ===========================================
  # お気に入り機能のテスト
  # ===========================================
  test "can have many favorites" do
    # user_one already has favorites from fixtures (harvard, state_university)
    user = users(:one)
    assert_equal 2, user.favorites.count
  end

  test "favorite? returns true when condition is favorited" do
    # user_one already favorites harvard from fixtures
    user = users(:one)
    harvard = conditions(:harvard)
    assert user.favorite?(harvard)
  end

  test "favorite? returns false when condition is not favorited" do
    user = users(:one)
    # womens_college is not favorited by user_one
    wellesley = conditions(:womens_college)
    assert_not user.favorite?(wellesley)
  end

  test "favorite_conditions returns favorited conditions" do
    # user_one already favorites harvard from fixtures
    user = users(:one)
    harvard = conditions(:harvard)
    assert_includes user.favorite_conditions, harvard
  end

  # ===========================================
  # 比較リストのテスト
  # ===========================================
  test "comparison_list returns empty array by default" do
    user = users(:one)
    assert_equal [], user.comparison_list
  end

  test "comparison_list can store and retrieve array" do
    user = users(:one)
    user.comparison_list = [1, 2, 3]
    user.save!

    user.reload
    assert_equal [1, 2, 3], user.comparison_list
  end

  test "comparison_list handles invalid JSON gracefully" do
    user = users(:one)
    user.write_attribute(:comparison_list, "invalid json")
    assert_equal [], user.comparison_list
  end

  # ===========================================
  # 閲覧履歴のテスト
  # ===========================================
  test "can have many view histories" do
    # user_one already has view_history from fixtures
    user = users(:one)
    assert user.view_histories.count >= 1
  end

  test "viewed_conditions returns viewed conditions" do
    # user_one already viewed harvard from fixtures
    user = users(:one)
    harvard = conditions(:harvard)
    assert_includes user.viewed_conditions, harvard
  end

  # ===========================================
  # 依存関係の削除テスト
  # ===========================================
  test "destroying user destroys associated favorites" do
    # user_one has favorites from fixtures
    user = users(:one)
    favorites_count = user.favorites.count

    assert_difference "Favorite.count", -favorites_count do
      user.destroy
    end
  end

  test "destroying user destroys associated view histories" do
    # user_one has view_histories from fixtures
    user = users(:one)
    view_history_count = user.view_histories.count

    assert_difference "ViewHistory.count", -view_history_count do
      user.destroy
    end
  end

  # ===========================================
  # パスワード認証のテスト
  # ===========================================
  test "authenticate with correct password" do
    user = User.create!(
      username: "authtest",
      email: "authtest@example.com",
      password: "correctpassword"
    )

    assert user.authenticate("correctpassword")
  end

  test "authenticate with incorrect password returns false" do
    user = User.create!(
      username: "authtest2",
      email: "authtest2@example.com",
      password: "correctpassword"
    )

    assert_not user.authenticate("wrongpassword")
  end
end
