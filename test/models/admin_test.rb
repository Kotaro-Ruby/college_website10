require "test_helper"

class AdminTest < ActiveSupport::TestCase
  # ===========================================
  # フィクスチャの読み込みテスト
  # ===========================================
  test "fixtures are loaded correctly" do
    assert_not_nil admins(:super_admin)
    assert_not_nil admins(:regular_admin)
  end

  # ===========================================
  # バリデーションのテスト
  # ===========================================
  test "valid admin with all required attributes" do
    admin = Admin.new(
      username: "newadmin123",
      email: "newadmin123@example.com",
      password: "password123",
      role: "admin"
    )
    assert admin.valid?
  end

  test "invalid without username" do
    admin = Admin.new(email: "test@example.com", password: "password123", role: "admin")
    assert_not admin.valid?
    assert_includes admin.errors[:username], "can't be blank"
  end

  test "invalid without email" do
    admin = Admin.new(username: "testadmin", password: "password123", role: "admin")
    assert_not admin.valid?
    assert_includes admin.errors[:email], "can't be blank"
  end

  test "invalid with short username" do
    admin = Admin.new(username: "ab", email: "test@example.com", password: "password123", role: "admin")
    assert_not admin.valid?
    assert_includes admin.errors[:username], "is too short (minimum is 3 characters)"
  end

  test "invalid with long username" do
    admin = Admin.new(username: "a" * 31, email: "test@example.com", password: "password123", role: "admin")
    assert_not admin.valid?
    assert_includes admin.errors[:username], "is too long (maximum is 30 characters)"
  end

  test "invalid with short password" do
    admin = Admin.new(username: "testadmin", email: "test@example.com", password: "short", role: "admin")
    assert_not admin.valid?
    assert_includes admin.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "invalid with duplicate username" do
    existing = admins(:super_admin)
    admin = Admin.new(username: existing.username, email: "different@example.com", password: "password123", role: "admin")
    assert_not admin.valid?
    assert_includes admin.errors[:username], "has already been taken"
  end

  test "invalid with duplicate email" do
    existing = admins(:super_admin)
    admin = Admin.new(username: "differentadmin", email: existing.email, password: "password123", role: "admin")
    assert_not admin.valid?
    assert_includes admin.errors[:email], "has already been taken"
  end

  test "invalid with invalid role" do
    admin = Admin.new(username: "testadmin", email: "test@example.com", password: "password123", role: "invalid_role")
    assert_not admin.valid?
    assert_includes admin.errors[:role], "無効な権限です"
  end

  test "valid roles" do
    %w[admin super_admin].each do |role|
      admin = Admin.new(
        username: "testadmin#{role}",
        email: "test#{role}@example.com",
        password: "password123",
        role: role
      )
      assert admin.valid?, "#{role} should be valid"
    end
  end

  # ===========================================
  # メール小文字変換のテスト
  # ===========================================
  test "email is downcased before save" do
    admin = Admin.new(
      username: "testdowncase",
      email: "TEST@EXAMPLE.COM",
      password: "password123",
      role: "admin"
    )
    admin.save!
    assert_equal "test@example.com", admin.email
  end

  # ===========================================
  # 権限メソッドのテスト
  # ===========================================
  test "super_admin? returns true for super_admin" do
    admin = admins(:super_admin)
    assert admin.super_admin?
  end

  test "super_admin? returns false for regular admin" do
    admin = admins(:regular_admin)
    assert_not admin.super_admin?
  end

  test "admin? returns true for super_admin" do
    admin = admins(:super_admin)
    assert admin.admin?
  end

  test "admin? returns true for regular admin" do
    admin = admins(:regular_admin)
    assert admin.admin?
  end

  # ===========================================
  # セッショントークンのテスト
  # ===========================================
  test "generates session token on create" do
    admin = Admin.create!(
      username: "tokentest",
      email: "tokentest@example.com",
      password: "password123",
      role: "admin"
    )
    assert_not_nil admin.session_token
  end

  test "regenerate_session_token! changes token" do
    admin = admins(:super_admin)
    old_token = admin.session_token
    admin.regenerate_session_token!
    assert_not_equal old_token, admin.session_token
  end

  # ===========================================
  # ログイン関連のテスト
  # ===========================================
  test "record_sign_in! updates last_sign_in_at and regenerates token" do
    admin = admins(:regular_admin)
    old_token = admin.session_token
    old_sign_in = admin.last_sign_in_at

    admin.record_sign_in!

    assert_not_equal old_token, admin.session_token
    assert admin.last_sign_in_at > old_sign_in if old_sign_in
  end

  # ===========================================
  # クラスメソッドのテスト
  # ===========================================
  test "create_initial_admin creates super_admin" do
    admin = Admin.create_initial_admin("initialadmin", "initial@example.com", "password123")
    assert_not_nil admin
    assert_equal "super_admin", admin.role
  end

  test "create_initial_admin returns nil on invalid data" do
    admin = Admin.create_initial_admin("ab", "invalid", "short")
    assert_nil admin
  end

  test "exists_admin? returns true when admins exist" do
    assert Admin.exists_admin?
  end

  # ===========================================
  # パスワード認証のテスト
  # ===========================================
  test "authenticate with correct password" do
    admin = Admin.create!(
      username: "authtest",
      email: "authtest@example.com",
      password: "correctpassword",
      role: "admin"
    )
    assert admin.authenticate("correctpassword")
  end

  test "authenticate with incorrect password returns false" do
    admin = Admin.create!(
      username: "authtest2",
      email: "authtest2@example.com",
      password: "correctpassword",
      role: "admin"
    )
    assert_not admin.authenticate("wrongpassword")
  end
end
