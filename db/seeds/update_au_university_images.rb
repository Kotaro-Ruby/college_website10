# Update AU Universities with image data

# Macquarie University
macquarie = AuUniversity.find_by(id: 397)
if macquarie
  macquarie.update!(
    images: [
      '/assets/au/universities/macquarie-university.jpg',
      '/assets/au/universities/macquarie-university-2.jpg', 
      '/assets/au/universities/macquarie-university-3.jpg'
    ].to_json,
    image_credits: [
      'Photo by Fidel Fernando on Unsplash',
      'Photo by Fidel Fernando on Unsplash',
      'Photo by Fidel Fernando on Unsplash'
    ].to_json
  )
  puts "Updated Macquarie University with images"
end

# The University of Sydney
sydney = AuUniversity.find_by(id: 403)
if sydney
  sydney.update!(
    images: ['/assets/au/universities/university-of-sydney.jpg'].to_json,
    image_credits: ['Photo by Andy Wang on Unsplash'].to_json
  )
  puts "Updated The University of Sydney with images"
end

puts "Image data update completed"