namespace :wiki do
  desc "Fetch university images from Wikimedia Commons"
  task fetch_images: :environment do
    require 'net/http'
    require 'json'
    require 'uri'

    def search_wiki_images(university_name, limit = 3)
      puts "Searching images for: #{university_name}"
      
      # WikiMediaのAPIエンドポイント
      base_url = "https://commons.wikimedia.org/w/api.php"
      
      # 検索クエリのパラメータ
      params = {
        action: "query",
        format: "json",
        generator: "search",
        gsrsearch: "#{university_name} campus building",
        gsrnamespace: "6", # File namespace
        gsrlimit: limit.to_s,
        prop: "imageinfo|info",
        iiprop: "url|extmetadata|mime",
        iiurlwidth: "1200"
      }
      
      uri = URI(base_url)
      uri.query = URI.encode_www_form(params)
      
      begin
        response = Net::HTTP.get_response(uri)
        if response.code == '200'
          data = JSON.parse(response.body)
          
          images = []
          credits = []
          
          if data['query'] && data['query']['pages']
            data['query']['pages'].each do |page_id, page_data|
              if page_data['imageinfo'] && page_data['imageinfo'][0]
                image_info = page_data['imageinfo'][0]
                
                # 画像URLを取得
                image_url = image_info['thumburl'] || image_info['url']
                
                # クレジット情報を構築
                extmetadata = image_info['extmetadata'] || {}
                artist = extmetadata['Artist'] ? extmetadata['Artist']['value'].gsub(/<[^>]*>/, '') : 'Unknown'
                license = extmetadata['LicenseShortName'] ? extmetadata['LicenseShortName']['value'] : 'CC'
                
                credit = "#{artist} / Wikimedia Commons / #{license}"
                
                # MIMEタイプをチェック（画像のみ取得）
                if image_info['mime'] && image_info['mime'].start_with?('image/')
                  images << image_url
                  credits << credit
                  puts "  Found: #{page_data['title']}"
                  puts "  URL: #{image_url}"
                  puts "  Credit: #{credit}"
                end
              end
            end
          end
          
          { images: images, credits: credits }
        else
          puts "  Error: HTTP #{response.code}"
          { images: [], credits: [] }
        end
      rescue => e
        puts "  Error fetching images: #{e.message}"
        { images: [], credits: [] }
      end
    end

    def download_and_save_image(url, filename)
      begin
        uri = URI(url)
        response = Net::HTTP.get_response(uri)
        
        if response.code == '200'
          # publicフォルダに保存
          file_path = Rails.root.join('public', 'images', 'au', 'universities', filename)
          
          # ディレクトリが存在しない場合は作成
          FileUtils.mkdir_p(File.dirname(file_path))
          
          # 画像を保存
          File.open(file_path, 'wb') do |file|
            file.write(response.body)
          end
          
          puts "    Saved: #{filename}"
          true
        else
          puts "    Failed to download: HTTP #{response.code}"
          false
        end
      rescue => e
        puts "    Error downloading: #{e.message}"
        false
      end
    end

    # クレジットがない大学を取得
    universities_without_credits = AuUniversity.where(image_credits: [nil, ''])
    
    puts "Found #{universities_without_credits.count} universities without image credits"
    puts "=" * 60
    
    universities_without_credits.each_with_index do |university, index|
      puts "\n[#{index + 1}/#{universities_without_credits.count}] Processing: #{university.name}"
      
      # WikiCommonsで画像を検索
      result = search_wiki_images(university.name)
      
      if result[:images].any?
        saved_images = []
        saved_credits = []
        
        result[:images].each_with_index do |image_url, idx|
          # ファイル名を生成（大学名をスラッグ化）
          slug = university.name.downcase.gsub(' ', '-').gsub(/[^a-z0-9\-]/, '')
          extension = image_url.match(/\.(jpg|jpeg|png|gif|webp)/i) ? $1.downcase : 'jpg'
          filename = idx == 0 ? "#{slug}.#{extension}" : "#{slug}-#{idx + 1}.#{extension}"
          
          # 画像をダウンロードして保存
          if download_and_save_image(image_url, filename)
            saved_images << "/images/au/universities/#{filename}"
            saved_credits << result[:credits][idx]
          end
        end
        
        # データベースを更新
        if saved_images.any?
          university.update(
            images: saved_images.to_json,
            image_credits: saved_credits.to_json
          )
          puts "  ✓ Updated database with #{saved_images.count} images"
        end
      else
        puts "  ✗ No images found"
      end
      
      # API制限を避けるため少し待機
      sleep(1)
    end
    
    puts "\n" + "=" * 60
    puts "Task completed!"
    
    # 統計を表示
    total = AuUniversity.count
    with_credits = AuUniversity.where.not(image_credits: [nil, '']).count
    puts "Universities with image credits: #{with_credits}/#{total}"
  end

  desc "Test WikiCommons API with a specific university"
  task :test_api, [:university_name] => :environment do |t, args|
    require 'net/http'
    require 'json'
    require 'uri'
    
    university_name = args[:university_name] || "University of Sydney"
    
    puts "Testing WikiCommons API for: #{university_name}"
    puts "=" * 60
    
    base_url = "https://commons.wikimedia.org/w/api.php"
    
    params = {
      action: "query",
      format: "json",
      generator: "search",
      gsrsearch: "#{university_name}",
      gsrnamespace: "6",
      gsrlimit: "5",
      prop: "imageinfo|info",
      iiprop: "url|extmetadata|mime",
      iiurlwidth: "800"
    }
    
    uri = URI(base_url)
    uri.query = URI.encode_www_form(params)
    
    puts "Request URL: #{uri}\n\n"
    
    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body)
    
    puts JSON.pretty_generate(data)
  end
end