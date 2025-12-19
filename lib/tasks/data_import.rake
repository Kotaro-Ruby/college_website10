namespace :data do
  desc "Import college data from CSV to production database"
  task import_colleges: :environment do
    require 'csv'
    
    csv_file = ENV['CSV_FILE'] || Rails.root.join('tmp', 'colleges_export.csv')
    
    unless File.exist?(csv_file)
      puts "Error: CSV file not found at #{csv_file}"
      puts "Please specify CSV_FILE environment variable or place file in tmp/"
      exit 1
    end
    
    puts "Importing colleges from #{csv_file}..."
    puts "Current college count: #{Condition.count}"
    
    imported_count = 0
    errors = []
    
    CSV.foreach(csv_file, headers: true, header_converters: :symbol) do |row|
      begin
        # Convert row to hash and remove id (let database auto-generate)
        attributes = row.to_hash
        attributes.delete(:id)
        
        # Handle boolean fields
        %i[hbcu tribal hsi women_only men_only].each do |bool_field|
          if attributes[bool_field]
            attributes[bool_field] = ActiveModel::Type::Boolean.new.cast(attributes[bool_field])
          end
        end
        
        # Handle numeric fields
        numeric_fields = %i[tuition students gpa acceptance_rate graduation_rate retention_rate
                           sat_math_25 sat_math_75 sat_reading_25 sat_reading_75
                           act_composite_25 act_composite_75 earnings_6yr_median earnings_10yr_median
                           pell_grant_rate federal_loan_rate median_debt
                           net_price_0_30k net_price_30_48k net_price_48_75k net_price_75_110k net_price_110k_plus
                           percent_white percent_black percent_hispanic percent_asian percent_men percent_women
                           faculty_salary room_board_cost tuition_in_state tuition_out_state
                           religious_affiliation carnegie_basic locale percent_non_resident_alien]
        
        numeric_fields.each do |field|
          if attributes[field] && attributes[field] != ''
            attributes[field] = attributes[field].to_f
          else
            attributes[field] = nil
          end
        end
        
        # Handle decimal fields for PCIP percentages
        pcip_fields = %i[pcip_agriculture pcip_natural_resources pcip_communication pcip_computer_science
                        pcip_education pcip_engineering pcip_foreign_languages pcip_english pcip_biology
                        pcip_mathematics pcip_psychology pcip_sociology pcip_social_sciences pcip_visual_arts
                        pcip_business pcip_health_professions pcip_history pcip_philosophy pcip_physical_sciences pcip_law]
        
        pcip_fields.each do |field|
          if attributes[field] && attributes[field] != ''
            attributes[field] = BigDecimal(attributes[field].to_s)
          else
            attributes[field] = nil
          end
        end
        
        condition = Condition.create!(attributes)
        imported_count += 1
        
        if imported_count % 100 == 0
          puts "Imported #{imported_count} colleges..."
        end
        
      rescue => e
        errors << "Row #{CSV.lineno(csv_file)}: #{e.message}"
        puts "Error importing college: #{e.message}"
      end
    end
    
    puts "Import completed!"
    puts "Successfully imported: #{imported_count} colleges"
    puts "Total colleges now: #{Condition.count}"
    
    if errors.any?
      puts "Errors encountered:"
      errors.first(10).each { |error| puts "  #{error}" }
      puts "  ... and #{errors.count - 10} more" if errors.count > 10
    end
  end

  desc "Import news data from JSON"
  task import_news: :environment do
    require 'json'

    json_file = Rails.root.join('db/seeds/news_data.json')

    unless File.exist?(json_file)
      puts "Error: JSON file not found at #{json_file}"
      exit 1
    end

    puts "Importing news from #{json_file}..."

    news_data = JSON.parse(File.read(json_file))
    updated_count = 0

    news_data.each do |data|
      news = News.find_by(title: data['title'])
      if news
        news.update(description: data['description'])
        updated_count += 1
        puts "Updated: #{data['title'][0..50]}..."
      else
        puts "Not found: #{data['title'][0..50]}..."
      end
    end

    puts "Updated #{updated_count} news articles"
  end

  desc "Import detailed programs from CSV"
  task import_programs: :environment do
    require 'csv'
    
    csv_file = ENV['CSV_FILE'] || Rails.root.join('tmp', 'detailed_programs_export.csv')
    
    unless File.exist?(csv_file)
      puts "Error: CSV file not found at #{csv_file}"
      exit 1
    end
    
    puts "Importing programs from #{csv_file}..."
    puts "Current program count: #{DetailedProgram.count}"
    
    imported_count = 0
    
    CSV.foreach(csv_file, headers: true, header_converters: :symbol) do |row|
      begin
        attributes = row.to_hash
        attributes.delete(:id)
        
        DetailedProgram.create!(attributes)
        imported_count += 1
        
      rescue => e
        puts "Error importing program: #{e.message}"
      end
    end
    
    puts "Successfully imported: #{imported_count} programs"
    puts "Total programs now: #{DetailedProgram.count}"
  end
end