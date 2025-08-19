# NCAA Division情報を追加するスクリプト
# このファイルは手動で大学のNCAA情報を追加するためのサンプルです

ncaa_data = [
  { college_name: "Ohio State University", ncaa_division: "Division I", conference: "Big Ten" },
  { college_name: "University of Alabama", ncaa_division: "Division I", conference: "SEC" },
  { college_name: "Stanford University", ncaa_division: "Division I", conference: "Pac-12" },
  { college_name: "MIT", ncaa_division: "Division III", conference: "NEWMAC" }
  # 他の大学のデータを追加...
]

ncaa_data.each do |data|
  condition = Condition.find_by(college: data[:college_name])
  if condition
    condition.update(
      Division: data[:ncaa_division],
      conference: data[:conference] # conferenceカラムが必要な場合は追加
    )
    puts "Updated #{data[:college_name]} with NCAA info"
  else
    puts "Could not find #{data[:college_name]}"
  end
end
