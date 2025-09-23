# Auto-import college data if none exists (for production deployment)
if Condition.count == 0 && File.exist?(Rails.root.join('data', 'colleges_data.csv'))
  puts "🏫 No college data found. Auto-importing from CSV..."

  require 'csv'
  imported_count = 0

  CSV.foreach(Rails.root.join('data', 'colleges_data.csv'), headers: true, header_converters: :symbol) do |row|
    begin
      attributes = row.to_hash
      attributes.delete(:id)

      # Handle boolean fields
      %i[hbcu tribal hsi women_only men_only].each do |bool_field|
        if attributes[bool_field]
          attributes[bool_field] = ActiveModel::Type::Boolean.new.cast(attributes[bool_field])
        end
      end

      # Handle numeric fields - convert empty strings to nil
      # Note: CSV has 'GPA' but database has 'gpa' - handle the mapping
      if attributes[:gpa]
        attributes[:gpa] = attributes[:gpa]
      elsif attributes[:GPA]
        attributes[:gpa] = attributes[:GPA]
        attributes.delete(:GPA)
      end

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

      Condition.create!(attributes)
      imported_count += 1

      if imported_count % 500 == 0
        puts "📊 Imported #{imported_count} colleges..."
      end

    rescue => e
      puts "❌ Error importing college: #{e.message}"
    end
  end

  puts "✅ College data import completed! Total: #{Condition.count} colleges"
else
  puts "📚 College data already exists (#{Condition.count} colleges)"
end

# Import Country data from REST Countries API
if Country.count == 0
  puts "\n🌍 Importing country data from REST Countries API..."
  if CountryApiService.fetch_and_update_countries
    count = Country.count
    puts "✅ Successfully imported #{count} countries (US, AU, NZ, CA)"
  else
    puts "⚠️  Failed to import country data - will retry on next deploy"
  end
else
  puts "🌍 Country data already exists (#{Country.count} countries)"
end

# Import Australian University data
if AuUniversity.count == 0
  puts "\n🇦🇺 Importing Australian University data..."
  load Rails.root.join('db', 'seeds', 'australia_data.rb')
else
  puts "🇦🇺 Australian university data already exists (#{AuUniversity.count} universities)"
end
