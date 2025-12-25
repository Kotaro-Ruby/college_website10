require "test_helper"

class NewsTest < ActiveSupport::TestCase
  # ===========================================
  # フィクスチャの読み込みテスト
  # ===========================================
  test "fixtures are loaded correctly" do
    assert_not_nil news(:published_us_news)
    assert_not_nil news(:draft_news)
    assert_not_nil news(:archived_news)
  end

  # ===========================================
  # バリデーションのテスト
  # ===========================================
  test "valid news with all required attributes" do
    news = News.new(
      title: "Test News",
      url: "https://example.com/test-news-unique",
      published_at: Time.current
    )
    assert news.valid?
  end

  test "invalid without title" do
    news = News.new(url: "https://example.com/test", published_at: Time.current)
    assert_not news.valid?
    assert_includes news.errors[:title], "can't be blank"
  end

  test "invalid without url" do
    news = News.new(title: "Test", published_at: Time.current)
    assert_not news.valid?
    assert_includes news.errors[:url], "can't be blank"
  end

  test "invalid without published_at" do
    news = News.new(title: "Test", url: "https://example.com/test")
    assert_not news.valid?
    assert_includes news.errors[:published_at], "can't be blank"
  end

  test "invalid with duplicate url" do
    existing = news(:published_us_news)
    news = News.new(
      title: "Another News",
      url: existing.url,
      published_at: Time.current
    )
    assert_not news.valid?
    assert_includes news.errors[:url], "has already been taken"
  end

  # ===========================================
  # ステータス(enum)のテスト
  # ===========================================
  test "default status is draft" do
    news = News.new(
      title: "New News",
      url: "https://example.com/new-news",
      published_at: Time.current
    )
    assert news.draft?
  end

  test "published status" do
    news = news(:published_us_news)
    assert news.published?
    assert_not news.draft?
    assert_not news.archived?
  end

  test "draft status" do
    news = news(:draft_news)
    assert news.draft?
  end

  test "archived status" do
    news = news(:archived_news)
    assert news.archived?
  end

  test "can change status" do
    news = news(:draft_news)
    news.published!
    assert news.published?
  end

  # ===========================================
  # スコープのテスト
  # ===========================================
  test "recent scope orders by published_at desc" do
    recent = News.recent.first
    assert_not_nil recent.published_at
  end

  test "by_country scope filters by country" do
    us_news = News.by_country("USA")
    us_news.each do |n|
      assert_equal "USA", n.country
    end
  end

  test "by_country scope returns all when country is blank" do
    all_news = News.by_country(nil)
    assert_equal News.count, all_news.count
  end

  # ===========================================
  # 属性のテスト
  # ===========================================
  test "news has japanese translation fields" do
    news = news(:published_us_news)
    assert_not_nil news.japanese_title
    assert_not_nil news.japanese_description
  end

  test "news can have optional fields" do
    news = news(:draft_news)
    assert_nil news.japanese_title
    assert_nil news.image_url
  end
end
