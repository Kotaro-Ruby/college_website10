module CollegeMajorImporter
  def self.fetch_and_update_major_data(college_name, api_key, max_retries = 3)
    retries = 0
    
    begin
      # College Scorecard APIから専攻データを取得
      uri = URI('https://api.data.gov/ed/collegescorecard/v1/schools.json')
      
      params = {
        'api_key' => api_key,
        'school.name' => college_name,
        '_fields' => [
          'school.name',
          'latest.academics.program_percentage.agriculture',
          'latest.academics.program_percentage.resources',
          'latest.academics.program_percentage.architecture',
          'latest.academics.program_percentage.area_ethnic_cultural_gender',
          'latest.academics.program_percentage.communication',
          'latest.academics.program_percentage.communications_technology',
          'latest.academics.program_percentage.computer',
          'latest.academics.program_percentage.personal_culinary',
          'latest.academics.program_percentage.education',
          'latest.academics.program_percentage.engineering',
          'latest.academics.program_percentage.engineering_technology',
          'latest.academics.program_percentage.language',
          'latest.academics.program_percentage.family_consumer_science',
          'latest.academics.program_percentage.legal',
          'latest.academics.program_percentage.english',
          'latest.academics.program_percentage.humanities',
          'latest.academics.program_percentage.library',
          'latest.academics.program_percentage.biological',
          'latest.academics.program_percentage.mathematics',
          'latest.academics.program_percentage.military',
          'latest.academics.program_percentage.multidiscipline',
          'latest.academics.program_percentage.parks_recreation_fitness',
          'latest.academics.program_percentage.philosophy_religious',
          'latest.academics.program_percentage.theology_religious_vocation',
          'latest.academics.program_percentage.physical_science',
          'latest.academics.program_percentage.science_technology',
          'latest.academics.program_percentage.psychology',
          'latest.academics.program_percentage.security_law_enforcement',
          'latest.academics.program_percentage.public_administration_social_service',
          'latest.academics.program_percentage.social_science',
          'latest.academics.program_percentage.construction',
          'latest.academics.program_percentage.mechanic_repair_technology',
          'latest.academics.program_percentage.precision_production',
          'latest.academics.program_percentage.transportation',
          'latest.academics.program_percentage.visual_performing',
          'latest.academics.program_percentage.health',
          'latest.academics.program_percentage.business_marketing',
          'latest.academics.program_percentage.history'
        ].join(','),
        '_per_page' => 1
      }
      
      uri.query = URI.encode_www_form(params)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      
      response = http.request(request)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        schools = data['results']
        
        if schools && !schools.empty?
          school = schools.first
          
          # データベースの大学レコードを取得
          condition = Condition.find_by('LOWER(college) = ?', college_name.downcase)
          return false unless condition
          
          # 専攻データを更新
          major_data = {
            pcip_agriculture: school['latest.academics.program_percentage.agriculture'],
            pcip_natural_resources: school['latest.academics.program_percentage.resources'],
            pcip_communication: school['latest.academics.program_percentage.communication'],
            pcip_computer_science: school['latest.academics.program_percentage.computer'],
            pcip_education: school['latest.academics.program_percentage.education'],
            pcip_engineering: school['latest.academics.program_percentage.engineering'],
            pcip_foreign_languages: school['latest.academics.program_percentage.language'],
            pcip_english: school['latest.academics.program_percentage.english'],
            pcip_biology: school['latest.academics.program_percentage.biological'],
            pcip_mathematics: school['latest.academics.program_percentage.mathematics'],
            pcip_psychology: school['latest.academics.program_percentage.psychology'],
            pcip_sociology: school['latest.academics.program_percentage.social_science'],
            pcip_social_sciences: school['latest.academics.program_percentage.public_administration_social_service'],
            pcip_visual_arts: school['latest.academics.program_percentage.visual_performing'],
            pcip_business: school['latest.academics.program_percentage.business_marketing'],
            pcip_health_professions: school['latest.academics.program_percentage.health'],
            pcip_history: school['latest.academics.program_percentage.history'],
            pcip_philosophy: school['latest.academics.program_percentage.philosophy_religious'],
            pcip_physical_sciences: school['latest.academics.program_percentage.physical_science'],
            pcip_law: school['latest.academics.program_percentage.legal']
          }
          
          # nil値を0に変換し、小数点形式に変換
          major_data.each do |key, value|
            major_data[key] = value.nil? ? 0 : (value.to_f / 100.0)
          end
          
          condition.update(major_data)
          return true
        end
      else
        raise "API Error: #{response.code}"
      end
      
    rescue => e
      retries += 1
      if retries <= max_retries
        puts "    Retry #{retries}/#{max_retries} for #{college_name}: #{e.message}"
        sleep(0.5)
        retry
      else
        puts "    Failed to fetch major data for #{college_name}: #{e.message}"
        return false
      end
    end
    
    false
  end
end