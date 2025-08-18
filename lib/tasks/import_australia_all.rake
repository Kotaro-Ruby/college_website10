require 'roo'
require Rails.root.join('config', 'australia_universities').to_s

namespace :australia do
  desc "Import all Australian universities data"
  task import_all: :environment do
    puts "\n" + "="*80
    puts "STARTING COMPLETE AUSTRALIAN DATA IMPORT"
    puts "="*80
    
    # Clean existing data
    puts "\n1. Cleaning existing data..."
    AuCourseLocation.destroy_all
    AuLocation.destroy_all
    AuCourse.destroy_all
    AuUniversity.destroy_all
    puts "   ✓ All Australian data cleared"
    
    # Open Excel file
    xlsx_path = Rails.root.join('data', 'cricos-providers-courses-and-locations-as-at-2025-8-1-9-05-05.xlsx').to_s
    xlsx = Roo::Spreadsheet.open(xlsx_path)
    
    # Import universities
    puts "\n2. Importing universities..."
    inst_sheet = xlsx.sheet('Institutions')
    
    universities_imported = 0
    target_universities = {}
    
    (4..inst_sheet.last_row).each do |row_num|
      row = inst_sheet.row(row_num)
      institution_name = row[1]
      
      # Check if this is one of our target universities
      is_target = false
      matched_name = nil
      
      # Stricter matching - only match if the institution name contains the university name
      # or the variations match
      AustraliaUniversities::UNIVERSITIES_LIST.each do |uni_name|
        if institution_name && institution_name.downcase.include?(uni_name.downcase)
          is_target = true
          matched_name = uni_name
          break
        end
      end
      
      # Also check variations
      if !is_target
        AustraliaUniversities::UNIVERSITY_VARIATIONS.each do |standard, variations|
          variations.each do |variation|
            if institution_name&.downcase&.include?(variation.downcase)
              is_target = true
              matched_name = standard
              break
            end
          end
          break if is_target
        end
      end
      
      if is_target
        # Skip if we already have this provider code
        next if target_universities[row[0]]
        
        # Skip if we already imported this university
        uni_name = matched_name || institution_name
        existing_uni = AuUniversity.find_by(name: uni_name)
        if existing_uni
          target_universities[row[0]] = existing_uni
          next
        end
        
        # Generate slug from university name with provider code for uniqueness
        base_slug = uni_name.downcase
          .gsub(/[^a-z0-9\s-]/, '')  # Remove non-alphanumeric characters
          .gsub(/\s+/, '-')           # Replace spaces with hyphens
          .gsub(/-+/, '-')            # Replace multiple hyphens with single hyphen
          .gsub(/^-|-$/, '')          # Remove leading/trailing hyphens
        
        # Make slug unique by adding provider code if needed
        slug = base_slug
        counter = 1
        while AuUniversity.exists?(slug: slug)
          slug = "#{base_slug}-#{counter}"
          counter += 1
        end
        
        uni = AuUniversity.create!(
          name: uni_name,
          slug: slug,
          cricos_provider_code: row[0],
          trading_name: row[1],
          institution_type: row[3],
          institution_capacity: row[4],
          website: row[5],
          city: row[10],
          state: row[11],
          postcode: row[12],
          postal_address: [row[6], row[7], row[8], row[9]].compact.reject(&:empty?).join(", ")
        )
        
        target_universities[row[0]] = uni
        universities_imported += 1
        puts "   #{universities_imported}. #{uni.name} (#{row[0]})"
      end
    end
    
    puts "   ✓ Imported #{universities_imported} universities"
    
    # Import courses
    puts "\n3. Importing courses..."
    courses_sheet = xlsx.sheet('Courses')
    
    total_courses = 0
    courses_by_uni = Hash.new(0)
    
    (4..courses_sheet.last_row).each do |row_num|
      row = courses_sheet.row(row_num)
      provider_code = row[0]
      
      if target_universities[provider_code]
        uni = target_universities[provider_code]
        
        # Calculate annual tuition
        duration_weeks = row[19].to_f
        tuition_fee = row[20].to_f
        annual_tuition = if duration_weeks > 0
          (tuition_fee / (duration_weeks / 52.0)).round
        else
          nil
        end
        
        course = uni.au_courses.create!(
          cricos_course_code: row[2],
          course_name: row[3],
          institution_name: row[1],
          vet_national_code: row[4],
          course_level: row[12],
          dual_qualification: row[5] == "Yes",
          foundation_studies: row[13] == "Yes",
          field_of_education_broad: row[6],
          field_of_education_narrow: row[7],
          field_of_education_detailed: row[8],
          field_of_education_2_broad: row[9],
          field_of_education_2_narrow: row[10],
          field_of_education_2_detailed: row[11],
          duration_weeks: row[19],
          work_component: row[14] == "Yes",
          work_component_hours_per_week: row[15],
          work_component_weeks: row[16],
          work_component_total_hours: row[17],
          course_language: row[18] || "English",
          tuition_fee: tuition_fee,
          non_tuition_fee: row[21],
          estimated_total_cost: row[22],
          annual_tuition_fee: annual_tuition,
          expired: row[23] == "Yes"
        )
        
        total_courses += 1
        courses_by_uni[uni.name] += 1
        
        if total_courses % 100 == 0
          puts "   #{total_courses} courses imported..."
        end
      end
    end
    
    puts "   ✓ Imported #{total_courses} courses total"
    puts "\n   Courses by university:"
    courses_by_uni.sort_by { |_, count| -count }.each do |uni_name, count|
      puts "     - #{uni_name}: #{count} courses"
    end
    
    # Import locations
    puts "\n4. Importing locations..."
    locations_sheet = xlsx.sheet('Locations')
    
    total_locations = 0
    
    (4..locations_sheet.last_row).each do |row_num|
      row = locations_sheet.row(row_num)
      provider_code = row[0]
      
      if target_universities[provider_code]
        uni = target_universities[provider_code]
        
        location = uni.au_locations.find_or_create_by!(
          cricos_provider_code: provider_code,
          location_name: row[1]
        ) do |loc|
          loc.location_type = row[2]
          loc.address_line_1 = row[3]
          loc.address_line_2 = row[4]
          loc.address_line_3 = row[5]
          loc.address_line_4 = row[6]
          loc.city = row[7]
          loc.state = row[8]
          loc.postcode = row[9]
        end
        
        total_locations += 1
      end
    end
    
    puts "   ✓ Imported #{total_locations} locations"
    
    # Import course-location associations
    puts "\n5. Importing course-location associations..."
    course_locations_sheet = xlsx.sheet('Course Locations')
    
    total_associations = 0
    
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
          AuCourseLocation.create!(
            au_course: course,
            au_location: location
          )
          total_associations += 1
        end
      end
    end
    
    puts "   ✓ Created #{total_associations} course-location associations"
    
    # Update statistics for each university
    puts "\n6. Updating university statistics..."
    
    target_universities.each do |code, uni|
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
    puts "IMPORT COMPLETE"
    puts "="*80
    puts "Universities: #{universities_imported}"
    puts "Total Courses: #{total_courses}"
    puts "Total Locations: #{total_locations}"
    puts "Course-Location Links: #{total_associations}"
    puts "\nTop 5 universities by course count:"
    
    AuUniversity
      .order(total_courses_count: :desc)
      .limit(5)
      .each_with_index do |uni, i|
        puts "  #{i+1}. #{uni.name}: #{uni.total_courses_count} courses"
        puts "     Bachelor: #{uni.bachelor_courses_count}, Masters: #{uni.masters_courses_count}, Doctoral: #{uni.doctoral_courses_count}"
        puts "     Tuition: $#{uni.min_annual_tuition&.to_i} - $#{uni.max_annual_tuition&.to_i} AUD/year"
    end
  end
end