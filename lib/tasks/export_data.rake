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
    
    # 必須フィールドのみエクスポート（サイズ削減）
    exported_data = Condition.select(
      :college, :state, :tuition, :students, :privateorpublic, 
      :GPA, :acceptance_rate, :graduation_rate, :city, :Division,
      :comment
    ).map do |college|
      {
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