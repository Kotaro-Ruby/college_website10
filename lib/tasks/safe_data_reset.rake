namespace :db do
  desc "Safely reset data with foreign key constraint handling"
  task safe_reset_conditions: :environment do
    puts "🔄 Safely resetting conditions data..."
    
    begin
      # First delete dependent records to avoid foreign key violations
      puts "Deleting favorites..."
      Favorite.delete_all
      
      puts "Deleting conditions..."
      Condition.delete_all
      
      puts "✅ Data reset completed successfully"
    rescue => e
      puts "❌ Error during data reset: #{e.message}"
      # Continue with deployment even if reset fails
      puts "Continuing with deployment..."
    end
  end
end