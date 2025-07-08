namespace :data do
  desc "Export college data to CSV (read-only operation)"
  task export_colleges: :environment do
    require 'csv'
    
    filename = "colleges_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"
    filepath = Rails.root.join('tmp', filename)
    
    puts "Exporting #{Condition.count} colleges to #{filepath}..."
    
    CSV.open(filepath, 'w', write_headers: true, headers: Condition.column_names) do |csv|
      Condition.find_each(batch_size: 100) do |condition|
        csv << condition.attributes.values
      end
    end
    
    puts "Export completed: #{filepath}"
    puts "File size: #{File.size(filepath)} bytes"
  end

  desc "Export detailed_programs data to CSV (read-only operation)"
  task export_programs: :environment do
    require 'csv'
    
    filename = "detailed_programs_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"
    filepath = Rails.root.join('tmp', filename)
    
    puts "Exporting #{DetailedProgram.count} programs to #{filepath}..."
    
    CSV.open(filepath, 'w', write_headers: true, headers: DetailedProgram.column_names) do |csv|
      DetailedProgram.find_each(batch_size: 100) do |program|
        csv << program.attributes.values
      end
    end
    
    puts "Export completed: #{filepath}"
    puts "File size: #{File.size(filepath)} bytes"
  end
  
  desc "Export all college-related data"
  task export_all: [:export_colleges, :export_programs] do
    puts "All college data exported successfully!"
  end
end