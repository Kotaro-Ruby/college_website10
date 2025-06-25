require 'net/http'
require 'json'
require 'uri'

namespace :college_data do
  desc "Check if special designation data is available in API"
  task check_special_data: :environment do
    puts "🔍 特別指定大学データの確認を開始..."
    
    # College Scorecard API URL with special designation fields
    base_url = "https://api.data.gov/ed/collegescorecard/v1/schools.json"
    
    # Request parameters
    params = {
      "api_key" => "YOUR_API_KEY_HERE",
      "fields" => [
        "school.name",
        "school.hbcu",
        "school.tribal", 
        "school.hsi",
        "school.womenonly",
        "school.menonly",
        "school.relaffil"
      ].join(","),
      "_per_page" => 100,
      "_page" => 0
    }
    
    # Build URL
    uri = URI(base_url)
    uri.query = URI.encode_www_form(params)
    
    begin
      puts "📡 APIリクエスト送信中..."
      puts "URL: #{uri}"
      
      response = Net::HTTP.get_response(uri)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        schools = data['results']
        
        puts "\n📊 APIレスポンス分析結果:"
        puts "取得した学校数: #{schools.length}校"
        
        # Count special designations
        hbcu_count = schools.count { |s| s['school.hbcu'] == 1 }
        tribal_count = schools.count { |s| s['school.tribal'] == 1 }
        hsi_count = schools.count { |s| s['school.hsi'] == 1 }
        women_count = schools.count { |s| s['school.womenonly'] == 1 }
        men_count = schools.count { |s| s['school.menonly'] == 1 }
        religious_count = schools.count { |s| s['school.relaffil'] && s['school.relaffil'] > 0 }
        
        puts "\n🏆 特別指定大学数 (最初の100校中):"
        puts "  HBCU: #{hbcu_count}校"
        puts "  Tribal: #{tribal_count}校"  
        puts "  HSI: #{hsi_count}校"
        puts "  女子大学: #{women_count}校"
        puts "  男子大学: #{men_count}校"
        puts "  宗教系: #{religious_count}校"
        
        # Show examples
        if hbcu_count > 0
          hbcu_examples = schools.select { |s| s['school.hbcu'] == 1 }.first(3)
          puts "\n📚 HBCU例:"
          hbcu_examples.each { |s| puts "  - #{s['school.name']}" }
        end
        
        if tribal_count > 0
          tribal_examples = schools.select { |s| s['school.tribal'] == 1 }.first(3)
          puts "\n🏛️ Tribal College例:"
          tribal_examples.each { |s| puts "  - #{s['school.name']}" }
        end
        
        if women_count > 0
          women_examples = schools.select { |s| s['school.womenonly'] == 1 }.first(3)
          puts "\n👩‍🎓 女子大学例:"
          women_examples.each { |s| puts "  - #{s['school.name']}" }
        end
        
        # Show raw data sample
        puts "\n🔍 サンプルデータ (最初の学校):"
        first_school = schools.first
        puts "  Name: #{first_school['school.name']}"
        puts "  HBCU: #{first_school['school.hbcu']}"
        puts "  Tribal: #{first_school['school.tribal']}"
        puts "  HSI: #{first_school['school.hsi']}"
        puts "  Women-only: #{first_school['school.womenonly']}"
        puts "  Men-only: #{first_school['school.menonly']}"
        puts "  Religious: #{first_school['school.relaffil']}"
        
      else
        puts "❌ APIエラー: #{response.code} - #{response.message}"
        puts response.body
      end
      
    rescue => e
      puts "❌ エラー: #{e.message}"
    end
    
    puts "\n✅ 特別指定データ確認完了"
  end
end