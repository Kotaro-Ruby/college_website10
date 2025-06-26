SitemapGenerator::Sitemap.default_host = 'https://college-spark.onrender.com'

SitemapGenerator::Sitemap.create do
  # メインページ
  add root_path, priority: 1.0, changefreq: 'daily'
  
  # 重要なページ
  add about_path, priority: 0.8, changefreq: 'monthly' if respond_to?(:about_path)
  add knowledge_path, priority: 0.8, changefreq: 'monthly' if respond_to?(:knowledge_path)
  add degreeseeking_path, priority: 0.8, changefreq: 'monthly' if respond_to?(:degreeseeking_path)
  add info_path, priority: 0.7, changefreq: 'monthly' if respond_to?(:info_path)
  add contact_path, priority: 0.6, changefreq: 'monthly' if respond_to?(:contact_path)
  
  # 検索結果ページ
  add '/results', priority: 0.9, changefreq: 'daily'
  
  # 全大学ページを追加
  Condition.find_each do |college|
    add conditions_path(college), lastmod: college.updated_at, priority: 0.7, changefreq: 'weekly'
  end
end