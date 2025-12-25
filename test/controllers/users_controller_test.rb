require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  # ===========================================
  # ユーザー登録ページのテスト
  # ===========================================
  test "should get new" do
    get register_url
    assert_response :success
  end

  # ===========================================
  # ユーザー登録処理のテスト
  # ===========================================
  test "should create user with valid params" do
    assert_difference "User.count", 1 do
      post register_url, params: {
        user: {
          username: "newuser",
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_redirected_to root_url
  end

  test "should not create user with duplicate email" do
    initial_count = User.count
    post register_url, params: {
      user: {
        username: "anotheruser",
        email: @user.email,
        password: "password123",
        password_confirmation: "password123"
      }
    }
    # 重複メールの場合は登録失敗（カウントが変わらないか、エラーページ表示）
    assert User.count == initial_count || response.body.include?("error") || response.body.include?("既に")
  end

  # ===========================================
  # プロフィールページのテスト
  # ===========================================
  test "should redirect to login when accessing profile without login" do
    get profile_url
    assert_redirected_to login_path
  end

  test "should get profile when logged in" do
    login_as(@user)
    get profile_url
    assert_response :success
  end

  # ===========================================
  # プロフィール編集のテスト
  # ===========================================
  test "should get edit when logged in" do
    login_as(@user)
    get profile_edit_url
    assert_response :success
  end

  test "should update profile" do
    login_as(@user)
    patch profile_url, params: {
      user: {
        username: "updatedname",
        email: @user.email
      }
    }
    assert_redirected_to profile_url
    @user.reload
    assert_equal "updatedname", @user.username
  end

  # ===========================================
  # アカウント削除のテスト
  # ===========================================
  test "should destroy user account" do
    login_as(@user)
    assert_difference "User.count", -1 do
      delete profile_url
    end
    assert_redirected_to root_url
  end

  # ===========================================
  # ユーザー名チェックのテスト
  # ===========================================
  test "should check username availability" do
    post check_username_url, params: { username: "availableusername" }, as: :json
    json_response = JSON.parse(response.body)
    assert json_response["available"]
  end

  test "should return unavailable for existing username" do
    post check_username_url, params: { username: @user.username }, as: :json
    json_response = JSON.parse(response.body)
    assert_not json_response["available"]
  end

  private

  def login_as(user)
    post login_url, params: {
      email: user.email,
      password: "password123"
    }
  end
end
