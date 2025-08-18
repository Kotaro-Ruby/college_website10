require 'roo'
require Rails.root.join('config', 'australia_universities').to_s

namespace :australia do
  desc "Import remaining Australian data (course-locations and statistics)"
  task import_remaining: :environment do
    puts "\n" + "="*80
    puts "IMPORTING REMAINING AUSTRALIAN DATA"
    puts "="*80
    
    # Open Excel file
    xlsx_path = Rails.root.join('data', 'cricos-providers-courses-and-locations-as-at-2025-8-1-9-05-05.xlsx').to_s
    xlsx = Roo::Spreadsheet.open(xlsx_path)
    
    # Get all target universities by provider code
    target_universities = {}
    AuUniversity.all.each do |uni|
      target_universities[uni.cricos_provider_code] = uni
    end
    
    # Import course-location associations
    puts "\n1. Importing course-location associations..."
    course_locations_sheet = xlsx.sheet('Course Locations')
    
    total_associations = 0
    errors = 0
    
    (4..course_locations_sheet.last_row).each do |row_num|
      row = course_locations_sheet.row(row_num)
      provider_code = row[0]
      
      if target_universities[provider_code]
        course_code = row[1]
        location_name = row[2]
        
        course = AuCourse.find_by(cricos_course_code: course_code)
        location = AuLocation.find_by(
          cricos_provider_code: provider_code,
          location_name: location_name
        )
        
        if course && location
          begin
            AuCourseLocation.find_or_create_by!(
              au_course: course,
              au_location: location
            )
            total_associations += 1
            
            if total_associations % 500 == 0
              puts "   #{total_associations} associations created..."
            end
          rescue => e
            errors += 1
          end
        end
      end
    end
    
    puts "   ✓ Created #{total_associations} course-location associations"
    puts "   Errors: #{errors}" if errors > 0
    
    # Update statistics for each university
    puts "\n2. Updating university statistics..."
    
    AuUniversity.all.each do |uni|
      uni.reload
      
      uni.update!(
        total_courses_count: uni.au_courses.count,
        bachelor_courses_count: uni.au_courses.bachelor.count,
        masters_courses_count: uni.au_courses.masters.count,
        doctoral_courses_count: uni.au_courses.doctoral.count,
        min_annual_tuition: uni.au_courses.minimum(:annual_tuition_fee),
        max_annual_tuition: uni.au_courses.maximum(:annual_tuition_fee),
        avg_annual_tuition: uni.au_courses.average(:annual_tuition_fee)
      )
      
      # Set popular fields
      top_fields = uni.au_courses
        .group(:field_of_education_broad)
        .count
        .sort_by { |_, count| -count }
        .first(3)
        .map { |field, _| field }
        .compact
        .join(", ")
      
      uni.update!(popular_fields: top_fields) if top_fields.present?
      
      puts "   ✓ #{uni.name}: #{uni.total_courses_count} courses"
    end
    
    # Final summary
    puts "\n" + "="*80
    puts "IMPORT COMPLETE - SUMMARY"
    puts "="*80
    puts "Universities: #{AuUniversity.count}"
    puts "Total Courses: #{AuCourse.count}"
    puts "Total Locations: #{AuLocation.count}"
    puts "Course-Location Links: #{AuCourseLocation.count}"
    
    puts "\nTop 10 universities by course count:"
    AuUniversity
      .order(total_courses_count: :desc)
      .limit(10)
      .each_with_index do |uni, i|
        puts "  #{i+1}. #{uni.name}: #{uni.total_courses_count} courses"
        if uni.min_annual_tuition && uni.max_annual_tuition
          puts "     Tuition: $#{uni.min_annual_tuition.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse} - $#{uni.max_annual_tuition.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse} AUD/year"
        end
    end
    
    # Check missing target universities
    puts "\nMissing Universities (not found in Excel):"
    missing = AustraliaUniversities::UNIVERSITIES_LIST - AuUniversity.pluck(:name)
    if missing.any?
      missing.each { |name| puts "  - #{name}" }
    else
      puts "  None - all 39 universities imported!"
    end
  end
end