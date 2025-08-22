# Fix Australian university image URLs for production
# Use direct GitHub URLs for images

puts "🖼️ Fixing Australian university image URLs for production..."

github_base = "https://raw.githubusercontent.com/Kotaro-Ruby/college_website10/main/app/assets/images"

# Force update for specific universities with known images
uni_images = {
  'Macquarie University' => [
    'au/universities/macquarie-university.jpg',
    'au/universities/macquarie-university-2.jpg',
    'au/universities/macquarie-university-3.jpg'
  ],
  'The University of Sydney' => ['au/universities/university-of-sydney.jpg'],
  'Bond University' => ['au/universities/bond-university.jpg'],
  'Australian Catholic University' => ['au/universities/australian-catholic-university.jpg']
}

uni_images.each do |name, images|
  uni = AuUniversity.find_by(name: name)
  if uni
    github_urls = images.map { |img| "#{github_base}/#{img}" }
    uni.update!(images: github_urls.to_json)
    puts "✅ Updated #{name} with GitHub URLs"
  end
end

puts "🎉 Image URLs fixed for production!"