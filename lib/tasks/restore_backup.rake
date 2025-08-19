namespace :restore do
  desc "Restore colleges from backup CSV file"
  task from_csv: :environment do
    require 'csv'
    
    csv_file = ENV['CSV_FILE'] || '/Users/kotaro/Desktop/colleges_backup_20250708.csv'
    
    unless File.exist?(csv_file)
      puts "Error: CSV file not found at #{csv_file}"
      exit 1
    end
    
    puts "=== Starting Restore from Backup ==="
    puts "CSV file: #{csv_file}"
    puts "Current college count: #{Condition.count}"
    
    imported_count = 0
    error_count = 0
    errors = []
    
    CSV.foreach(csv_file, headers: true) do |row|
      begin
        # Convert row to hash
        attributes = {}
        
        row.each do |key, value|
          next if key.nil? || key == 'id' || key == 'created_at' || key == 'updated_at'
          
          # Handle nil and empty values
          if value.nil? || value == ''
            attributes[key] = nil
          elsif key == 'comprehensive_data'
            # Parse JSON data
            attributes[key] = value
          elsif %w[hbcu tribal hsi women_only men_only].include?(key)
            # Handle boolean fields
            attributes[key] = (value == 'true' || value == 't' || value == '1')
          elsif %w[tuition students acceptance_rate graduation_rate retention_rate
                   sat_math_25 sat_math_75 sat_reading_25 sat_reading_75
                   act_composite_25 act_composite_75 earnings_6yr_median earnings_10yr_median
                   pell_grant_rate federal_loan_rate median_debt
                   net_price_0_30k net_price_30_48k net_price_48_75k net_price_75_110k net_price_110k_plus
                   percent_white percent_black percent_hispanic percent_asian percent_men percent_women
                   faculty_salary room_board_cost tuition_in_state tuition_out_state
                   religious_affiliation carnegie_basic locale percent_non_resident_alien].include?(key)
            # Handle numeric fields
            attributes[key] = value.to_f unless value == ''
          elsif key.start_with?('pcip_')
            # Handle PCIP decimal fields
            attributes[key] = BigDecimal(value) unless value == ''
          else
            # String fields
            attributes[key] = value
          end
        end
        
        # Create new college record
        Condition.create!(attributes)
        imported_count += 1
        
        if imported_count % 100 == 0
          puts "Imported #{imported_count} colleges..."
        end
        
      rescue => e
        error_count += 1
        errors << "Row #{imported_count + error_count + 1}: #{e.message}"
        if error_count <= 5
          puts "Error: #{e.message}"
        end
      end
    end
    
    puts "\n=== Restore Complete ==="
    puts "Successfully imported: #{imported_count} colleges"
    puts "Errors: #{error_count}"
    puts "Total colleges now: #{Condition.count}"
    
    if errors.any? && errors.count <= 10
      puts "\nFirst few errors:"
      errors.first(10).each { |error| puts "  #{error}" }
    end
  end
  
  desc "Create test user"
  task create_user: :environment do
    begin
      user = User.create!(
        id: 2,
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      puts "User created with id: #{user.id}"
    rescue => e
      puts "Error creating user: #{e.message}"
      # Try without specifying ID
      user = User.create!(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      puts "User created with id: #{user.id}"
    end
  end
end