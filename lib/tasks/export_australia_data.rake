namespace :export do
  desc "Export Australia university data to JSON"
  task australia_data: :environment do
    require 'json'
    
    # エクスポート先ディレクトリ
    export_dir = Rails.root.join('data', 'australia')
    FileUtils.mkdir_p(export_dir)
    
    # AuUniversity データをエクスポート
    universities_data = AuUniversity.all.map do |uni|
      uni.attributes.merge(
        'courses' => uni.au_courses.map(&:attributes),
        'locations' => uni.au_locations.map(&:attributes),
        'overseas_student_countries' => (uni.overseas_student_countries.map(&:attributes) rescue [])
      )
    end
    
    # JSONファイルに保存
    File.open(export_dir.join('universities.json'), 'w') do |f|
      f.write(JSON.pretty_generate(universities_data))
    end
    
    puts "✅ Exported #{universities_data.size} Australian universities to data/australia/universities.json"
  end
end