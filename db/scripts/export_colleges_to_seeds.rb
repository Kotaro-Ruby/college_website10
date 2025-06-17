require 'roo'

xlsx = Roo::Spreadsheet.open('college_data_revised5_18_25_5th_copy')  # あなたのファイル名に変更
header = xlsx.row(1)

File.open("db/seeds_data.rb", "w:utf-8") do |file|
  (2..xlsx.last_row).each do |i|
    row = Hash[[header, xlsx.row(i)].transpose]

    next if row['college'].nil? || row['college'].strip == ''

    file.puts <<~RUBY
      College.create!(
        name: "#{row['college']}",
        state: "#{row['state']}",
        students: #{row['students'] || 0},
        category: "#{row['privateorpublic']}",
        acceptance_rate: #{row['acceptance_rate'].to_f},
        city: "#{row['city']}",
        address: "#{row['address']}",
        zip: "#{row['zip']}",
        urbanicity: "#{row['urbanicity']}",
        website: "#{row['website']}",
        school_type: "#{row['school_typ']}",
        graduation_rate: #{row['graduation_r'].to_f}
      )
    RUBY
  end
end

puts "✅ db/seeds_data.rb にエクスポート完了"
