# Australian Universities Seed Data
puts "🇦🇺 Importing Australian University data..."

# JSONファイルからデータを読み込む
json_file = Rails.root.join('data', 'australia', 'universities.json')

if File.exist?(json_file)
  require 'json'
  
  begin
    data = JSON.parse(File.read(json_file))
    
    data.each do |uni_data|
      # 大学データの作成
      university_attrs = uni_data.except('courses', 'locations', 'overseas_student_countries')
      university_attrs.delete('id')  # IDは自動生成させる
      
      university = AuUniversity.find_or_create_by(
        name: university_attrs['name']
      ) do |u|
        u.assign_attributes(university_attrs)
      end
      
      # コースデータの作成
      if uni_data['courses'].present?
        uni_data['courses'].each do |course_data|
          course_attrs = course_data.except('id', 'au_university_id')
          
          AuCourse.find_or_create_by(
            au_university: university,
            cricos_course_code: course_attrs['cricos_course_code']
          ) do |c|
            c.assign_attributes(course_attrs)
          end
        end
      end
      
      # ロケーションデータの作成
      if uni_data['locations'].present?
        uni_data['locations'].each do |location_data|
          location_attrs = location_data.except('id', 'au_university_id')
          
          AuLocation.find_or_create_by(
            au_university: university,
            location_name: location_attrs['location_name']
          ) do |l|
            l.assign_attributes(location_attrs)
          end
        end
      end
      
      # 留学生国別データの作成（モデルが存在する場合）
      if defined?(OverseasStudentCountry) && uni_data['overseas_student_countries'].present?
        uni_data['overseas_student_countries'].each do |country_data|
          country_attrs = country_data.except('id', 'au_university_id')
          
          OverseasStudentCountry.find_or_create_by(
            au_university: university,
            country: country_attrs['country']
          ) do |o|
            o.assign_attributes(country_attrs)
          end
        end
      end
    end
    
    puts "✅ Successfully imported #{AuUniversity.count} Australian universities"
    puts "   - #{AuCourse.count} courses"
    puts "   - #{AuLocation.count} locations"
    
  rescue JSON::ParserError => e
    puts "❌ Error parsing JSON file: #{e.message}"
  rescue => e
    puts "❌ Error importing Australian data: #{e.message}"
    puts e.backtrace.first(5)
  end
else
  puts "⚠️  Australian university data file not found at #{json_file}"
  puts "   Run 'rake export:australia_data' first to generate the data file"
end