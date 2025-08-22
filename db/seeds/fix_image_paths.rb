# Fix image paths for production environment
# Add /assets/ prefix to all image paths

AuUniversity.where.not(images: nil).find_each do |university|
  begin
    images = JSON.parse(university.images)
    
    # Add /assets/ prefix if not already present
    updated_images = images.map do |image_path|
      if image_path.start_with?('/assets/')
        image_path
      else
        "/assets/#{image_path}"
      end
    end
    
    university.update!(images: updated_images.to_json)
    puts "Updated #{university.name}: #{updated_images.join(', ')}"
  rescue JSON::ParserError => e
    puts "Error parsing images for #{university.name}: #{e.message}"
  end
end

puts "Image paths update completed!"