# Fix Australian university image URLs for production
# Use public folder URLs for images

puts "🖼️ Fixing Australian university image URLs for production..."

# Force update for specific universities with known images
uni_images = {
  'Macquarie University' => [
    '/images/au/universities/macquarie-university.jpg',
    '/images/au/universities/macquarie-university-2.jpg',
    '/images/au/universities/macquarie-university-3.jpg'
  ],
  'The University of Sydney' => ['/images/au/universities/university-of-sydney.jpg'],
  'Bond University' => ['/images/au/universities/bond-university.jpg'],
  'Australian Catholic University' => ['/images/au/universities/australian-catholic-university.jpg'],
  'RMIT University' => [
    '/images/au/universities/rmit-university.jpg',
    '/images/au/universities/rmit-university-2.jpg'
  ],
  'Queensland University of Technology' => ['/images/au/universities/queensland-university-of-technology.jpg']
}

uni_images.each do |name, images|
  uni = AuUniversity.find_by(name: name)
  if uni
    uni.update!(images: images.to_json)
    puts "✅ Updated #{name} with public URLs"
  end
end

puts "🎉 Image URLs fixed for production!"