namespace :college_data do
  desc "Add comprehensive comments to colleges without existing comments"
  task add_comments: :environment do
    puts "コメント追加を開始します..."
    
    # コメントがない大学を取得
    colleges_without_comments = Condition.where(comment: [nil, ''])
    total_to_update = colleges_without_comments.count
    updated_count = 0
    
    puts "対象大学数: #{total_to_update}校"
    
    # 大学の種類とコメントテンプレート
    comment_templates = {
      # 州立大学系
      'state_university' => [
        "州を代表する総合大学として、幅広い学術分野で高品質な教育を提供しています。リーズナブルな学費と充実した研究環境で、多くの学生に高等教育の機会を提供しています。",
        "州立大学として地域に根ざした教育を展開し、実践的なカリキュラムと豊富な課外活動を通じて学生の成長をサポートしています。",
        "州内外から多様な学生が集まる環境で、学術的な厳格さと温かいコミュニティの雰囲気を両立しています。卒業生は様々な分野で活躍しています。",
        "州立大学として手頃な学費で質の高い教育を提供し、研究活動にも力を入れています。学生支援体制も充実しており、安心して学習に取り組めます。"
      ],
      
      # コミュニティカレッジ系
      'community_college' => [
        "地域に密着したコミュニティカレッジとして、職業訓練から4年制大学への編入準備まで多様なプログラムを提供しています。",
        "手頃な学費で質の高い教育を受けられ、小規模クラスでの個別指導に定評があります。働きながら学ぶ学生も多く、柔軟な履修が可能です。",
        "実践的なスキル習得に重点を置いたプログラムが充実しており、地域の産業界との連携も強く、就職率の高さが自慢です。",
        "多様な年齢層の学生が学ぶアットホームな環境で、一人ひとりの目標に合わせたサポートを提供しています。"
      ],
      
      # 私立総合大学系
      'private_university' => [
        "私立大学ならではの少人数教育と充実した施設で、学生一人ひとりに手厚い指導を行っています。伝統と革新を重んじる教育方針で知られています。",
        "優秀な教授陣による質の高い教育と、最新の設備を備えたキャンパスで学習環境は抜群です。卒業生のネットワークも強く、キャリア支援も充実しています。",
        "学生の多様性を重視し、世界各国からの留学生も多く在籍しています。国際的な視野を持った人材育成に力を入れています。",
        "伝統ある私立大学として、リベラルアーツ教育に重点を置き、批判的思考力と創造性を育む教育を実践しています。"
      ],
      
      # 専門大学・技術系
      'technical_college' => [
        "実践的な技術教育に特化し、産業界のニーズに直結したプログラムを提供しています。高い就職率と即戦力となる人材育成で評価されています。",
        "最新の設備と経験豊富な指導者による実習中心の教育で、実際の現場で求められるスキルを身につけることができます。",
        "業界との強いつながりを活かし、インターンシップや就職支援が充実しています。卒業後すぐに活躍できる実力が身につきます。",
        "少人数制の授業で個別指導が行き届き、一人ひとりの技術習得をしっかりとサポートしています。"
      ],
      
      # 美術・芸術系
      'arts_college' => [
        "創造性を育む環境で、芸術分野の専門教育を提供しています。個性を重視し、学生の表現力と技術力を総合的に伸ばします。",
        "著名なアーティストや業界のプロフェッショナルが指導に当たり、実践的なスキルと芸術的感性を養います。",
        "最新の制作設備と創作スペースが整備され、学生は自由に創作活動に取り組むことができます。展示会やコンクールへの参加も積極的に支援しています。",
        "多様な芸術分野での学習機会を提供し、学生の創作活動をあらゆる面からサポートしています。"
      ],
      
      # 宗教系大学
      'religious_college' => [
        "宗教的価値観に基づいた全人教育を実践し、学術的な学習と精神的な成長を両立させています。温かいコミュニティの中で学べます。",
        "信仰を基盤とした教育理念のもと、道徳的なリーダーシップと社会奉仕の精神を育みます。小規模でアットホームな環境が特色です。",
        "宗教的な価値観を大切にしながら、現代社会に必要な知識とスキルを身につけることができます。支援体制も手厚く、安心して学習できます。",
        "信仰共同体としての絆を大切にし、学生の人格形成と学術的成長を総合的にサポートしています。"
      ],
      
      # 医療系大学
      'medical_college' => [
        "医療・健康分野の専門教育に特化し、最新の医学知識と技術を身につけることができます。臨床実習も充実しており、実践的な学習が可能です。",
        "経験豊富な医療従事者による指導と最新の医療設備を活用した教育で、医療現場で活躍できる人材を育成しています。",
        "医療倫理と技術の両面を重視した教育により、患者に寄り添える医療従事者を養成しています。国家試験対策も万全です。",
        "医療分野での専門知識習得と実習を通じて、医療現場で求められる実践力を身につけることができます。"
      ],
      
      # 一般的なコメント
      'general' => [
        "学生一人ひとりの個性と可能性を大切にし、質の高い教育環境を提供しています。キャンパスライフも充実しており、学習と成長の場として最適です。",
        "多様な学習機会と豊富な課外活動を通じて、学生の総合的な成長をサポートしています。卒業生は様々な分野で活躍し、社会に貢献しています。",
        "アカデミックな厳格さと温かいコミュニティの雰囲気を併せ持つ教育機関として、学生の学習と人格形成を全面的にサポートしています。",
        "伝統と革新のバランスを保ちながら、現代社会のニーズに応える教育を実践しています。学生支援体制も充実しており、安心して学べる環境です。",
        "幅広い学問分野での学習機会を提供し、学生の知的好奇心と創造性を育みます。国際的な視野を持った人材育成にも力を入れています。"
      ]
    }
    
    # 大学の種類を判定するヘルパーメソッド
    def determine_college_type(college_name, school_type)
      name_lower = college_name.downcase
      
      # 2年制大学
      return 'community_college' if school_type&.include?('2-year') || 
                                   name_lower.include?('community college') ||
                                   name_lower.include?('junior college')
      
      # 技術系・職業訓練系
      return 'technical_college' if name_lower.include?('technical') ||
                                   name_lower.include?('institute of technology') ||
                                   name_lower.include?('trade') ||
                                   name_lower.include?('vocational')
      
      # 美術・芸術系
      return 'arts_college' if name_lower.include?('art') ||
                              name_lower.include?('design') ||
                              name_lower.include?('music') ||
                              name_lower.include?('conservatory')
      
      # 医療系
      return 'medical_college' if name_lower.include?('medical') ||
                                 name_lower.include?('nursing') ||
                                 name_lower.include?('health') ||
                                 name_lower.include?('pharmacy')
      
      # 宗教系
      return 'religious_college' if name_lower.include?('seminary') ||
                                   name_lower.include?('theological') ||
                                   name_lower.include?('christian') ||
                                   name_lower.include?('catholic') ||
                                   name_lower.include?('baptist') ||
                                   name_lower.include?('methodist')
      
      # 州立大学
      return 'state_university' if name_lower.include?('state university') ||
                                  name_lower.include?('state college') ||
                                  name_lower.include?('university of')
      
      # 私立大学
      return 'private_university' if name_lower.include?('university') ||
                                    name_lower.include?('college')
      
      'general'
    end
    
    colleges_without_comments.find_each.with_index do |college, index|
      college_type = determine_college_type(college.college, college.school_type)
      template_options = comment_templates[college_type] || comment_templates['general']
      
      # ランダムにコメントを選択
      selected_comment = template_options.sample
      
      # 大学の特徴に基づいてコメントをカスタマイズ
      if college.students && college.students > 0
        if college.students > 30000
          selected_comment += " 大規模な学生数を抱える総合大学として、多様な学習機会と活発なキャンパスライフが魅力です。"
        elsif college.students > 10000
          selected_comment += " 中規模の大学として、適度な規模感の中で充実した教育とサポートを受けることができます。"
        else
          selected_comment += " 小規模な環境を活かし、教授との距離が近く、きめ細かい指導を受けることができます。"
        end
      end
      
      if college.acceptance_rate && college.acceptance_rate > 0
        if college.acceptance_rate < 0.3
          selected_comment += " 高い選考基準で知られ、優秀な学生が集まる環境で切磋琢磨できます。"
        elsif college.acceptance_rate > 0.8
          selected_comment += " 多くの学生に学習機会を提供することを重視し、幅広い背景の学生を受け入れています。"
        end
      end
      
      # コメントを更新
      college.update(comment: selected_comment)
      updated_count += 1
      
      # 進捗表示
      if (index + 1) % 100 == 0
        puts "進捗: #{index + 1}/#{total_to_update} (#{((index + 1).to_f / total_to_update * 100).round(1)}%)"
      end
    end
    
    puts "\\nコメント追加が完了しました！"
    puts "更新された大学数: #{updated_count}校"
    
    # 最終統計
    total_with_comments = Condition.where.not(comment: [nil, '']).count
    coverage = (total_with_comments.to_f / Condition.count * 100).round(1)
    puts "現在のコメント数: #{total_with_comments}校"
    puts "カバレッジ: #{coverage}%"
  end
end