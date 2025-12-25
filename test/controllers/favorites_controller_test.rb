require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @condition = conditions(:harvard)
  end

  # ===========================================
  # 認証テスト
  # ===========================================
  test "should redirect to login when not authenticated for index" do
    get favorites_url
    assert_redirected_to login_path
  end

  test "should require login for create" do
    post favorites_url, params: { condition_id: @condition.id }, as: :json
    # ログインしていない場合はエラーまたはリダイレクト
    assert response.body.include?("error") || response.redirect?
  end

  # ===========================================
  # お気に入り一覧のテスト
  # ===========================================
  test "should get index when logged in" do
    login_as(@user)
    get favorites_url
    assert_response :success
  end

  # ===========================================
  # お気に入り追加のテスト
  # ===========================================
  test "should create favorite when logged in" do
    login_as(@user)

    # 既存のお気に入りを削除
    @user.favorites.where(condition: @condition).destroy_all

    assert_difference "Favorite.count", 1 do
      post favorites_url, params: { condition_id: @condition.id }, as: :json
    end

    json_response = JSON.parse(response.body)
    assert_equal "success", json_response["status"]
    assert json_response["favorited"]
  end

  test "should not create duplicate favorite" do
    login_as(@user)

    # 一度お気に入りに追加
    @user.favorites.find_or_create_by(condition: @condition)

    assert_no_difference "Favorite.count" do
      post favorites_url, params: { condition_id: @condition.id }, as: :json
    end

    json_response = JSON.parse(response.body)
    assert_equal "error", json_response["status"]
  end

  # ===========================================
  # お気に入り削除のテスト
  # ===========================================
  test "should destroy favorite when logged in" do
    login_as(@user)

    # お気に入りを追加
    @user.favorites.find_or_create_by(condition: @condition)

    assert_difference "Favorite.count", -1 do
      delete favorites_url, params: { condition_id: @condition.id }, as: :json
    end

    json_response = JSON.parse(response.body)
    assert_equal "success", json_response["status"]
    assert_not json_response["favorited"]
  end

  private

  def login_as(user)
    post login_url, params: {
      email: user.email,
      password: "password123"
    }
  end
end
