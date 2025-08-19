namespace :restore do
  desc "Restore conditions from JSON backup"
  task from_json_backup: :environment do
    require 'json'
    
    json_file = 'backups/full_backup_20250708_110643.json'
    
    unless File.exist?(json_file)
      puts "Error: JSON file not found at #{json_file}"
      exit 1
    end
    
    puts "=== Starting Restore from JSON Backup ==="
    puts "Loading data from: #{json_file}"
    
    data = JSON.parse(File.read(json_file))
    
    puts "Found #{data['conditions'].size} colleges in backup"
    puts "Starting import..."
    
    imported_count = 0
    error_count = 0
    
    data['conditions'].each_with_index do |record, index|
      begin
        # Remove id and timestamps from attributes
        attributes = record.except('id', 'created_at', 'updated_at')
        
        # Create the condition record
        Condition.create!(attributes)
        imported_count += 1
        
        if imported_count % 500 == 0
          puts "Imported #{imported_count} colleges..."
        end
        
      rescue => e
        error_count += 1
        if error_count <= 5
          puts "Error importing #{record['college']}: #{e.message}"
        end
      end
    end
    
    puts "\n=== Restore Complete ==="
    puts "Successfully imported: #{imported_count} colleges"
    puts "Errors: #{error_count}"
    puts "Total colleges: #{Condition.count}"
    
    # Verify some specific colleges
    puts "\nVerification:"
    
    # Check UC Santa Cruz
    ucsc = Condition.find_by(college: 'University of California-Santa Cruz')
    if ucsc
      puts "UC Santa Cruz:"
      puts "  SAT scores: #{ucsc.sat_math_25}-#{ucsc.sat_math_75} (Math), #{ucsc.sat_reading_25}-#{ucsc.sat_reading_75} (Reading)"
      puts "  Demographics: White=#{ucsc.percent_white}, Asian=#{ucsc.percent_asian}, Hispanic=#{ucsc.percent_hispanic}"
      puts "  Retention: #{ucsc.retention_rate}"
    else
      puts "UC Santa Cruz not found"
    end
    
    # Check a few other colleges
    ['Harvard University', 'Stanford University', 'MIT'].each do |name|
      college = Condition.find_by(college: name)
      if college
        puts "#{name}: Found with #{college.students} students"
      end
    end
    
    # Statistics
    puts "\nStatistics:"
    puts "  Colleges with SAT data: #{Condition.where.not(sat_math_25: nil).count}"
    puts "  Colleges with demographic data: #{Condition.where.not(percent_white: nil).count}"
    puts "  Colleges with retention data: #{Condition.where.not(retention_rate: nil).count}"
  end
end