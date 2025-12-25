namespace :deploy do
  desc "Export all data for deployment"
  task export_all: :environment do
    puts "Exporting all data..."
    
    # Export all university data
    data = {
      conditions: Condition.all.as_json,
      au_universities: AuUniversity.all.as_json,
      users: User.all.as_json(except: [:password_digest]),
      created_at: Time.current
    }
    
    # Save to JSON file
    File.write('db/full_backup.json', JSON.pretty_generate(data))
    
    # Compress it
    system("gzip -9 db/full_backup.json")
    
    puts "Data exported to db/full_backup.json.gz"
    puts "Stats:"
    puts "  - Conditions: #{data[:conditions].count}"
    puts "  - AU Universities: #{data[:au_universities].count}"
    puts "  - Users: #{data[:users].count}"
  end
  
  desc "Import all data from backup"
  task import_all: :environment do
    file = 'db/full_backup.json.gz'
    
    unless File.exist?(file)
      puts "Error: Backup file not found: #{file}"
      exit 1
    end
    
    puts "Importing data from #{file}..."
    
    # Decompress and load
    json_data = Zlib::GzipReader.open(file) { |gz| gz.read }
    data = JSON.parse(json_data)
    
    # Import Conditions
    if data['conditions'].present?
      puts "Importing #{data['conditions'].count} conditions..."
      data['conditions'].each do |record|
        Condition.find_or_create_by(id: record['id']) do |c|
          c.attributes = record.except('id', 'created_at', 'updated_at')
        end
      end
    end
    
    # Import AU Universities
    if data['au_universities'].present?
      puts "Importing #{data['au_universities'].count} AU universities..."
      data['au_universities'].each do |record|
        AuUniversity.find_or_create_by(id: record['id']) do |u|
          u.attributes = record.except('id', 'created_at', 'updated_at')
        end
      end
    end
    
    puts "Import completed!"
    puts "Current counts:"
    puts "  - Conditions: #{Condition.count}"
    puts "  - AU Universities: #{AuUniversity.count}"
  end
end