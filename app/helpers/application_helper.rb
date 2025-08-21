module ApplicationHelper
  def translate_state(state_code)
    state_translations = {
      "AL" => "アラバマ州",
      "AK" => "アラスカ州",
      "AZ" => "アリゾナ州",
      "AR" => "アーカンソー州",
      "CA" => "カリフォルニア州",
      "CO" => "コロラド州",
      "CT" => "コネチカット州",
      "DE" => "デラウェア州",
      "DC" => "ワシントンD.C.",
      "FL" => "フロリダ州",
      "GA" => "ジョージア州",
      "HI" => "ハワイ州",
      "ID" => "アイダホ州",
      "IL" => "イリノイ州",
      "IN" => "インディアナ州",
      "IA" => "アイオワ州",
      "KS" => "カンザス州",
      "KY" => "ケンタッキー州",
      "LA" => "ルイジアナ州",
      "ME" => "メイン州",
      "MD" => "メリーランド州",
      "MA" => "マサチューセッツ州",
      "MI" => "ミシガン州",
      "MN" => "ミネソタ州",
      "MS" => "ミシシッピ州",
      "MO" => "ミズーリ州",
      "MT" => "モンタナ州",
      "NE" => "ネブラスカ州",
      "NV" => "ネバダ州",
      "NH" => "ニューハンプシャー州",
      "NJ" => "ニュージャージー州",
      "NM" => "ニューメキシコ州",
      "NY" => "ニューヨーク州",
      "NC" => "ノースカロライナ州",
      "ND" => "ノースダコタ州",
      "OH" => "オハイオ州",
      "OK" => "オクラホマ州",
      "OR" => "オレゴン州",
      "PA" => "ペンシルベニア州",
      "PR" => "プエルトリコ",
      "RI" => "ロードアイランド州",
      "SC" => "サウスカロライナ州",
      "SD" => "サウスダコタ州",
      "TN" => "テネシー州",
      "TX" => "テキサス州",
      "UT" => "ユタ州",
      "VT" => "バーモント州",
      "VA" => "バージニア州",
      "VI" => "バージン諸島",
      "WA" => "ワシントン州",
      "WV" => "ウェストバージニア州",
      "WI" => "ウィスコンシン州",
      "WY" => "ワイオミング州",
      "GU" => "グアム",
      "AS" => "アメリカ領サモア",
      "MP" => "北マリアナ諸島"
    }

    state_translations[state_code] || "#{state_code}州"
  end

  def is_search_section?
    # Direct search-related paths
    search_paths = [ "/search", "/results" ]
    return true if search_paths.include?(request.path)

    # Result pages with ID parameter
    return true if request.path.start_with?("/result/")

    # Specific college pages
    specific_colleges = [
      "/ohio_northern_university",
      "/ohio_state_university",
      "/florida_state_university",
      "/alabama_state_university"
    ]
    return true if specific_colleges.include?(request.path)

    # Fallback: any path that doesn't match known sections
    # This handles the catch-all route that goes to conditions#fallback_page
    known_sections = [
      "/", "/about", "/info", "/contact", "/terms", "/recruit",
      "/canada", "/australia", "/newzealand",
      "/study_abroad_types", "/scholarships", "/visa_guide", "/english_tests",
      "/majors_careers", "/life_guide", "/why_study_abroad", "/knowledge", "/degreeseeking",
      "/login", "/register", "/logout", "/profile", "/favorites", "/compare"
    ]

    known_prefixes = [
      "/blogs", "/columns", "/p/", "/states", "/admin", "/profile/", "/password_resets"
    ]

    # If it's not in known sections and doesn't start with known prefixes, it's likely a college page
    return false if known_sections.include?(request.path)
    return false if known_prefixes.any? { |prefix| request.path.start_with?(prefix) }

    # If we get here, it's likely a college page handled by the fallback route
    true
  end

  def is_blog_section?
    request.path.start_with?("/blogs")
  end

  def is_column_section?
    request.path.start_with?("/columns") || request.path.start_with?("/p/")
  end

  def is_states_section?
    request.path.start_with?("/states")
  end

  def translate_au_field(field_name)
    # 番号を削除して分野名のみを取得
    clean_field_name = field_name.to_s.gsub(/^\d+\s*-\s*/, '')
    
    field_translations = {
      "Natural and Physical Sciences" => "自然科学・物理科学",
      "Information Technology" => "情報技術",
      "Engineering and Related Technologies" => "工学・関連技術",
      "Architecture and Building" => "建築・建設",
      "Agriculture, Environmental and Related Studies" => "農業・環境・関連研究",
      "Health" => "健康・医療",
      "Education" => "教育",
      "Management and Commerce" => "経営・商学",
      "Society and Culture" => "社会・文化",
      "Creative Arts" => "創造芸術",
      "Food, Hospitality and Personal Services" => "食品・ホスピタリティ・個人サービス",
      "Mixed Field Programmes" => "複合分野プログラム"
    }
    
    field_translations[clean_field_name] || clean_field_name
  end

  def translate_au_course_level(level)
    level_translations = {
      "Bachelor Degree" => "学士課程",
      "Masters Degree (Coursework)" => "修士課程（コースワーク）",
      "Masters Degree (Research)" => "修士課程（研究）",
      "Doctoral Degree" => "博士課程",
      "Graduate Diploma" => "準修士ディプロマ",
      "Graduate Certificate" => "準修士証明書",
      "Advanced Diploma" => "高等ディプロマ",
      "Diploma" => "ディプロマ",
      "Associate Degree" => "準学士",
      "Non-award" => "単位なし",
      "Enabling" => "準備課程"
    }
    
    level_translations[level] || level
  end

  def translate_common_course_terms(course_name)
    # よく出てくる学術用語の翻訳辞書
    common_terms = {
      "Bachelor of" => "学士（",
      "Master of" => "修士（",
      "Doctor of" => "博士（",
      "Diploma in" => "ディプロマ（",
      "Certificate in" => "証明書（",
      "Science" => "理学",
      "Arts" => "文学",
      "Engineering" => "工学",
      "Medicine" => "医学",
      "Law" => "法学",
      "Business" => "経営学",
      "Commerce" => "商学",
      "Education" => "教育学",
      "Nursing" => "看護学",
      "Psychology" => "心理学",
      "Computer Science" => "コンピュータ科学",
      "Information Technology" => "情報技術",
      "Architecture" => "建築学",
      "Design" => "デザイン",
      "Music" => "音楽",
      "Fine Arts" => "美術",
      "Social Work" => "社会福祉",
      "Public Health" => "公衆衛生",
      "Environmental Science" => "環境科学",
      "Agriculture" => "農学",
      "Veterinary" => "獣医学",
      "Pharmacy" => "薬学",
      "Dentistry" => "歯学",
      "Physiotherapy" => "理学療法",
      "Occupational Therapy" => "作業療法",
      "Economics" => "経済学",
      "Accounting" => "会計学",
      "Finance" => "金融",
      "Marketing" => "マーケティング",
      "Management" => "経営管理",
      "International" => "国際",
      "Studies" => "研究",
      "Applied" => "応用",
      "Clinical" => "臨床",
      "Advanced" => "上級",
      "Professional" => "専門",
      "Research" => "研究",
      "Honours" => "優等"
    }
    
    translated = course_name
    common_terms.each do |en, ja|
      if translated.include?(en)
        # Bachelor of, Master of, Doctor ofの場合は特別処理
        if en.end_with?(" of")
          translated = translated.gsub(en, ja)
          translated = translated.gsub("）", "") + "）" if translated.include?(ja)
        else
          translated = translated.gsub(en, ja)
        end
      end
    end
    
    translated
  end
end
