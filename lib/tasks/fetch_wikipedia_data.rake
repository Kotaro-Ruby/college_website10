namespace :import do
  desc "Fetch NCAA data from Wikipedia (free and legal)"
  task wikipedia_ncaa: :environment do
    require 'net/http'
    require 'json'
    require 'uri'
    
    def fetch_wikipedia_data(college_name)
      # Wikipedia API - 完全無料・合法
      base_url = "https://en.wikipedia.org/w/api.php"
      
      # 大学名を検索用に調整
      search_name = college_name.gsub(/University of /, '')
                                .gsub(/College/, '')
                                .strip
      
      params = {
        action: 'query',
        format: 'json',
        prop: 'extracts|pageprops',
        exintro: true,
        explaintext: true,
        titles: college_name,
        ppprop: 'wikibase_item'
      }
      
      uri = URI(base_url)
      uri.query = URI.encode_www_form(params)
      
      response = Net::HTTP.get_response(uri)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        pages = data['query']['pages']
        
        # ページの内容を解析
        pages.each do |page_id, page_data|
          extract = page_data['extract']
          
          if extract
            # NCAA Division情報を抽出
            ncaa_info = case extract
                       when /NCAA Division I/i
                         "Division I"
                       when /NCAA Division II/i
                         "Division II"
                       when /NCAA Division III/i
                         "Division III"
                       when /NAIA/i
                         "NAIA"
                       else
                         nil
                       end
            
            return ncaa_info
          end
        end
      end
      
      nil
    rescue => e
      puts "Error fetching Wikipedia data: #{e.message}"
      nil
    end
    
    # 処理対象の大学
    Condition.where(Division: nil).limit(10).each do |condition|
      puts "Checking #{condition.college}..."
      
      ncaa_info = fetch_wikipedia_data(condition.college)
      
      if ncaa_info
        condition.update(Division: ncaa_info)
        puts "  → Found: #{ncaa_info}"
      else
        puts "  → No NCAA info found"
      end
      
      # API利用規約に従い、リクエスト間隔を空ける
      sleep 1
    end
  end
end