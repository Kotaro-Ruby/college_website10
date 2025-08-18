require 'roo'

namespace :australia do
  desc "Import missing Australian universities"
  task import_missing: :environment do
    puts "\n" + "="*80
    puts "IMPORTING MISSING AUSTRALIAN UNIVERSITIES"
    puts "="*80
    
    # Open Excel file
    xlsx_path = Rails.root.join('data', 'cricos-providers-courses-and-locations-as-at-2025-8-1-9-05-05.xlsx').to_s
    xlsx = Roo::Spreadsheet.open(xlsx_path)
    
    # Missing universities with their likely provider codes
    missing_unis = {
      '00034K' => 'University of Canberra',
      '00114A' => 'Flinders University',
      '00121B' => 'University of South Australia',
      '00586B' => 'University of Tasmania',
      '00113B' => 'Deakin University',
      '00111D' => 'Swinburne University of Technology',
      '00116K' => 'The University of Melbourne'
    }
    
    inst_sheet = xlsx.sheet('Institutions')
    courses_sheet = xlsx.sheet('Courses')
    
    imported = 0
    
    missing_unis.each do |code, name|
      puts "\nProcessing #{name} (#{code})..."
      
      # Find university details in institutions sheet
      uni_data = nil
      (4..inst_sheet.last_row).each do |row_num|
        row = inst_sheet.row(row_num)
        if row[0] == code
          uni_data = row
          break
        end
      end
      
      if uni_data
        # Generate slug
        slug = name.downcase
          .gsub(/[^a-z0-9\s-]/, '')
          .gsub(/\s+/, '-')
          .gsub(/-+/, '-')
          .gsub(/^-|-$/, '')
        
        # Check if already exists
        existing = AuUniversity.find_by(cricos_provider_code: code)
        if existing
          puts "  Already exists as: #{existing.name}"
          next
        end
        
        # Create university
        uni = AuUniversity.create!(
          name: name,
          slug: slug,
          cricos_provider_code: code,
          trading_name: uni_data[1] || name,
          institution_type: uni_data[3],
          institution_capacity: uni_data[4],
          website: uni_data[5],
          city: uni_data[10],
          state: uni_data[11],
          postcode: uni_data[12],
          postal_address: [uni_data[6], uni_data[7], uni_data[8], uni_data[9]].compact.reject(&:empty?).join(", ")
        )
        
        puts "  Created: #{uni.name}"
        imported += 1
        
        # Import courses for this university
        course_count = 0
        (4..courses_sheet.last_row).each do |row_num|
          row = courses_sheet.row(row_num)
          
          if row[0] == code
            # Calculate annual tuition
            duration_weeks = row[19].to_f
            tuition_fee = row[20].to_f
            annual_tuition = if duration_weeks > 0
              (tuition_fee / (duration_weeks / 52.0)).round
            else
              nil
            end
            
            begin
              course = uni.au_courses.create!(
                cricos_course_code: row[2],
                course_name: row[3],
                institution_name: row[1] || name,
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
              course_count += 1
            rescue => e
              # Skip invalid courses
            end
          end
        end
        
        puts "  Imported #{course_count} courses"
        
        # Update statistics
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
      else
        puts "  Not found in Excel file"
      end
    end
    
    puts "\n" + "="*80
    puts "IMPORT COMPLETE"
    puts "="*80
    puts "Added #{imported} universities"
    puts "Total universities now: #{AuUniversity.count}"
    puts "Total courses now: #{AuCourse.count}"
    
    # Check if we have all 39 universities
    remaining = 39 - AuUniversity.count
    if remaining > 0
      puts "\nStill missing #{remaining} universities"
    else
      puts "\nAll 39 universities imported successfully!"
    end
  end
end