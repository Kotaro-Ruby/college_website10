module ApplicationHelper
  def translate_state(state_code)
    state_translations = {
      'AL' => 'アラバマ州',
      'AK' => 'アラスカ州',
      'AZ' => 'アリゾナ州',
      'AR' => 'アーカンソー州',
      'CA' => 'カリフォルニア州',
      'CO' => 'コロラド州',
      'CT' => 'コネチカット州',
      'DE' => 'デラウェア州',
      'DC' => 'ワシントンD.C.',
      'FL' => 'フロリダ州',
      'GA' => 'ジョージア州',
      'HI' => 'ハワイ州',
      'ID' => 'アイダホ州',
      'IL' => 'イリノイ州',
      'IN' => 'インディアナ州',
      'IA' => 'アイオワ州',
      'KS' => 'カンザス州',
      'KY' => 'ケンタッキー州',
      'LA' => 'ルイジアナ州',
      'ME' => 'メイン州',
      'MD' => 'メリーランド州',
      'MA' => 'マサチューセッツ州',
      'MI' => 'ミシガン州',
      'MN' => 'ミネソタ州',
      'MS' => 'ミシシッピ州',
      'MO' => 'ミズーリ州',
      'MT' => 'モンタナ州',
      'NE' => 'ネブラスカ州',
      'NV' => 'ネバダ州',
      'NH' => 'ニューハンプシャー州',
      'NJ' => 'ニュージャージー州',
      'NM' => 'ニューメキシコ州',
      'NY' => 'ニューヨーク州',
      'NC' => 'ノースカロライナ州',
      'ND' => 'ノースダコタ州',
      'OH' => 'オハイオ州',
      'OK' => 'オクラホマ州',
      'OR' => 'オレゴン州',
      'PA' => 'ペンシルベニア州',
      'PR' => 'プエルトリコ',
      'RI' => 'ロードアイランド州',
      'SC' => 'サウスカロライナ州',
      'SD' => 'サウスダコタ州',
      'TN' => 'テネシー州',
      'TX' => 'テキサス州',
      'UT' => 'ユタ州',
      'VT' => 'バーモント州',
      'VA' => 'バージニア州',
      'VI' => 'バージン諸島',
      'WA' => 'ワシントン州',
      'WV' => 'ウェストバージニア州',
      'WI' => 'ウィスコンシン州',
      'WY' => 'ワイオミング州',
      'GU' => 'グアム',
      'AS' => 'アメリカ領サモア',
      'MP' => '北マリアナ諸島'
    }
    
    state_translations[state_code] || "#{state_code}州"
  end

  def is_search_section?
    # Direct search-related paths
    search_paths = ['/search', '/results']
    return true if search_paths.include?(request.path)
    
    # Result pages with ID parameter
    return true if request.path.start_with?('/result/')
    
    # Specific college pages
    specific_colleges = [
      '/ohio_northern_university',
      '/ohio_state_university', 
      '/florida_state_university',
      '/alabama_state_university'
    ]
    return true if specific_colleges.include?(request.path)
    
    # Fallback: any path that doesn't match known sections
    # This handles the catch-all route that goes to conditions#fallback_page
    known_sections = [
      '/', '/about', '/info', '/contact', '/terms', '/recruit',
      '/canada', '/australia', '/newzealand',
      '/study_abroad_types', '/scholarships', '/visa_guide', '/english_tests',
      '/majors_careers', '/life_guide', '/why_study_abroad', '/knowledge', '/degreeseeking',
      '/login', '/register', '/logout', '/profile', '/favorites', '/compare'
    ]
    
    known_prefixes = [
      '/blogs', '/columns', '/p/', '/states', '/admin', '/profile/', '/password_resets'
    ]
    
    # If it's not in known sections and doesn't start with known prefixes, it's likely a college page
    return false if known_sections.include?(request.path)
    return false if known_prefixes.any? { |prefix| request.path.start_with?(prefix) }
    
    # If we get here, it's likely a college page handled by the fallback route
    true
  end

  def is_blog_section?
    request.path.start_with?('/blogs')
  end

  def is_column_section?
    request.path.start_with?('/columns') || request.path.start_with?('/p/')
  end

  def is_states_section?
    request.path.start_with?('/states')
  end
end
