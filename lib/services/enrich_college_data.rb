# データ処理用スクリプト - 開発環境でのみ実行
# 本番環境では何も実行しません

unless Rails.env.development?
  Rails.logger.info "Data enrichment script skipped in #{Rails.env} environment"
  return
end

# 開発環境でのみ以下のコードが実行される
require 'roo'
require 'csv'
require 'json'
require 'net/http'
require 'uri'

puts "Development environment detected - data enrichment script is available"