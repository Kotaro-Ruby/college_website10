namespace :setup do
  desc "Setup production database with all necessary data"
  task production: :environment do
    puts "🚀 Starting production setup..."
    
    # 1. Run pending migrations
    puts "📊 Running migrations..."
    Rake::Task['db:migrate'].invoke
    
    # 2. Check and import US universities
    if Condition.count == 0
      puts "🇺🇸 Importing US universities..."
      if File.exist?('db/college_data_compressed.json.gz')
        Rake::Task['import:from_compressed'].invoke
      elsif File.exist?('data/colleges_data.csv')
        Rake::Task['db:seed'].invoke
      end
    else
      puts "✅ US universities already exist (#{Condition.count} records)"
      
      # 詳細データが不足している場合は強制更新
      if Condition.where.not(percent_white: nil).count < 100
        puts "📊 Force updating US universities with all data..."
        Rake::Task['import:force_update_all'].invoke
      elsif Condition.where.not(percent_white: nil).count < 4000
        puts "📊 Updating US universities with detailed data..."
        Rake::Task['import:update_detailed_data'].invoke
      end
    end
    
    # 3. Check and import Australian universities
    if AuUniversity.count == 0
      puts "🇦🇺 Importing Australian universities..."
      load Rails.root.join('db/seeds/australia_data.rb')
    else
      puts "✅ Australian universities already exist (#{AuUniversity.count} records)"
    end
    
    # 3.5. Update Australian university images
    if AuUniversity.exists? && AuUniversity.where.not(images: nil).count == 0
      puts "🖼️ Adding images to Australian universities..."
      load Rails.root.join('db/seeds/update_au_university_images.rb')
    end
    
    # 4. Check and import New Zealand universities (future)
    if defined?(NzUniversity) && NzUniversity.count == 0
      nz_seed = Rails.root.join('db/seeds/nz_data.rb')
      if File.exist?(nz_seed)
        puts "🇳🇿 Importing New Zealand universities..."
        load nz_seed
      end
    end
    
    # 5. Check and import Canadian universities (future)
    if defined?(CaUniversity) && CaUniversity.count == 0
      ca_seed = Rails.root.join('db/seeds/canada_data.rb')
      if File.exist?(ca_seed)
        puts "🇨🇦 Importing Canadian universities..."
        load ca_seed
      end
    end
    
    # 6. Fix image URLs for production (always run in production)
    if Rails.env.production?
      puts "🔧 Ensuring image URLs are production-ready..."
      load Rails.root.join('db/seeds/fix_au_image_urls.rb')
      
      puts "🖼️ Updating WikiCommons images for AU universities..."
      load Rails.root.join('db/seeds/update_au_wiki_images.rb')
    end
    
    # 7. Run any custom setup scripts
    setup_dir = Rails.root.join('db/setup')
    if Dir.exist?(setup_dir)
      Dir[setup_dir.join('*.rb')].sort.each do |file|
        puts "📝 Running setup script: #{File.basename(file)}"
        load file
      end
    end
    
    puts "✨ Production setup completed!"
    puts "📊 Final counts:"
    puts "  - US Universities: #{Condition.count}"
    puts "  - AU Universities: #{AuUniversity.count}" if defined?(AuUniversity)
    puts "  - NZ Universities: #{NzUniversity.count}" if defined?(NzUniversity) && NzUniversity.table_exists?
    puts "  - CA Universities: #{CaUniversity.count}" if defined?(CaUniversity) && CaUniversity.table_exists?
  end
  
  desc "Quick health check"
  task health: :environment do
    puts "🏥 Health Check:"
    puts "  - Database: #{ActiveRecord::Base.connection.active? ? '✅ Connected' : '❌ Not connected'}"
    puts "  - Tables: #{ActiveRecord::Base.connection.tables.count} tables"
    puts "  - US Unis: #{Condition.count rescue 0}"
    puts "  - AU Unis: #{AuUniversity.count rescue 0}"
    puts "  - Users: #{User.count rescue 0}"
  end
end