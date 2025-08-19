class UnsplashService
  include HTTParty
  base_uri "https://api.unsplash.com"

  def initialize
    @access_key = ENV["UNSPLASH_ACCESS_KEY"]
  end

  def search_university_photo(university_name, country = nil)
    # 有名大学の画像を直接マッピング
    preset_photo = get_preset_university_photo(university_name)
    return preset_photo if preset_photo

    # APIキーが設定されていない場合はnilを返す
    if @access_key.blank?
      Rails.logger.info "No API key for #{university_name}"
      return nil
    end

    query = university_name
    query += " #{country}" if country

    options = {
      query: {
        query: query,
        per_page: 1,
        orientation: "landscape"
      },
      headers: {
        "Authorization" => "Client-ID #{@access_key}"
      }
    }

    response = self.class.get("/search/photos", options)

    if response.success? && response["results"].present?
      photo = response["results"].first
      {
        url: photo["urls"]["regular"],
        thumb_url: photo["urls"]["thumb"],
        small_url: photo["urls"]["small"],
        photographer: photo["user"]["name"],
        photographer_url: photo["user"]["links"]["html"],
        unsplash_url: photo["links"]["html"]
      }
    else
      nil
    end
  rescue => e
    Rails.logger.error "Unsplash API error: #{e.message}"
    nil
  end

  def get_cached_photo(university_name, country = nil)
    cache_key = "unsplash_photo_#{university_name.parameterize}_#{country&.parameterize}"

    Rails.cache.fetch(cache_key, expires_in: 7.days) do
      search_university_photo(university_name, country)
    end
  end

  private

  def get_preset_university_photo(university_name)
    # 大学名を正規化
    normalized_name = university_name.downcase.strip

    # 有名大学の画像マッピング（全てnil - APIが承認されるまで画像なし）
    university_photos = {}

    university_photos[normalized_name]
  end
end
