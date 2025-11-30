# Auto-import college data if none exists (for production deployment)
if Condition.count == 0 && File.exist?(Rails.root.join('data', 'colleges_data.csv'))
  puts "🏫 No college data found. Auto-importing from CSV..."

  require 'csv'
  imported_count = 0

  CSV.foreach(Rails.root.join('data', 'colleges_data.csv'), headers: true, header_converters: :symbol) do |row|
    begin
      attributes = row.to_hash
      attributes.delete(:id)

      # Handle boolean fields
      %i[hbcu tribal hsi women_only men_only].each do |bool_field|
        if attributes[bool_field]
          attributes[bool_field] = ActiveModel::Type::Boolean.new.cast(attributes[bool_field])
        end
      end

      # Handle numeric fields - convert empty strings to nil
      # Note: CSV has 'GPA' but database has 'gpa' - handle the mapping
      if attributes[:gpa]
        attributes[:gpa] = attributes[:gpa]
      elsif attributes[:GPA]
        attributes[:gpa] = attributes[:GPA]
        attributes.delete(:GPA)
      end

      numeric_fields = %i[tuition students gpa acceptance_rate graduation_rate retention_rate
                         sat_math_25 sat_math_75 sat_reading_25 sat_reading_75
                         act_composite_25 act_composite_75 earnings_6yr_median earnings_10yr_median
                         pell_grant_rate federal_loan_rate median_debt
                         net_price_0_30k net_price_30_48k net_price_48_75k net_price_75_110k net_price_110k_plus
                         percent_white percent_black percent_hispanic percent_asian percent_men percent_women
                         faculty_salary room_board_cost tuition_in_state tuition_out_state
                         religious_affiliation carnegie_basic locale percent_non_resident_alien]

      numeric_fields.each do |field|
        if attributes[field] && attributes[field] != ''
          attributes[field] = attributes[field].to_f
        else
          attributes[field] = nil
        end
      end

      # Handle decimal fields for PCIP percentages
      pcip_fields = %i[pcip_agriculture pcip_natural_resources pcip_communication pcip_computer_science
                      pcip_education pcip_engineering pcip_foreign_languages pcip_english pcip_biology
                      pcip_mathematics pcip_psychology pcip_sociology pcip_social_sciences pcip_visual_arts
                      pcip_business pcip_health_professions pcip_history pcip_philosophy pcip_physical_sciences pcip_law]

      pcip_fields.each do |field|
        if attributes[field] && attributes[field] != ''
          attributes[field] = BigDecimal(attributes[field].to_s)
        else
          attributes[field] = nil
        end
      end

      Condition.create!(attributes)
      imported_count += 1

      if imported_count % 500 == 0
        puts "📊 Imported #{imported_count} colleges..."
      end

    rescue => e
      puts "❌ Error importing college: #{e.message}"
    end
  end

  puts "✅ College data import completed! Total: #{Condition.count} colleges"
else
  puts "📚 College data already exists (#{Condition.count} colleges)"
end

# Import Country data from REST Countries API
if Country.count == 0
  puts "\n🌍 Importing country data from REST Countries API..."
  if CountryApiService.fetch_and_update_countries
    count = Country.count
    puts "✅ Successfully imported #{count} countries (US, AU, NZ, CA)"
  else
    puts "⚠️  Failed to import country data - will retry on next deploy"
  end
else
  puts "🌍 Country data already exists (#{Country.count} countries)"
end

# Import Australian University data
if AuUniversity.count == 0
  puts "\n🇦🇺 Importing Australian University data..."
  load Rails.root.join('db', 'seeds', 'australia_data.rb')
else
  puts "🇦🇺 Australian university data already exists (#{AuUniversity.count} universities)"
end

# 有名大学の日本語名を投入
puts "\n🇯🇵 Importing Japanese university names..."

UNIVERSITY_NAMES_JA = {
  # Ivy League
  "Harvard University" => "ハーバード大学",
  "Yale University" => "イェール大学",
  "Princeton University" => "プリンストン大学",
  "Columbia University in the City of New York" => "コロンビア大学",
  "University of Pennsylvania" => "ペンシルベニア大学",
  "Brown University" => "ブラウン大学",
  "Dartmouth College" => "ダートマス大学",
  "Cornell University" => "コーネル大学",

  # Top Private Universities
  "Stanford University" => "スタンフォード大学",
  "Massachusetts Institute of Technology" => "マサチューセッツ工科大学（MIT）",
  "California Institute of Technology" => "カリフォルニア工科大学（Caltech）",
  "Duke University" => "デューク大学",
  "Northwestern University" => "ノースウェスタン大学",
  "Johns Hopkins University" => "ジョンズ・ホプキンス大学",
  "University of Chicago" => "シカゴ大学",
  "Vanderbilt University" => "ヴァンダービルト大学",
  "Rice University" => "ライス大学",
  "Washington University in St Louis" => "ワシントン大学セントルイス",
  "University of Notre Dame" => "ノートルダム大学",
  "Emory University" => "エモリー大学",
  "Georgetown University" => "ジョージタウン大学",
  "Carnegie Mellon University" => "カーネギーメロン大学",
  "University of Southern California" => "南カリフォルニア大学（USC）",
  "New York University" => "ニューヨーク大学（NYU）",
  "Boston University" => "ボストン大学",
  "Boston College" => "ボストンカレッジ",
  "Tufts University" => "タフツ大学",
  "Wake Forest University" => "ウェイクフォレスト大学",
  "Brandeis University" => "ブランダイス大学",
  "Case Western Reserve University" => "ケースウェスタンリザーブ大学",
  "Northeastern University" => "ノースイースタン大学",
  "Tulane University of Louisiana" => "チューレーン大学",
  "Pepperdine University" => "ペパーダイン大学",
  "University of Miami" => "マイアミ大学",
  "George Washington University" => "ジョージ・ワシントン大学",
  "Syracuse University" => "シラキュース大学",
  "Fordham University" => "フォーダム大学",
  "University of Rochester" => "ロチェスター大学",
  "Rensselaer Polytechnic Institute" => "レンセラー工科大学",
  "Santa Clara University" => "サンタクララ大学",
  "Villanova University" => "ヴィラノバ大学",
  "Lehigh University" => "リーハイ大学",
  "Stevens Institute of Technology" => "スティーブンス工科大学",
  "Southern Methodist University" => "サザンメソジスト大学",
  "Loyola Marymount University" => "ロヨラメリーマウント大学",

  # UC System
  "University of California-Berkeley" => "カリフォルニア大学バークレー校（UCバークレー）",
  "University of California-Los Angeles" => "カリフォルニア大学ロサンゼルス校（UCLA）",
  "University of California-San Diego" => "カリフォルニア大学サンディエゴ校",
  "University of California-Santa Barbara" => "カリフォルニア大学サンタバーバラ校",
  "University of California-Irvine" => "カリフォルニア大学アーバイン校",
  "University of California-Davis" => "カリフォルニア大学デービス校",
  "University of California-Santa Cruz" => "カリフォルニア大学サンタクルーズ校",
  "University of California-Riverside" => "カリフォルニア大学リバーサイド校",
  "University of California-Merced" => "カリフォルニア大学マーセド校",

  # Big Ten & Major State Universities
  "University of Michigan-Ann Arbor" => "ミシガン大学アナーバー校",
  "University of Wisconsin-Madison" => "ウィスコンシン大学マディソン校",
  "University of Illinois Urbana-Champaign" => "イリノイ大学アーバナ・シャンペーン校",
  "Pennsylvania State University-Main Campus" => "ペンシルベニア州立大学",
  "Ohio State University-Main Campus" => "オハイオ州立大学",
  "University of Minnesota-Twin Cities" => "ミネソタ大学ツインシティーズ校",
  "Purdue University-Main Campus" => "パデュー大学",
  "Indiana University-Bloomington" => "インディアナ大学ブルーミントン校",
  "University of Iowa" => "アイオワ大学",
  "Michigan State University" => "ミシガン州立大学",
  "Rutgers University-New Brunswick" => "ラトガース大学",
  "University of Maryland-College Park" => "メリーランド大学カレッジパーク校",
  "University of Nebraska-Lincoln" => "ネブラスカ大学リンカーン校",

  # Other Major State Universities
  "University of Virginia-Main Campus" => "バージニア大学",
  "University of North Carolina at Chapel Hill" => "ノースカロライナ大学チャペルヒル校",
  "University of Florida" => "フロリダ大学",
  "University of Texas at Austin" => "テキサス大学オースティン校",
  "Georgia Institute of Technology-Main Campus" => "ジョージア工科大学",
  "University of Washington-Seattle Campus" => "ワシントン大学シアトル校",
  "University of Colorado Boulder" => "コロラド大学ボルダー校",
  "University of Georgia" => "ジョージア大学",
  "Florida State University" => "フロリダ州立大学",
  "University of Arizona" => "アリゾナ大学",
  "Arizona State University-Tempe" => "アリゾナ州立大学",
  "University of Pittsburgh-Pittsburgh Campus" => "ピッツバーグ大学",
  "University of Connecticut" => "コネチカット大学",
  "University of Utah" => "ユタ大学",
  "University of Oregon" => "オレゴン大学",
  "Oregon State University" => "オレゴン州立大学",
  "Colorado State University-Fort Collins" => "コロラド州立大学",
  "University of South Carolina-Columbia" => "サウスカロライナ大学",
  "University of Tennessee-Knoxville" => "テネシー大学ノックスビル校",
  "University of Kentucky" => "ケンタッキー大学",
  "University of Alabama" => "アラバマ大学",
  "Louisiana State University and Agricultural & Mechanical College" => "ルイジアナ州立大学",
  "University of Kansas" => "カンザス大学",
  "University of Missouri-Columbia" => "ミズーリ大学",
  "University of Oklahoma-Norman Campus" => "オクラホマ大学",
  "University of Arkansas" => "アーカンソー大学",
  "University of Mississippi" => "ミシシッピ大学",
  "University of Hawaii at Manoa" => "ハワイ大学マノア校",
  "Brigham Young University-Provo" => "ブリガムヤング大学",

  # CSU System
  "California State University-Long Beach" => "カリフォルニア州立大学ロングビーチ校",
  "California State University-Fullerton" => "カリフォルニア州立大学フラートン校",
  "San Diego State University" => "サンディエゴ州立大学",
  "San Jose State University" => "サンノゼ州立大学",
  "California State University-Northridge" => "カリフォルニア州立大学ノースリッジ校",
  "California Polytechnic State University-San Luis Obispo" => "カリフォルニアポリテクニック州立大学",
  "California State University-Los Angeles" => "カリフォルニア州立大学ロサンゼルス校",
  "San Francisco State University" => "サンフランシスコ州立大学",

  # SUNY System
  "Stony Brook University" => "ストーニーブルック大学",
  "University at Buffalo" => "ニューヨーク州立大学バッファロー校",
  "Binghamton University" => "ビンガムトン大学",
  "University at Albany" => "ニューヨーク州立大学オールバニー校",

  # Liberal Arts Colleges
  "Williams College" => "ウィリアムズ大学",
  "Amherst College" => "アマースト大学",
  "Swarthmore College" => "スワースモア大学",
  "Wellesley College" => "ウェルズリー大学",
  "Pomona College" => "ポモナ大学",
  "Bowdoin College" => "ボウディン大学",
  "Middlebury College" => "ミドルベリー大学",
  "Carleton College" => "カールトン大学",
  "Claremont McKenna College" => "クレアモントマッケナ大学",
  "Haverford College" => "ハバフォード大学",
  "Vassar College" => "ヴァッサー大学",
  "Colgate University" => "コルゲート大学",
  "Hamilton College" => "ハミルトン大学",
  "Wesleyan University" => "ウェズリアン大学",
  "Grinnell College" => "グリネル大学",
  "Barnard College" => "バーナード大学",
  "Smith College" => "スミス大学",
  "Oberlin College" => "オーバリン大学",
  "Colorado College" => "コロラドカレッジ",
  "Bryn Mawr College" => "ブリンマー大学",

  # Art & Design Schools
  "Rhode Island School of Design" => "ロードアイランド・スクール・オブ・デザイン",
  "Pratt Institute-Main" => "プラット・インスティテュート",
  "California Institute of the Arts" => "カリフォルニア芸術大学",
  "Savannah College of Art and Design" => "サバンナ芸術大学",
  "Fashion Institute of Technology" => "ファッション工科大学",

  # Music Schools
  "The Juilliard School" => "ジュリアード音楽院",
  "Berklee College of Music" => "バークリー音楽大学",
  "New England Conservatory of Music" => "ニューイングランド音楽院",
  "Manhattan School of Music" => "マンハッタン音楽院",
  "Curtis Institute of Music" => "カーティス音楽院",

  # Engineering & Business
  "Chapman University" => "チャップマン大学",
  "Babson College" => "バブソン大学",
  "Bentley University" => "ベントレー大学",
  "Worcester Polytechnic Institute" => "ウースター工科大学",
  "Illinois Institute of Technology" => "イリノイ工科大学",
  "Rose-Hulman Institute of Technology" => "ローズハルマン工科大学",
  "Harvey Mudd College" => "ハーヴェイマッド大学",
  "Cooper Union for the Advancement of Science and Art" => "クーパー・ユニオン",
  "Virginia Polytechnic Institute and State University" => "バージニア工科大学",
  "Texas A & M University-College Station" => "テキサスA&M大学",

  # HBCUs
  "Howard University" => "ハワード大学",
  "Spelman College" => "スペルマン大学",
  "Morehouse College" => "モアハウス大学",
  "Hampton University" => "ハンプトン大学",
  "Fisk University" => "フィスク大学",
  "Tuskegee University" => "タスキーギー大学",

  # 特別枠
  "Ohio Northern University" => "オハイオノーザン大学",
}

success_count = 0
UNIVERSITY_NAMES_JA.each do |english_name, japanese_name|
  condition = Condition.find_by(college: english_name)
  next unless condition

  translation = UniversityTranslation.find_or_initialize_by(
    condition: condition,
    locale: 'ja'
  )
  translation.name = japanese_name
  if translation.save
    success_count += 1
  end
end

puts "✅ Japanese university names imported: #{success_count} universities"
