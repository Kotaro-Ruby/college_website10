namespace :backup do
  desc "Create a full backup of all college data"
  task create: :environment do
    require 'json'
    
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    backup_dir = Rails.root.join('backups')
    FileUtils.mkdir_p(backup_dir)
    
    # SQLite database backup (development)
    if Rails.env.development? && File.exist?(Rails.root.join('db', 'development.sqlite3'))
      puts "📁 Backing up SQLite database..."
      FileUtils.cp(
        Rails.root.join('db', 'development.sqlite3'),
        backup_dir.join("development_#{timestamp}.sqlite3")
      )
    end
    
    # JSON backup (all environments)
    puts "📊 Creating JSON backup of all data..."
    backup_data = {
      metadata: {
        created_at: Time.current.iso8601,
        rails_env: Rails.env,
        record_counts: {
          conditions: Condition.count,
          detailed_programs: DetailedProgram.count,
          users: User.count,
          survey_responses: SurveyResponse.count,
          blogs: Blog.count
        }
      },
      conditions: Condition.all.as_json,
      detailed_programs: DetailedProgram.all.as_json,
      users: User.all.as_json(except: [:password_digest]),
      survey_responses: SurveyResponse.all.as_json,
      blogs: Blog.all.as_json
    }
    
    json_file = backup_dir.join("full_backup_#{timestamp}.json")
    File.write(json_file, JSON.pretty_generate(backup_data))
    
    # Compress if large
    if File.size(json_file) > 10.megabytes
      puts "🗜️  Compressing backup..."
      system("gzip '#{json_file}'")
      json_file = backup_dir.join("full_backup_#{timestamp}.json.gz")
    end
    
    puts "✅ Backup completed: #{json_file}"
    puts "📦 File size: #{(File.size(json_file) / 1.megabyte.to_f).round(2)} MB"
    
    # Clean old backups (keep last 5)
    all_backups = Dir[backup_dir.join('*.{json,json.gz,sqlite3}')].sort
    if all_backups.size > 5
      puts "🧹 Cleaning old backups..."
      all_backups[0...-5].each do |old_backup|
        File.delete(old_backup)
        puts "  Deleted: #{File.basename(old_backup)}"
      end
    end
  end
  
  desc "Restore data from a backup file"
  task :restore, [:backup_file] => :environment do |t, args|
    unless args[:backup_file]
      puts "❌ Please specify a backup file:"
      puts "   rails backup:restore[backups/full_backup_20250708_120000.json]"
      exit 1
    end
    
    backup_path = Rails.root.join(args[:backup_file])
    unless File.exist?(backup_path)
      puts "❌ Backup file not found: #{backup_path}"
      exit 1
    end
    
    puts "⚠️  WARNING: This will restore data from backup!"
    puts "Current data counts:"
    puts "  Conditions: #{Condition.count}"
    puts "  Users: #{User.count}"
    puts "  Survey Responses: #{SurveyResponse.count}"
    
    print "\nContinue? (yes/no): "
    response = STDIN.gets.chomp
    exit unless response.downcase == 'yes'
    
    puts "🔄 Restoring from backup..."
    
    # Read backup file
    data = if backup_path.to_s.end_with?('.gz')
             require 'zlib'
             JSON.parse(Zlib::GzipReader.open(backup_path) { |gz| gz.read })
           else
             JSON.parse(File.read(backup_path))
           end
    
    # Restore data (careful not to duplicate)
    ActiveRecord::Base.transaction do
      # Restore conditions
      if data['conditions']
        puts "📚 Restoring #{data['conditions'].size} colleges..."
        data['conditions'].each do |condition_data|
          condition_data.delete('id')
          Condition.find_or_create_by(slug: condition_data['slug']) do |c|
            c.assign_attributes(condition_data)
          end
        end
      end
      
      # Add more restoration logic as needed...
    end
    
    puts "✅ Restore completed!"
    puts "New data counts:"
    puts "  Conditions: #{Condition.count}"
  end

  desc "Export college data to Google Drive compatible format"
  task export_for_cloud: :environment do
    puts "☁️  Creating cloud-ready backup..."
    
    timestamp = Time.current.strftime('%Y%m%d')
    
    # Create CSV for easy viewing in Google Sheets
    csv_file = Rails.root.join('backups', "colleges_backup_#{timestamp}.csv")
    FileUtils.mkdir_p(Rails.root.join('backups'))
    
    require 'csv'
    CSV.open(csv_file, 'w', write_headers: true, headers: Condition.column_names) do |csv|
      Condition.find_each do |condition|
        csv << condition.attributes.values
      end
    end
    
    puts "✅ CSV backup created: #{csv_file}"
    puts "📤 You can upload this to:"
    puts "   - Google Drive"
    puts "   - Dropbox" 
    puts "   - iCloud"
    puts "   - External HDD"
  end
end