namespace :export do
  desc "Export all college data to JSON file for deployment"
  task colleges: :environment do
    puts "=== College Data Export Starting ==="
    
    total_count = Condition.count
    puts "Total colleges to export: #{total_count}"
    
    # バッチ処理でメモリ使用量を抑制
    batch_size = 500
    exported_data = []
    
    puts "Exporting data in batches of #{batch_size}..."
    
    Condition.find_in_batches(batch_size: batch_size).with_index do |batch, index|
      batch_data = batch.map do |college|
        {
          college: college.college,
          state: college.state,
          tuition: college.tuition,
          students: college.students,
          privateorpublic: college.privateorpublic,
          GPA: college.GPA,
          acceptance_rate: college.acceptance_rate,
          graduation_rate: college.graduation_rate,
          city: college.city,
          Division: college.Division,
          address: college.address,
          zip: college.zip,
          urbanicity: college.urbanicity,
          website: college.website,
          school_type: college.school_type,
          comment: college.comment,
          major_data: college.major_data,
          pcip_business: college.pcip_business,
          pcip_engineering: college.pcip_engineering,
          pcip_computer_science: college.pcip_computer_science,
          pcip_education: college.pcip_education,
          pcip_healthcare: college.pcip_healthcare,
          pcip_arts: college.pcip_arts,
          pcip_agriculture: college.pcip_agriculture,
          pcip_social_sciences: college.pcip_social_sciences,
          pcip_psychology: college.pcip_psychology,
          pcip_communications: college.pcip_communications,
          pcip_other: college.pcip_other
        }
      end
      
      exported_data.concat(batch_data)
      puts "Processed batch #{index + 1}: #{batch.size} colleges"
    end
    
    # JSONファイルに書き出し
    output_file = Rails.root.join('tmp', 'college_data_export.json')
    
    File.open(output_file, 'w') do |file|
      file.write(JSON.pretty_generate({
        export_date: Time.current.iso8601,
        total_colleges: exported_data.size,
        data: exported_data
      }))
    end
    
    file_size = File.size(output_file) / 1024.0 / 1024.0
    puts "\n=== Export Complete ==="
    puts "Exported #{exported_data.size} colleges"
    puts "File: #{output_file}"
    puts "Size: #{file_size.round(2)} MB"
    puts "\nTo import this data on Render, copy this file to the server and run:"
    puts "RAILS_ENV=production bundle exec rails import:from_json"
  end

  desc "Export data in compressed format for deployment"
  task colleges_compressed: :environment do
    require 'zlib'
    
    puts "=== Compressed College Data Export Starting ==="
    
    total_count = Condition.count
    puts "Total colleges to export: #{total_count}"
    
    # 全フィールドをエクスポート（収入データ、性別分布など含む）
    exported_data = Condition.all.map do |college|
      # 基本フィールド（短縮形）
      data = {
        c: college.college,
        s: college.state,
        t: college.tuition,
        st: college.students,
        p: college.privateorpublic,
        g: college.GPA,
        a: college.acceptance_rate,
        gr: college.graduation_rate,
        ci: college.city,
        d: college.Division,
        co: college.comment
      }
      
      # 全ての詳細データを追加（値がある場合のみ）
      additional_data = {}
      
      # 財務・収入データ
      additional_data[:pell_grant_rate] = college.pell_grant_rate if college.pell_grant_rate
      additional_data[:federal_loan_rate] = college.federal_loan_rate if college.federal_loan_rate
      additional_data[:median_debt] = college.median_debt if college.median_debt
      additional_data[:earnings_10yr_median] = college.earnings_10yr_median if college.earnings_10yr_median
      additional_data[:earnings_6yr_median] = college.earnings_6yr_median if college.earnings_6yr_median
      additional_data[:net_price_0_30k] = college.net_price_0_30k if college.net_price_0_30k
      additional_data[:net_price_30_48k] = college.net_price_30_48k if college.net_price_30_48k
      additional_data[:net_price_48_75k] = college.net_price_48_75k if college.net_price_48_75k
      additional_data[:net_price_75_110k] = college.net_price_75_110k if college.net_price_75_110k
      additional_data[:net_price_110k_plus] = college.net_price_110k_plus if college.net_price_110k_plus
      
      # 性別分布データ
      additional_data[:percent_men] = college.percent_men if college.percent_men
      additional_data[:percent_women] = college.percent_women if college.percent_women
      
      # 人種・民族分布データ
      additional_data[:percent_white] = college.percent_white if college.percent_white
      additional_data[:percent_black] = college.percent_black if college.percent_black
      additional_data[:percent_hispanic] = college.percent_hispanic if college.percent_hispanic
      additional_data[:percent_asian] = college.percent_asian if college.percent_asian
      additional_data[:percent_non_resident_alien] = college.percent_non_resident_alien if college.percent_non_resident_alien
      
      # SAT/ACTスコア
      additional_data[:sat_math_25] = college.sat_math_25 if college.sat_math_25
      additional_data[:sat_math_75] = college.sat_math_75 if college.sat_math_75
      additional_data[:sat_reading_25] = college.sat_reading_25 if college.sat_reading_25
      additional_data[:sat_reading_75] = college.sat_reading_75 if college.sat_reading_75
      additional_data[:act_composite_25] = college.act_composite_25 if college.act_composite_25
      additional_data[:act_composite_75] = college.act_composite_75 if college.act_composite_75
      
      # その他重要データ
      additional_data[:retention_rate] = college.retention_rate if college.retention_rate
      additional_data[:faculty_salary] = college.faculty_salary if college.faculty_salary
      additional_data[:room_board_cost] = college.room_board_cost if college.room_board_cost
      additional_data[:tuition_in_state] = college.tuition_in_state if college.tuition_in_state
      additional_data[:tuition_out_state] = college.tuition_out_state if college.tuition_out_state
      additional_data[:school_type] = college.school_type if college.school_type
      additional_data[:locale] = college.locale if college.locale
      additional_data[:carnegie_basic] = college.carnegie_basic if college.carnegie_basic
      additional_data[:religious_affiliation] = college.religious_affiliation if college.religious_affiliation
      additional_data[:hbcu] = college.hbcu if college.hbcu
      additional_data[:hsi] = college.hsi if college.hsi
      additional_data[:tribal] = college.tribal if college.tribal
      additional_data[:men_only] = college.men_only if college.men_only
      additional_data[:women_only] = college.women_only if college.women_only
      additional_data[:urbanicity] = college.urbanicity if college.urbanicity
      additional_data[:website] = college.website if college.website
      additional_data[:address] = college.address if college.address
      additional_data[:zip] = college.zip if college.zip
      
      # 専攻データを追加（値がある場合のみ）
      major_data = {}
      {
        pcip_agriculture: college.pcip_agriculture,
        pcip_natural_resources: college.pcip_natural_resources,
        pcip_communication: college.pcip_communication,
        pcip_computer_science: college.pcip_computer_science,
        pcip_education: college.pcip_education,
        pcip_engineering: college.pcip_engineering,
        pcip_foreign_languages: college.pcip_foreign_languages,
        pcip_english: college.pcip_english,
        pcip_biology: college.pcip_biology,
        pcip_mathematics: college.pcip_mathematics,
        pcip_psychology: college.pcip_psychology,
        pcip_sociology: college.pcip_sociology,
        pcip_social_sciences: college.pcip_social_sciences,
        pcip_visual_arts: college.pcip_visual_arts,
        pcip_business: college.pcip_business,
        pcip_health_professions: college.pcip_health_professions,
        pcip_history: college.pcip_history,
        pcip_philosophy: college.pcip_philosophy,
        pcip_physical_sciences: college.pcip_physical_sciences,
        pcip_law: college.pcip_law
      }.each do |field, value|
        if value && value > 0
          major_data[field] = value
        end
      end
      
      data[:add] = additional_data unless additional_data.empty?
      data[:maj] = major_data unless major_data.empty?
      data
    end
    
    # JSONを圧縮
    json_data = JSON.generate({
      export_date: Time.current.iso8601,
      total_colleges: exported_data.size,
      data: exported_data
    })
    
    compressed_data = Zlib::Deflate.deflate(json_data)
    
    # 圧縮ファイルに書き出し
    output_file = Rails.root.join('tmp', 'college_data_compressed.json.gz')
    
    File.open(output_file, 'wb') do |file|
      file.write(compressed_data)
    end
    
    original_size = json_data.bytesize / 1024.0 / 1024.0
    compressed_size = File.size(output_file) / 1024.0 / 1024.0
    compression_ratio = (compressed_size / original_size * 100).round(1)
    
    puts "\n=== Compressed Export Complete ==="
    puts "Exported #{exported_data.size} colleges"
    puts "Original size: #{original_size.round(2)} MB"
    puts "Compressed size: #{compressed_size.round(2)} MB"
    puts "Compression ratio: #{compression_ratio}%"
    puts "File: #{output_file}"
  end
end

namespace :import do
  desc "Import college data from JSON export file"
  task from_json: :environment do
    puts "=== College Data Import Starting ==="
    
    json_file = Rails.root.join('tmp', 'college_data_export.json')
    
    unless File.exist?(json_file)
      puts "Error: #{json_file} not found"
      puts "Please upload the exported JSON file to tmp/ directory"
      exit 1
    end
    
    puts "Reading data from #{json_file}..."
    
    data = JSON.parse(File.read(json_file))
    colleges_data = data['data']
    total_count = colleges_data.size
    
    puts "Found #{total_count} colleges to import"
    puts "Export date: #{data['export_date']}"
    
    imported_count = 0
    error_count = 0
    
    colleges_data.each_with_index do |college_data, index|
      begin
        # 既存のレコードを確認
        existing_college = Condition.find_by(college: college_data['college'])
        
        if existing_college
          # 更新
          existing_college.update!(college_data)
        else
          # 新規作成
          Condition.create!(college_data)
        end
        
        imported_count += 1
        
        if (index + 1) % 100 == 0
          puts "Progress: #{index + 1}/#{total_count} (#{((index + 1).to_f / total_count * 100).round(1)}%)"
        end
        
      rescue => e
        error_count += 1
        puts "Error importing #{college_data['college']}: #{e.message}"
      end
    end
    
    puts "\n=== Import Complete ==="
    puts "Successfully imported: #{imported_count} colleges"
    puts "Errors: #{error_count} colleges"
    puts "Total in database: #{Condition.count} colleges"
  end

  desc "Import college data from compressed JSON export file"
  task from_compressed: :environment do
    require 'zlib'
    
    puts "=== Compressed College Data Import Starting ==="
    
    compressed_file = Rails.root.join('tmp', 'college_data_compressed.json.gz')
    
    unless File.exist?(compressed_file)
      puts "Error: #{compressed_file} not found"
      puts "Please upload the compressed export file to tmp/ directory"
      exit 1
    end
    
    puts "Reading compressed data from #{compressed_file}..."
    
    # 圧縮ファイルを展開
    compressed_data = File.read(compressed_file)
    json_data = Zlib::Inflate.inflate(compressed_data)
    data = JSON.parse(json_data)
    
    colleges_data = data['data']
    total_count = colleges_data.size
    
    puts "Found #{total_count} colleges to import"
    puts "Export date: #{data['export_date']}"
    
    imported_count = 0
    error_count = 0
    
    colleges_data.each_with_index do |college_data, index|
      begin
        # 短縮フィールド名を元に戻す
        full_data = {
          college: college_data['c'],
          state: college_data['s'],
          tuition: college_data['t'],
          students: college_data['st'],
          privateorpublic: college_data['p'],
          GPA: college_data['g'],
          acceptance_rate: college_data['a'],
          graduation_rate: college_data['gr'],
          city: college_data['ci'],
          Division: college_data['d'],
          comment: college_data['co']
        }
        
        # 専攻データを追加（存在する場合）
        if college_data['maj']
          full_data.merge!(college_data['maj'])
        end
        
        # 既存のレコードを確認
        existing_college = Condition.find_by(college: full_data[:college])
        
        if existing_college
          # 更新
          existing_college.update!(full_data)
        else
          # 新規作成
          Condition.create!(full_data)
        end
        
        imported_count += 1
        
        if (index + 1) % 100 == 0
          puts "Progress: #{index + 1}/#{total_count} (#{((index + 1).to_f / total_count * 100).round(1)}%)"
        end
        
      rescue => e
        error_count += 1
        puts "Error importing #{college_data['c']}: #{e.message}"
      end
    end
    
    puts "\n=== Import Complete ==="
    puts "Successfully imported: #{imported_count} colleges"
    puts "Errors: #{error_count} colleges"
    puts "Total in database: #{Condition.count} colleges"
  end
end