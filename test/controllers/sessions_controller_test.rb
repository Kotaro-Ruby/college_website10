require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  # ===========================================
  # ログインページのテスト
  # ===========================================
  test "should get login page" do
    get login_url
    assert_response :success
  end

  # ===========================================
  # ログイン処理のテスト
  # ===========================================
  test "should login with valid credentials" do
    post login_url, params: {
      email: @user.email,
      password: "password123"
    }
    # ログイン成功時はリダイレクト
    assert_redirected_to root_url
    assert_not_nil session[:user_id]
  end

  test "should not login with invalid password" do
    post login_url, params: {
      email: @user.email,
      password: "wrongpassword"
    }
    # ログイン失敗時は再度ログインページを表示
    assert_response :success
    assert_nil session[:user_id]
  end

  test "should not login with non-existent email" do
    post login_url, params: {
      email: "nonexistent@example.com",
      password: "password123"
    }
    # ログイン失敗時は再度ログインページを表示
    assert_response :success
    assert_nil session[:user_id]
  end

  # ===========================================
  # ログアウト処理のテスト
  # ===========================================
  test "should logout" do
    # まずログイン
    post login_url, params: {
      email: @user.email,
      password: "password123"
    }

    # ログアウト
    delete logout_url
    assert_redirected_to root_url
    assert_nil session[:user_id]
  end
end
