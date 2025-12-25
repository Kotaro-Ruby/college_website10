require "test_helper"

class BlogsHelperTest < ActionView::TestCase
  # ===========================================
  # 基本的なマークダウン変換のテスト
  # ===========================================
  test "render_blog_content returns empty string for blank content" do
    assert_equal "", render_blog_content(nil)
    assert_equal "", render_blog_content("")
  end

  test "render_blog_content converts headings" do
    assert_includes render_blog_content("# Heading 1"), "<h3>Heading 1</h3>"
    assert_includes render_blog_content("## Heading 2"), "<h4>Heading 2</h4>"
    assert_includes render_blog_content("### Heading 3"), "<h5>Heading 3</h5>"
  end

  test "render_blog_content converts bold text" do
    result = render_blog_content("This is **bold** text")
    assert_includes result, "<strong>bold</strong>"
  end

  test "render_blog_content converts italic text" do
    result = render_blog_content("This is *italic* text")
    assert_includes result, "<em>italic</em>"
  end

  test "render_blog_content converts links" do
    result = render_blog_content("[Link Text](https://example.com)")
    assert_includes result, '<a href="https://example.com">Link Text</a>'
  end

  test "render_blog_content converts lists" do
    result = render_blog_content("- Item 1")
    assert_includes result, "<li>Item 1</li>"
    assert_includes result, "<ul>"
  end

  test "render_blog_content converts blockquotes" do
    result = render_blog_content("> This is a quote")
    assert_includes result, "<blockquote"
    assert_includes result, "This is a quote"
  end

  # ===========================================
  # ショートコードのテスト
  # ===========================================
  test "render_blog_content converts info shortcode" do
    result = render_blog_content("[info]Information[/info]")
    assert_includes result, 'class="info-box"'
    assert_includes result, "Information"
  end

  test "render_blog_content converts warning shortcode" do
    result = render_blog_content("[warning]Warning message[/warning]")
    assert_includes result, 'class="warning-box"'
    assert_includes result, "Warning message"
  end

  test "render_blog_content converts success shortcode" do
    result = render_blog_content("[success]Success![/success]")
    assert_includes result, 'class="success-box"'
  end

  test "render_blog_content converts highlight shortcode" do
    result = render_blog_content("[highlight]Highlighted[/highlight]")
    assert_includes result, 'class="highlight"'
  end

  test "render_blog_content converts button shortcode" do
    result = render_blog_content('[button url="https://example.com"]Click me[/button]')
    assert_includes result, 'href="https://example.com"'
    assert_includes result, 'class="cta-button"'
    assert_includes result, "Click me"
  end

  test "render_blog_content converts step shortcode" do
    result = render_blog_content('[step number="1"]First step[/step]')
    assert_includes result, 'class="step"'
    assert_includes result, 'class="step-number"'
    assert_includes result, "1"
  end

  # ===========================================
  # XSS対策のテスト
  # ===========================================
  test "render_blog_content sanitizes dangerous tags" do
    result = render_blog_content("<script>alert('xss')</script>")
    assert_not_includes result, "<script>"
    # sanitize removes tags but may leave text content
  end

  test "render_blog_content sanitizes dangerous attributes" do
    result = render_blog_content('<a href="javascript:alert()">Link</a>')
    # sanitize should remove javascript: hrefs
    assert_not_includes result, "javascript:"
  end
end
