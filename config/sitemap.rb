SitemapGenerator::Sitemap.default_host = "https://college-spark.com"

SitemapGenerator::Sitemap.create do
  # メインページ
  add root_path, priority: 1.0, changefreq: "daily"

  # 主要コンテンツページ
  add "/about", priority: 0.8, changefreq: "monthly"
  add "/knowledge", priority: 0.8, changefreq: "monthly"
  add "/degreeseeking", priority: 0.8, changefreq: "monthly"
  add "/why_study_abroad", priority: 0.9, changefreq: "monthly"
  add "/info", priority: 0.7, changefreq: "monthly"
  add "/recruit", priority: 0.7, changefreq: "monthly"
  add "/contact", priority: 0.6, changefreq: "monthly"
  add "/terms", priority: 0.5, changefreq: "yearly"

  # 検索機能
  add "/results", priority: 0.9, changefreq: "daily"

  # 認証ページ
  add "/login", priority: 0.6, changefreq: "monthly"
  add "/register", priority: 0.6, changefreq: "monthly"

  # ユーザー機能ページ
  add "/favorites", priority: 0.6, changefreq: "monthly"
  add "/compare", priority: 0.6, changefreq: "monthly"
  add "/profile", priority: 0.5, changefreq: "monthly"

  # 国別情報ページ
  add "/canada", priority: 0.7, changefreq: "monthly"
  add "/australia", priority: 0.7, changefreq: "monthly"
  add "/newzealand", priority: 0.7, changefreq: "monthly"

  # 特定大学の詳細ページ
  add "/ohio_northern_university", priority: 0.7, changefreq: "weekly"
  add "/ohio_state_university", priority: 0.7, changefreq: "weekly"
  add "/florida_state_university", priority: 0.7, changefreq: "weekly"
  add "/alabama_state_university", priority: 0.7, changefreq: "weekly"

  # 全大学ページを追加
  Condition.find_each do |college|
    add conditions_path(college), lastmod: college.updated_at, priority: 0.7, changefreq: "weekly"
  end
end
