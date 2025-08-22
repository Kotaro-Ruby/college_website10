# Fix Australian university image URLs for production
# Use direct GitHub URLs for images

puts "🖼️ Fixing Australian university image URLs for production..."

github_base = "https://raw.githubusercontent.com/Kotaro-Ruby/college_website10/main/app/assets/images"

AuUniversity.find_each do |uni|
  if uni.images.present?
    images = JSON.parse(uni.images)
    
    # Convert local paths to GitHub URLs
    updated_images = images.map do |img|
      if img.start_with?('/assets/')
        # Remove /assets/ prefix and add GitHub base URL
        path = img.sub('/assets/', '')
        "#{github_base}/#{path}"
      else
        img
      end
    end
    
    uni.update(images: updated_images.to_json)
    puts "✅ Updated images for #{uni.name}"
  end
end

puts "🎉 Image URLs fixed for production!"