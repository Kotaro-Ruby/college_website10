require 'net/http'
require 'json'

class CountryApiService
  BASE_URL = 'https://restcountries.com/v3.1'
  TARGET_COUNTRIES = ['US', 'AU', 'NZ', 'CA'].freeze
  
  def self.fetch_and_update_countries
    new.fetch_and_update_countries
  end
  
  def fetch_and_update_countries
    countries_data = fetch_countries_data
    return false if countries_data.nil?
    
    countries_data.each do |country_data|
      update_or_create_country(country_data)
    end
    
    true
  rescue => e
    Rails.logger.error "Error updating countries: #{e.message}"
    false
  end
  
  private
  
  def fetch_countries_data
    codes = TARGET_COUNTRIES.join(',')
    uri = URI("#{BASE_URL}/alpha?codes=#{codes}")
    
    response = Net::HTTP.get_response(uri)
    return nil unless response.code == '200'
    
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "API fetch error: #{e.message}"
    nil
  end
  
  def update_or_create_country(data)
    code = data.dig('cca2')
    return if code.blank?
    
    country = Country.find_or_initialize_by(code: code)
    
    # 基本情報
    country.assign_attributes(
      name: data.dig('name', 'common'),
      official_name: data.dig('name', 'official'),
      capital: data.dig('capital')&.first,
      currency_code: data.dig('currencies')&.keys&.first,
      currency_name: data.dig('currencies')&.values&.first&.dig('name'),
      currency_symbol: data.dig('currencies')&.values&.first&.dig('symbol'),
      languages: data.dig('languages') || {},
      population: data.dig('population'),
      flag_emoji: data.dig('flag'),
      timezones: data.dig('timezones') || [],
      
      # 地理情報
      area: data.dig('area'),
      landlocked: data.dig('landlocked'),
      borders: data.dig('borders') || [],
      alt_spellings: data.dig('altSpellings') || [],
      region: data.dig('region'),
      subregion: data.dig('subregion'),
      country_latlng: data.dig('latlng') || [],
      capital_latlng: data.dig('capitalInfo', 'latlng') || [],
      
      # 国際関係
      un_member: data.dig('unMember'),
      independent: data.dig('independent'),
      status: data.dig('status'),
      
      # 経済・社会
      gini_coefficient: data.dig('gini')&.values&.first,
      gini_year: data.dig('gini')&.keys&.first&.to_i,
      
      # 交通
      car_signs: data.dig('car', 'signs') || [],
      car_side: data.dig('car', 'side'),
      
      # その他
      start_of_week: data.dig('startOfWeek'),
      fifa_code: data.dig('fifa'),
      postal_code_format: data.dig('postalCode', 'format'),
      postal_code_regex: data.dig('postalCode', 'regex'),
      
      # 画像・マップ
      coat_of_arms_png: data.dig('coatOfArms', 'png'),
      coat_of_arms_svg: data.dig('coatOfArms', 'svg'),
      flag_png: data.dig('flags', 'png'),
      flag_svg: data.dig('flags', 'svg'),
      flag_alt: data.dig('flags', 'alt'),
      maps_google: data.dig('maps', 'googleMaps'),
      maps_openstreetmap: data.dig('maps', 'openStreetMaps'),
      
      # 複雑なデータ
      demonyms: data.dig('demonyms') || {},
      translations: data.dig('translations') || {},
      tld: data.dig('tld') || [],
      idd_root: data.dig('idd', 'root'),
      idd_suffixes: data.dig('idd', 'suffixes') || []
    )
    
    country.save!
  end
end