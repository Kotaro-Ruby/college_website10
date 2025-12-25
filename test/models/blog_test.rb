require "test_helper"

class BlogTest < ActiveSupport::TestCase
  # ===========================================
  # フィクスチャの読み込みテスト
  # ===========================================
  test "fixtures are loaded correctly" do
    assert_not_nil blogs(:published_blog)
    assert_not_nil blogs(:draft_blog)
    assert_not_nil blogs(:featured_blog)
  end

  # ===========================================
  # バリデーションのテスト
  # ===========================================
  test "valid blog with all required attributes" do
    blog = Blog.new(
      title: "Test Blog Post",
      content: "This is the content of the test blog post.",
      author: "Test Author",
      category: "留学体験記",
      slug: "test-blog-post-unique"
    )
    assert blog.valid?
  end

  test "invalid without title" do
    blog = Blog.new(content: "Content", author: "Author", category: "留学体験記", slug: "test")
    assert_not blog.valid?
    assert_includes blog.errors[:title], "can't be blank"
  end

  test "invalid without content" do
    blog = Blog.new(title: "Title", author: "Author", category: "留学体験記", slug: "test")
    assert_not blog.valid?
    assert_includes blog.errors[:content], "can't be blank"
  end

  test "invalid without author" do
    blog = Blog.new(title: "Title", content: "Content", category: "留学体験記", slug: "test")
    assert_not blog.valid?
    assert_includes blog.errors[:author], "can't be blank"
  end

  test "invalid without category" do
    blog = Blog.new(title: "Title", content: "Content", author: "Author", slug: "test")
    assert_not blog.valid?
    assert_includes blog.errors[:category], "can't be blank"
  end

  test "invalid with too long title" do
    blog = Blog.new(
      title: "a" * 201,
      content: "Content",
      author: "Author",
      category: "留学体験記",
      slug: "test"
    )
    assert_not blog.valid?
    assert_includes blog.errors[:title], "is too long (maximum is 200 characters)"
  end

  test "invalid with duplicate slug" do
    existing = blogs(:published_blog)
    blog = Blog.new(
      title: "Another Blog",
      content: "Content",
      author: "Author",
      category: "留学体験記",
      slug: existing.slug
    )
    assert_not blog.valid?
    assert_includes blog.errors[:slug], "has already been taken"
  end

  test "invalid with invalid slug format" do
    blog = Blog.new(
      title: "Test",
      content: "Content",
      author: "Author",
      category: "留学体験記",
      slug: "Invalid Slug With Spaces!"
    )
    assert_not blog.valid?
  end

  test "valid slug formats" do
    valid_slugs = ["test-slug", "test123", "a-b-c-123"]
    valid_slugs.each do |slug|
      blog = Blog.new(
        title: "Test",
        content: "Content",
        author: "Author",
        category: "留学体験記",
        slug: slug
      )
      assert blog.valid?, "#{slug} should be valid"
    end
  end

  # ===========================================
  # スラグ自動生成のテスト
  # ===========================================
  test "generates slug from title when slug is blank" do
    blog = Blog.new(
      title: "My Amazing Blog Post",
      content: "Content",
      author: "Author",
      category: "留学体験記"
    )
    blog.valid?
    assert_equal "my-amazing-blog-post", blog.slug
  end

  test "does not override existing slug" do
    blog = Blog.new(
      title: "My Amazing Blog Post",
      content: "Content",
      author: "Author",
      category: "留学体験記",
      slug: "custom-slug"
    )
    blog.valid?
    assert_equal "custom-slug", blog.slug
  end

  # ===========================================
  # 公開状態のテスト
  # ===========================================
  test "published? returns true for published blog" do
    blog = blogs(:published_blog)
    assert blog.published?
  end

  test "published? returns false for draft blog" do
    blog = blogs(:draft_blog)
    assert_not blog.published?
  end

  test "draft? returns true for draft blog" do
    blog = blogs(:draft_blog)
    assert blog.draft?
  end

  test "draft? returns false for published blog" do
    blog = blogs(:published_blog)
    assert_not blog.draft?
  end

  # ===========================================
  # スコープのテスト
  # ===========================================
  test "published scope returns only published blogs" do
    Blog.published.each do |blog|
      assert blog.published?
    end
  end

  test "draft scope returns only draft blogs" do
    Blog.draft.each do |blog|
      assert blog.draft?
    end
  end

  test "featured scope returns only featured blogs" do
    Blog.featured.each do |blog|
      assert blog.featured
    end
  end

  test "by_category scope filters by category" do
    category = "留学体験記"
    Blog.by_category(category).each do |blog|
      assert_equal category, blog.category
    end
  end

  test "recent scope orders by published_at desc" do
    blogs = Blog.published.recent.to_a
    blogs.each_cons(2) do |older, newer|
      assert older.published_at >= newer.published_at if older.published_at && newer.published_at
    end
  end

  # ===========================================
  # 定数のテスト
  # ===========================================
  test "CATEGORIES constant is defined" do
    assert_not_empty Blog::CATEGORIES
    assert_includes Blog::CATEGORIES, "留学体験記"
    assert_includes Blog::CATEGORIES, "大学レビュー"
  end

  test "TEMPLATES constant is defined" do
    assert_not_empty Blog::TEMPLATES
    assert Blog::TEMPLATES.key?("experience_story")
  end
end
