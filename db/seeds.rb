# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'csv'

# Import college data from CSV file
csv_file_path = Rails.root.join('college_data.csv')

if File.exist?(csv_file_path)
  puts "Starting college data import from #{csv_file_path}..."
  
  imported_count = 0
  error_count = 0
  
  CSV.foreach(csv_file_path, headers: true, encoding: 'UTF-8') do |row|
    begin
      # Skip if no college name
      next if row['college'].blank?
      
      # Prepare data with proper type conversions
      college_data = {
        college: row['college']&.strip,
        state: row['state']&.strip,
        students: row['students']&.to_i,
        privateorpublic: row['privateorpublic']&.strip,
        acceptance_rate: row['acceptance_rate']&.to_f,
        city: row['city']&.strip,
        address: row['address']&.strip,
        zip: row['zip']&.strip,
        urbanicity: row['urbanicity']&.strip,
        website: row['website']&.strip,
        school_type: row['school_type']&.strip,
        graduation_rate: row['graduation_rate']&.to_f
      }
      
      # Additional fields from Excel that might be in CSV
      college_data[:tuition] = row['tuition'].to_f if row['tuition']
      college_data[:major] = row['major']&.strip if row['major']
      college_data[:GPA] = row['GPA'].to_f if row['GPA']
      college_data[:Division] = row['Division']&.strip if row['Division']
      
      # Create or update the record
      condition = Condition.find_or_initialize_by(college: college_data[:college])
      condition.assign_attributes(college_data)
      
      if condition.save
        imported_count += 1
        puts "✓ Imported: #{college_data[:college]}"
      else
        error_count += 1
        puts "✗ Error importing #{college_data[:college]}: #{condition.errors.full_messages.join(', ')}"
      end
      
    rescue => e
      error_count += 1
      puts "✗ Error processing row: #{e.message}"
    end
  end
  
  puts "\n========== Import Summary =========="
  puts "Successfully imported: #{imported_count} records"
  puts "Errors: #{error_count} records"
  puts "Total in database: #{Condition.count} records"
  puts "===================================="
else
  puts "Warning: College data CSV file not found at #{csv_file_path}"
  puts "Please ensure college_data.csv is in the Rails root directory"
  
  # Alternative: Use the rake task
  puts "\nAlternatively, you can use the rake task to import from Excel:"
  puts "  rails import:colleges[path/to/excel/file.xlsx]"
end

