class StatesController < ApplicationController
  before_action :set_state_data, only: [:show]

  def index
    @states = get_all_states_data
  end

  def show
    @colleges = Condition.where(state: @state_code).limit(20)
    @total_colleges = Condition.where(state: @state_code).count
    @top_colleges = Condition.where(state: @state_code)
                            .where.not(students: nil)
                            .where('students > 0')
                            .order(students: :desc)
                            .limit(6)
  end

  private

  def set_state_data
    @state_code = params[:state_code].upcase
    @state_data = get_state_data(@state_code)
    
    if @state_data.nil?
      redirect_to states_path, alert: '指定された州が見つかりません。'
    end
  end

  def get_state_data(state_code)
    states_data = {
      'CA' => {
        name: 'カリフォルニア州',
        english_name: 'California',
        nickname: 'ゴールデンステート',
        capital: 'サクラメント',
        largest_city: 'ロサンゼルス',
        population: '約3,950万人',
        area: '423,970 km²',
        climate: '地中海性気候～砂漠気候',
        average_temp: '年間平均気温：15-22°C',
        cost_of_living: '高い（全米平均の120-150%）',
        economy: 'テクノロジー、エンターテインメント、農業',
        famous_for: 'シリコンバレー、ハリウッド、ディズニーランド',
        education_highlights: 'UC系列、Stanford大学、Caltech等の名門校が集中',
        international_students: '全米最多の留学生数',
        job_opportunities: 'テック業界、映画産業で豊富な就職機会',
        description: 'アメリカ西海岸の経済・技術・文化の中心地。世界トップレベルの大学が多数あり、革新的な研究環境と多様な文化が魅力。'
      },
      'NY' => {
        name: 'ニューヨーク州',
        english_name: 'New York',
        nickname: 'エンパイアステート',
        capital: 'オルバニー',
        largest_city: 'ニューヨーク市',
        population: '約1,950万人',
        area: '141,300 km²',
        climate: '湿潤大陸性気候',
        average_temp: '年間平均気温：8-14°C',
        cost_of_living: '高い（全米平均の130-180%）',
        economy: '金融、不動産、メディア、テクノロジー',
        famous_for: '金融街ウォール街、ブロードウェイ、自由の女神',
        education_highlights: 'Columbia大学、NYU、Cornell大学等の名門校',
        international_students: '多様性に富む国際的な教育環境',
        job_opportunities: '金融、メディア、アート分野で豊富な機会',
        description: '世界の金融・文化・芸術の中心地。多様性と革新性に富む環境で、ビジネス・芸術分野での学習に最適。'
      },
      'TX' => {
        name: 'テキサス州',
        english_name: 'Texas',
        nickname: 'ローンスターステート',
        capital: 'オースティン',
        largest_city: 'ヒューストン',
        population: '約3,000万人',
        area: '695,662 km²',
        climate: '亜熱帯～砂漠気候',
        average_temp: '年間平均気温：18-25°C',
        cost_of_living: '中程度（全米平均の90-110%）',
        economy: 'エネルギー、テクノロジー、航空宇宙、農業',
        famous_for: 'NASA、石油産業、BBQ、カウボーイ文化',
        education_highlights: 'UT Austin、Rice大学、Texas A&M等の優秀校',
        international_students: '手頃な学費と温暖な気候が魅力',
        job_opportunities: 'エネルギー、テック、航空宇宙分野で豊富',
        description: '広大な土地と豊かな資源を誇る州。比較的安い生活費と温暖な気候、そして成長著しいテック産業が魅力。'
      },
      'FL' => {
        name: 'フロリダ州',
        english_name: 'Florida',
        nickname: 'サンシャインステート',
        capital: 'タラハシー',
        largest_city: 'ジャクソンビル',
        population: '約2,200万人',
        area: '170,312 km²',
        climate: '亜熱帯～熱帯気候',
        average_temp: '年間平均気温：20-26°C',
        cost_of_living: '中程度（全米平均の95-115%）',
        economy: '観光業、農業、航空宇宙、国際貿易',
        famous_for: 'ディズニーワールド、美しいビーチ、宇宙開発',
        education_highlights: 'University of Florida、Miami大学等の優秀校',
        international_students: '温暖な気候と多様な文化環境',
        job_opportunities: '観光、国際ビジネス、航空宇宙分野',
        description: '年中温暖な気候と美しい自然環境。国際色豊かで、特にラテンアメリカとのつながりが強い。'
      },
      'MA' => {
        name: 'マサチューセッツ州',
        english_name: 'Massachusetts',
        nickname: 'ベイステート',
        capital: 'ボストン',
        largest_city: 'ボストン',
        population: '約695万人',
        area: '27,336 km²',
        climate: '湿潤大陸性気候',
        average_temp: '年間平均気温：8-13°C',
        cost_of_living: '高い（全米平均の120-140%）',
        economy: 'テクノロジー、バイオテクノロジー、金融、教育',
        famous_for: 'ハーバード大学、MIT、ボストン茶会事件',
        education_highlights: 'Harvard、MIT、Tufts等世界最高レベルの大学群',
        international_students: '最高レベルの教育研究環境',
        job_opportunities: 'バイオテック、フィンテック、AI分野で豊富',
        description: 'アメリカ教育の聖地。世界最高レベルの大学が集中し、学術研究とイノベーションの中心地。'
      },
      'OH' => {
        name: 'オハイオ州',
        english_name: 'Ohio',
        nickname: 'バックアイステート',
        capital: 'コロンバス',
        largest_city: 'コロンバス',
        population: '約1,170万人',
        area: '116,096 km²',
        climate: '湿潤大陸性気候',
        average_temp: '年間平均気温：9-13°C',
        cost_of_living: '低い（全米平均の85-95%）',
        economy: '製造業、航空宇宙、農業、金融',
        famous_for: 'ライト兄弟発祥の地、ロックンロール殿堂',
        education_highlights: 'Ohio State大学、Case Western Reserve大学等の名門校',
        international_students: '手頃な学費と親しみやすい環境',
        job_opportunities: '製造業、ヘルスケア、金融分野で豊富',
        description: 'アメリカ中西部の製造業とイノベーションの中心地。手頃な生活費と質の高い教育環境が魅力。'
      },
      'IL' => {
        name: 'イリノイ州',
        english_name: 'Illinois',
        nickname: 'プレーリーステート',
        capital: 'スプリングフィールド',
        largest_city: 'シカゴ',
        population: '約1,270万人',
        area: '149,997 km²',
        climate: '湿潤大陸性気候',
        average_temp: '年間平均気温：8-12°C',
        cost_of_living: '中程度（全米平均の95-105%）',
        economy: '金融、製造業、農業、テクノロジー',
        famous_for: 'シカゴ、摩天楼建築、ディープディッシュピザ',
        education_highlights: 'University of Chicago、Northwestern大学等の名門校',
        international_students: '国際的な都市環境と充実した研究機関',
        job_opportunities: '金融、コンサルティング、製造業で豊富',
        description: 'アメリカ中西部の経済・文化の中心地シカゴを擁する州。世界クラスの大学と多様な産業機会。'
      },
      'PA' => {
        name: 'ペンシルベニア州',
        english_name: 'Pennsylvania',
        nickname: 'キーストーンステート',
        capital: 'ハリスバーグ',
        largest_city: 'フィラデルフィア',
        population: '約1,290万人',
        area: '119,280 km²',
        climate: '湿潤大陸性気候',
        average_temp: '年間平均気温：8-12°C',
        cost_of_living: '中程度（全米平均の95-110%）',
        economy: '製造業、ヘルスケア、エネルギー、金融',
        famous_for: '独立宣言の地、自由の鐘、チーズステーキ',
        education_highlights: 'University of Pennsylvania、Carnegie Mellon等の名門校',
        international_students: '歴史ある学術環境と多様な文化',
        job_opportunities: 'ヘルスケア、テクノロジー、金融分野で豊富',
        description: 'アメリカ建国の歴史を持つ州。フィラデルフィアとピッツバーグを中心とした教育・産業の拠点。'
      },
      'MI' => {
        name: 'ミシガン州',
        english_name: 'Michigan',
        nickname: 'ウルヴァリンステート',
        capital: 'ランシング',
        largest_city: 'デトロイト',
        population: '約1,000万人',
        area: '250,493 km²',
        climate: '湿潤大陸性気候',
        average_temp: '年間平均気温：6-10°C',
        cost_of_living: '低い（全米平均の85-95%）',
        economy: '自動車産業、製造業、農業、テクノロジー',
        famous_for: '自動車産業の中心地、五大湖',
        education_highlights: 'University of Michigan、Michigan State大学等の優秀校',
        international_students: '手頃な学費と研究重点の環境',
        job_opportunities: '自動車、エンジニアリング、製造業で豊富',
        description: 'アメリカ自動車産業の中心地。五大湖に囲まれた美しい自然環境と優秀な州立大学。'
      },
      'NC' => {
        name: 'ノースカロライナ州',
        english_name: 'North Carolina',
        nickname: 'タールヒールステート',
        capital: 'ローリー',
        largest_city: 'シャーロット',
        population: '約1,070万人',
        area: '139,391 km²',
        climate: '亜熱帯湿潤気候',
        average_temp: '年間平均気温：14-18°C',
        cost_of_living: '低い（全米平均の90-100%）',
        economy: 'テクノロジー、金融、製造業、農業',
        famous_for: 'リサーチトライアングル、バンクオブアメリカ',
        education_highlights: 'Duke大学、University of North Carolina等の名門校',
        international_students: '温暖な気候と成長するテック産業',
        job_opportunities: 'テクノロジー、金融、ヘルスケア分野で豊富',
        description: '東海岸の成長州。リサーチトライアングルを中心とした技術革新と手頃な生活費が魅力。'
      },
      'VA' => {
        name: 'バージニア州',
        english_name: 'Virginia',
        nickname: 'オールドドミニオン',
        capital: 'リッチモンド',
        largest_city: 'バージニアビーチ',
        population: '約860万人',
        area: '110,787 km²',
        climate: '亜熱帯湿潤気候',
        average_temp: '年間平均気温：12-16°C',
        cost_of_living: '中程度（全米平均の100-110%）',
        economy: 'テクノロジー、政府、軍事、農業',
        famous_for: 'アメリカ初代大統領の故郷、ワシントンDC近郊',
        education_highlights: 'University of Virginia、Virginia Tech等の名門校',
        international_students: '政府機関との連携と豊富な機会',
        job_opportunities: '政府、テクノロジー、国防分野で豊富',
        description: 'アメリカ建国の歴史を持つ州。ワシントンDC近郊で政府・テクノロジー産業が発達。'
      },
      'WA' => {
        name: 'ワシントン州',
        english_name: 'Washington',
        nickname: 'エバーグリーンステート',
        capital: 'オリンピア',
        largest_city: 'シアトル',
        population: '約760万人',
        area: '184,661 km²',
        climate: '西岸海洋性気候',
        average_temp: '年間平均気温：9-13°C',
        cost_of_living: '高い（全米平均の110-130%）',
        economy: 'テクノロジー、航空宇宙、農業、林業',
        famous_for: 'Microsoft、Amazon、Boeing、コーヒー文化',
        education_highlights: 'University of Washington、Washington State大学',
        international_students: '世界トップクラスのテック企業との連携',
        job_opportunities: 'テクノロジー、航空宇宙、イノベーション分野',
        description: '西海岸のテクノロジーハブ。シアトルを中心とした革新的な企業文化と美しい自然環境。'
      },
      'GA' => {
        name: 'ジョージア州',
        english_name: 'Georgia',
        nickname: 'ピーチステート',
        capital: 'アトランタ',
        largest_city: 'アトランタ',
        population: '約1,080万人',
        area: '153,910 km²',
        climate: '亜熱帯湿潤気候',
        average_temp: '年間平均気温：16-20°C',
        cost_of_living: '中程度（全米平均の90-100%）',
        economy: 'テクノロジー、映画産業、物流、農業',
        famous_for: 'CNN、コカ・コーラ発祥の地、映画産業',
        education_highlights: 'Georgia Tech、Emory大学等の優秀校',
        international_students: '成長するテック産業と多様な文化',
        job_opportunities: 'テクノロジー、メディア、物流分野で豊富',
        description: '南東部の経済中心地。アトランタを拠点とした急成長するテクノロジーと映画産業。'
      },
      'NJ' => {
        name: 'ニュージャージー州',
        english_name: 'New Jersey',
        nickname: 'ガーデンステート',
        capital: 'トレントン',
        largest_city: 'ニューアーク',
        population: '約920万人',
        area: '22,591 km²',
        climate: '湿潤大陸性気候',
        average_temp: '年間平均気温：10-14°C',
        cost_of_living: '高い（全米平均の115-125%）',
        economy: '製薬、金融、製造業、テクノロジー',
        famous_for: 'ニューヨーク・フィラデルフィア近郊、製薬産業',
        education_highlights: 'Princeton大学、Rutgers大学等の名門校',
        international_students: '大都市圏へのアクセスと産業機会',
        job_opportunities: '製薬、金融、テクノロジー分野で豊富',
        description: 'ニューヨークとフィラデルフィア間の戦略的立地。製薬産業の中心地として発展。'
      }
    }
    
    states_data[state_code]
  end

  def get_all_states_data
    # 大学数の多い主要な州と重要な州を表示
    major_states = %w[CA NY TX FL MA IL PA OH MI NC VA WA GA NJ MD WI MN AZ IN TN MO AL KY CO SC IA OR KS AR MS LA NV UT NM CT RI]
    
    major_states.map do |state_code|
      state_data = get_state_data(state_code)
      next unless state_data
      
      college_count = Condition.where(state: state_code).count
      
      state_data.merge(
        code: state_code,
        college_count: college_count
      )
    end.compact.sort_by { |state| -state[:college_count] }
  end
end