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

namespace :translations do
  desc "Import university translations from JSON file"
  task import: :environment do
    require 'json'

    json_path = Rails.root.join('db', 'seeds', 'translations_data.json')

    unless File.exist?(json_path)
      puts "エラー: #{json_path} が見つかりません"
      exit 1
    end

    translations_data = JSON.parse(File.read(json_path))
    puts "=== 翻訳インポート開始 ==="
    puts "インポート対象: #{translations_data.count}件"

    created = 0
    updated = 0
    not_found = 0

    translations_data.each do |data|
      college = Condition.find_by(college: data['college'])

      if college
        translation = UniversityTranslation.find_or_initialize_by(
          condition_id: college.id,
          locale: data['locale']
        )
        translation.name = data['name']

        if translation.new_record?
          translation.save
          created += 1
        else
          translation.save
          updated += 1
        end
        print "." if (created + updated) % 10 == 0
      else
        not_found += 1
        puts "\n見つからない: #{data['college']}"
      end
    end

    puts "\n=== インポート完了 ==="
    puts "新規作成: #{created}件"
    puts "更新: #{updated}件"
    puts "見つからない: #{not_found}件"
  end
end

namespace :data do
  desc "Import all data (comments and translations)"
  task import_all: :environment do
    Rake::Task['comments:import'].invoke
    Rake::Task['translations:import'].invoke
  end
end
