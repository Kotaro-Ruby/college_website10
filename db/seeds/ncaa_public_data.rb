# NCAA Division情報 - 公開情報から手動で収集したデータ
# これらの情報は各大学の公式サイトや NCAA.org から公開されている情報です

# NCAA Division I 大学（主要大学）
division_1_schools = [
  # Big Ten Conference
  { name: "Ohio State University", state: "OH", conference: "Big Ten" },
  { name: "University of Michigan", state: "MI", conference: "Big Ten" },
  { name: "Penn State University", state: "PA", conference: "Big Ten" },
  
  # SEC Conference
  { name: "University of Alabama", state: "AL", conference: "SEC" },
  { name: "University of Florida", state: "FL", conference: "SEC" },
  { name: "University of Georgia", state: "GA", conference: "SEC" },
  
  # Pac-12 Conference
  { name: "Stanford University", state: "CA", conference: "Pac-12" },
  { name: "University of California, Berkeley", state: "CA", conference: "Pac-12" },
  { name: "UCLA", state: "CA", conference: "Pac-12" },
  
  # Ivy League
  { name: "Harvard University", state: "MA", conference: "Ivy League" },
  { name: "Yale University", state: "CT", conference: "Ivy League" },
  { name: "Princeton University", state: "NJ", conference: "Ivy League" },
]

# NCAA Division III 大学（学術重視）
division_3_schools = [
  { name: "MIT", state: "MA", conference: "NEWMAC" },
  { name: "University of Chicago", state: "IL", conference: "UAA" },
  { name: "Johns Hopkins University", state: "MD", conference: "Centennial" },
]

# データベースに追加
puts "Adding NCAA Division I schools..."
division_1_schools.each do |school|
  condition = Condition.find_by("LOWER(college) LIKE ?", "%#{school[:name].downcase}%")
  if condition
    condition.update(Division: "Division I")
    puts "Updated #{school[:name]} - Division I, #{school[:conference]}"
  end
end

puts "\nAdding NCAA Division III schools..."
division_3_schools.each do |school|
  condition = Condition.find_by("LOWER(college) LIKE ?", "%#{school[:name].downcase}%")
  if condition
    condition.update(Division: "Division III")
    puts "Updated #{school[:name]} - Division III, #{school[:conference]}"
  end
end

# スポーツをしていない大学
no_athletics = [
  "California Institute of Technology",
  "Rockefeller University",
  "Curtis Institute of Music"
]

puts "\nMarking schools with no athletics program..."
no_athletics.each do |school_name|
  condition = Condition.find_by("LOWER(college) LIKE ?", "%#{school_name.downcase}%")
  if condition
    condition.update(Division: "N/A")
    puts "Updated #{school_name} - No athletics program"
  end
end