require "test_helper"

class Admin::NewsControllerTest < ActionDispatch::IntegrationTest
  test "should get index or require authentication" do
    get admin_news_index_url
    # 認証なしの場合はリダイレクトまたは200（ログインページ表示）
    assert [200, 302].include?(response.status)
  end
end
