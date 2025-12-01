namespace :comments do
  desc "Import college comments from JSON file"
  task import: :environment do
    require 'json'

    json_path = Rails.root.join('db', 'seeds', 'comments_data.json')

    unless File.exist?(json_path)
      puts "エラー: #{json_path} が見つかりません"
      exit 1
    end

    comments_data = JSON.parse(File.read(json_path))
    puts "=== コメントインポート開始 ==="
    puts "インポート対象: #{comments_data.count}件"

    updated = 0
    not_found = 0

    comments_data.each do |college_name, comment|
      college = Condition.find_by(college: college_name)

      if college
        college.update(comment: comment)
        updated += 1
        print "." if updated % 10 == 0
      else
        not_found += 1
        puts "\n見つからない: #{college_name}"
      end
    end

    puts "\n=== インポート完了 ==="
    puts "更新: #{updated}件"
    puts "見つからない: #{not_found}件"
  end
end
