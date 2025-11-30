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

  # 留学ガイドページ（SEO強化済み）
  add "/study_abroad_types", priority: 0.9, changefreq: "weekly"
  add "/scholarships", priority: 0.9, changefreq: "weekly"
  add "/visa_guide", priority: 0.9, changefreq: "weekly"
  add "/english_tests", priority: 0.9, changefreq: "weekly"
  add "/majors_careers", priority: 0.9, changefreq: "weekly"
  add "/life_guide", priority: 0.9, changefreq: "weekly"
  add "/ivy-league", priority: 0.9, changefreq: "weekly"
  
  # ブログ・コラム
  add "/blogs", priority: 0.7, changefreq: "weekly"
  add "/columns", priority: 0.7, changefreq: "weekly"

  # 検索機能
  add "/search", priority: 0.8, changefreq: "monthly"
  add "/results", priority: 0.9, changefreq: "daily"
  add "/top", priority: 0.7, changefreq: "monthly"
  add "/rankings", priority: 0.9, changefreq: "weekly"

  # 州別ガイド
  add "/states", priority: 0.7, changefreq: "monthly"

  # 認証ページ
  add "/login", priority: 0.6, changefreq: "monthly"
  add "/register", priority: 0.6, changefreq: "monthly"

  # ユーザー機能ページ
  add "/favorites", priority: 0.6, changefreq: "monthly"
  add "/compare", priority: 0.6, changefreq: "monthly"
  add "/profile", priority: 0.5, changefreq: "monthly"
  add "/profile/edit", priority: 0.5, changefreq: "monthly"
  
  # 相談・お問い合わせ
  add "/consultations/new", priority: 0.9, changefreq: "monthly"

  # 国別情報ページ
  add "/canada", priority: 0.7, changefreq: "monthly"
  add "/australia", priority: 0.7, changefreq: "monthly"
  add "/newzealand", priority: 0.7, changefreq: "monthly"
  
  # アメリカ大学ページ
  add "/us", priority: 0.8, changefreq: "weekly"
  add "/us/about", priority: 0.7, changefreq: "monthly"
  add "/us/universities", priority: 0.8, changefreq: "weekly"
  add "/us/universities/search", priority: 0.7, changefreq: "daily"
  
  # オーストラリア大学ページ
  add "/au", priority: 0.8, changefreq: "weekly"
  add "/au/universities", priority: 0.8, changefreq: "weekly"
  add "/au/universities/top", priority: 0.8, changefreq: "weekly"
  add "/au/about", priority: 0.7, changefreq: "monthly"
  add "/au/group-of-eight", priority: 0.8, changefreq: "monthly"
  add "/au/popular-cities", priority: 0.7, changefreq: "monthly"
  add "/au/scholarships", priority: 0.8, changefreq: "monthly"
  add "/au/universities/search", priority: 0.7, changefreq: "daily"
  
  # ニュージーランド大学ページ
  add "/nz", priority: 0.8, changefreq: "weekly"
  add "/nz/universities", priority: 0.8, changefreq: "weekly"
  add "/nz/about", priority: 0.7, changefreq: "monthly"
  add "/nz/universities/search", priority: 0.7, changefreq: "daily"
  
  # カナダ大学ページ
  add "/ca", priority: 0.8, changefreq: "weekly"
  add "/ca/universities", priority: 0.8, changefreq: "weekly"
  add "/ca/about", priority: 0.7, changefreq: "monthly"
  add "/ca/universities/search", priority: 0.7, changefreq: "daily"

  # 全大学ページを追加（日本語名がある大学は優先度高め）
  Condition.includes(:university_translations).find_each do |college|
    has_japanese_name = college.university_translations.exists?(locale: 'ja')
    priority = has_japanese_name ? 0.8 : 0.6
    add conditions_path(college), lastmod: college.updated_at, priority: priority, changefreq: "weekly"
  end
end
