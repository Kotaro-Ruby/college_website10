require 'roo'

namespace :import do
  desc "Import college data from Excel file"
  task :colleges, [:file_path] => :environment do |t, args|
    file_path = args[:file_path] || '/Users/kotaro/Downloads/college_data_revised5_18_25_6th.xlsx'
    
    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      exit
    end
    
    begin
      xlsx = Roo::Spreadsheet.open(file_path)
      sheet = xlsx.sheet(0)
      
      # Get headers from the first row
      headers = sheet.row(1).map(&:to_s).map(&:downcase).map(&:strip)
      puts "Found headers: #{headers.inspect}"
      
      # Map Excel headers to database columns
      column_mapping = {
        'state' => 'state',
        'tuition' => 'tuition',
        'students' => 'students',
        'major' => 'major',
        'gpa' => 'GPA',
        'private or public' => 'privateorpublic',
        'privateorpublic' => 'privateorpublic',
        'college' => 'college',
        'division' => 'Division',
        'acceptance rate' => 'acceptance_rate',
        'acceptance_rate' => 'acceptance_rate',
        'city' => 'city',
        'address' => 'address',
        'zip' => 'zip',
        'urbanicity' => 'urbanicity',
        'website' => 'website',
        'school type' => 'school_type',
        'school_type' => 'school_type',
        'graduation rate' => 'graduation_rate',
        'graduation_rate' => 'graduation_rate'
      }
      
      imported_count = 0
      error_count = 0
      
      # Process each row starting from row 2
      (2..sheet.last_row).each do |row_num|
        row_data = {}
        
        headers.each_with_index do |header, index|
          db_column = column_mapping[header]
          if db_column
            value = sheet.cell(row_num, index + 1)
            
            # Clean and convert data types
            case db_column
            when 'tuition', 'students', 'acceptance_rate', 'graduation_rate'
              # Remove commas and convert to number
              value = value.to_s.gsub(/[$,]/, '').strip
              value = value.empty? ? nil : value.to_f
            when 'GPA'
              value = value.to_f if value
            when 'zip'
              value = value.to_s.strip
            else
              value = value.to_s.strip if value
            end
            
            row_data[db_column] = value
          end
        end
        
        # Skip if no college name
        next if row_data['college'].blank?
        
        begin
          # Create or update the record
          condition = Condition.find_or_initialize_by(college: row_data['college'])
          condition.assign_attributes(row_data)
          
          if condition.save
            imported_count += 1
            puts "Imported: #{row_data['college']}"
          else
            error_count += 1
            puts "Error importing #{row_data['college']}: #{condition.errors.full_messages.join(', ')}"
          end
        rescue => e
          error_count += 1
          puts "Error on row #{row_num}: #{e.message}"
        end
      end
      
      puts "\n========== Import Summary =========="
      puts "Successfully imported: #{imported_count} records"
      puts "Errors: #{error_count} records"
      puts "Total in database: #{Condition.count} records"
      
    rescue => e
      puts "Error reading Excel file: #{e.message}"
      puts e.backtrace.first(5)
    end
  end
end