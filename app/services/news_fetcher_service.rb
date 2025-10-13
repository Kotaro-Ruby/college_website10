require "feedjira"
require "open-uri"

class NewsFetcherService
  # Google News RSS URL構築
  def self.build_google_news_url(query, language: "en", country: "US")
    base_url = "https://news.google.com/rss/search"
    params = {
      q: query,
      hl: language,
      gl: country,
      ceid: "#{country}:#{language}"
    }
    query_string = params.map { |k, v| "#{k}=#{URI.encode_www_form_component(v)}" }.join("&")
    "#{base_url}?#{query_string}"
  end

  # RSSフィードからニュースを取得
  def self.fetch_news(query, country: "USA", limit: 20)
    url = build_google_news_url(query)

    begin
      xml = URI.open(url).read
      feed = Feedjira.parse(xml)

      return [] unless feed&.entries

      entries = feed.entries.first(limit).map do |entry|
        {
          title: entry.title,
          url: entry.url,
          description: entry.summary || entry.title,
          published_at: entry.published,
          source: extract_source(entry),
          image_url: extract_image(entry),
          country: country
        }
      end

      entries
    rescue StandardError => e
      Rails.logger.error "RSS取得エラー: #{e.message}"
      []
    end
  end

  # 複数のキーワードでニュースを取得
  def self.fetch_study_abroad_news
    queries = {
      "USA" => "study abroad USA OR international students USA OR student visa USA",
      "Australia" => "study abroad Australia OR international students Australia",
      "Canada" => "study abroad Canada OR international students Canada",
      "New Zealand" => "study abroad New Zealand OR international students New Zealand"
    }

    all_news = []

    queries.each do |country, query|
      news = fetch_news(query, country: country, limit: 10)
      all_news.concat(news)
    end

    all_news
  end

  # ニュースをDBに保存（重複チェック付き）
  def self.save_to_database(news_items)
    saved_count = 0

    news_items.each do |item|
      next if News.exists?(url: item[:url])

      news = News.new(item)
      if news.save
        saved_count += 1
        Rails.logger.info "ニュース保存: #{news.title}"
      else
        Rails.logger.error "ニュース保存失敗: #{news.errors.full_messages.join(', ')}"
      end
    end

    saved_count
  end

  # ワンストップ実行
  def self.fetch_and_save
    news_items = fetch_study_abroad_news
    saved_count = save_to_database(news_items)

    {
      fetched: news_items.count,
      saved: saved_count,
      skipped: news_items.count - saved_count
    }
  end

  private

  # ニュースソースを抽出
  def self.extract_source(entry)
    # Google Newsの場合、タイトルに「- ソース名」が含まれることが多い
    if entry.title.include?(" - ")
      entry.title.split(" - ").last
    else
      entry.author || "Google News"
    end
  end

  # 画像URLを抽出（可能な場合）
  def self.extract_image(entry)
    # enclosureやmedia contentから画像を探す
    if entry.respond_to?(:enclosure_url) && entry.enclosure_url
      entry.enclosure_url
    elsif entry.respond_to?(:image) && entry.image
      entry.image
    else
      nil
    end
  end
end
