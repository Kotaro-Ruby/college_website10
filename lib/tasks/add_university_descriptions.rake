namespace :au_universities do
  desc "Add descriptions to famous Australian universities"
  task add_descriptions: :environment do
    
    descriptions = {
      "The University of Melbourne" => {
        description: "1853年創立のオーストラリア第2古の名門大学。Group of Eight（Go8）のメンバーで、世界ランキングでも常にトップ50以内に入る。メルボルンの中心部に位置し、美しいキャンパスと優れた研究施設で知られる。",
        highlights: "• QS世界ランキング14位（2024年）\n• 法学・医学・工学が特に有名\n• ノーベル賞受賞者8名輩出\n• 留学生比率40%以上の国際的な環境",
        famous_alumni: "ジュリア・ギラード（元首相）、ケイト・ブランシェット（女優）、エリザベス・ブラックバーン（ノーベル賞受賞者）"
      },
      
      "The University of Sydney" => {
        description: "1850年創立のオーストラリア最古の大学。シドニー中心部から近く、歴史的な砂岩建築（Sandstone buildings）が特徴的。Go8メンバーで、幅広い分野で世界的に高い評価を受けている。",
        highlights: "• QS世界ランキング19位（2024年）\n• 法学部・医学部が特に有名\n• 美しいキャンパスは観光名所にも\n• 5人の首相を輩出",
        famous_alumni: "マルコム・ターンブル（元首相）、ジェフリー・ラッシュ（俳優）、ジョン・ハワード（元首相）"
      },
      
      "The Australian National University" => {
        description: "1946年創立の首都キャンベラにある国立大学。研究重視の大学として知られ、特に政治学、国際関係、アジア太平洋研究で世界的な評価が高い。緑豊かなキャンパスが特徴。",
        highlights: "• QS世界ランキング34位（2024年）\n• ノーベル賞受賞者6名\n• 政治家・外交官を多数輩出\n• 少人数教育で学生サポートが充実",
        famous_alumni: "ケビン・ラッド（元首相）、ボブ・ホーク（元首相）、ブライアン・シュミット（ノーベル賞受賞者）"
      },
      
      "UNSW" => {
        description: "1949年創立のシドニーにある研究型大学。工学・ビジネス・法学で特に強く、起業家精神を重視する文化がある。シリコンバレーとの連携も深く、スタートアップ支援が充実。",
        highlights: "• QS世界ランキング45位（2024年）\n• 工学部はオーストラリアNo.1の評価\n• 太陽光発電研究の世界的リーダー\n• 起業家育成プログラムが充実",
        famous_alumni: "スコット・モリソン（元首相）、ミシェル・シモンズ（量子物理学者）"
      },
      
      "The University of Queensland" => {
        description: "1909年創立のブリスベンにある研究型大学。Go8メンバーで、特に生物科学、環境科学、鉱山工学で世界的評価が高い。美しいキャンパスと温暖な気候が魅力。",
        highlights: "• QS世界ランキング43位（2024年）\n• 獣医学部は世界トップクラス\n• 子宮頸がんワクチン開発\n• 3つのキャンパスを持つ",
        famous_alumni: "ピーター・ドハーティ（ノーベル賞受賞者）、ジェフリー・ラッシュ（俳優）"
      },
      
      "Monash University" => {
        description: "1958年創立のメルボルンにある大規模総合大学。オーストラリア最大の学生数を誇り、マレーシア、南アフリカ、イタリア、中国にもキャンパスを持つ国際的な大学。",
        highlights: "• QS世界ランキング42位（2024年）\n• 薬学部は世界2位の評価\n• 5大陸にキャンパスを展開\n• 学生数84,000人以上",
        famous_alumni: "ジョシュ・フライデンバーグ（元財務相）、ダニエル・アンドリューズ（ビクトリア州首相）"
      },
      
      "The University of Western Australia" => {
        description: "1911年創立のパースにある研究型大学。Go8メンバーで、美しいキャンパスは国の文化遺産に指定されている。鉱山工学、海洋科学、農業科学で特に強い。",
        highlights: "• QS世界ランキング72位（2024年）\n• ノーベル賞受賞者を輩出\n• 西オーストラリア州唯一のGo8大学\n• 産業界との連携が強い",
        famous_alumni: "ボブ・ホーク（元首相）、バリー・マーシャル（ノーベル賞受賞者）"
      },
      
      "The University of Adelaide" => {
        description: "1874年創立の歴史ある大学。Go8メンバーで、5人のノーベル賞受賞者を輩出。ワイン科学、農業科学、健康科学で世界的に有名。アデレードの文化的中心地に位置。",
        highlights: "• QS世界ランキング89位（2024年）\n• ワイン醸造学で世界トップ\n• ノーベル賞受賞者5名輩出\n• 生活費が他都市より安い",
        famous_alumni: "ジュリア・ギラード（元首相）、ハワード・フローリー（ノーベル賞受賞者）"
      },
      
      "University of Technology Sydney" => {
        description: "1988年創立の比較的新しい大学だが、急速に評価を高めている。シドニー中心部に位置し、実践的な教育と産業界との強い連携が特徴。革新的な建築のキャンパスも話題。",
        highlights: "• QS世界ランキング90位（2024年）\n• 若い大学ランキングで世界トップ10\n• デザイン・建築学が特に有名\n• 産学連携プログラムが充実",
        famous_alumni: "ヒュー・ジャックマン（俳優）、ミランダ・タプセル（女優）"
      },
      
      "RMIT University" => {
        description: "1887年創立のメルボルンにある実践重視の大学。デザイン、建築、エンジニアリング分野で特に強く、産業界との密接な関係を持つ。ベトナムにもキャンパスを展開。",
        highlights: "• アート&デザインで世界トップ20\n• 建築学でオーストラリアNo.1\n• 実践的な教育アプローチ\n• メルボルン中心部にキャンパス",
        famous_alumni: "ジェームズ・ワン（映画監督）、シガニー・ウィーバー（女優）"
      },
      
      "Macquarie University" => {
        description: "1964年創立のシドニー北部にある大学。ビジネススクールが特に有名で、MBAプログラムは国際的に高い評価を受ける。大学内に私立病院を持つ唯一の大学。",
        highlights: "• 言語学・心理学で世界的評価\n• MBAプログラムが有名\n• キャンパス内に私立病院\n• シドニーのハイテク地区に立地",
        famous_alumni: "レイ・マーティン（ジャーナリスト）、キャサリン・リビングストン（実業家）"
      },
      
      "Queensland University of Technology" => {
        description: "1989年創立のブリスベンにある実践重視の大学。「現実世界のための大学」をモットーに、産業界との強い連携と実践的な教育で知られる。",
        highlights: "• メディア・コミュニケーション学が強い\n• ビジネススクールが三冠認証取得\n• Gardens Pointキャンパスは市内中心部\n• 起業家教育に力を入れる",
        famous_alumni: "ウェイン・スワン（元財務相）、レイチェル・グリフィス（女優）"
      },
      
      "Curtin University" => {
        description: "1966年創立のパースにある大学。鉱山工学で世界2位の評価を持ち、西オーストラリアの資源産業と密接な関係を持つ。国際的なキャンパス展開も積極的。",
        highlights: "• 鉱山工学で世界トップクラス\n• マレーシア、シンガポールにキャンパス\n• 石油・ガス産業との連携\n• 実践的な教育アプローチ",
        famous_alumni: "ジョン・バトラー（ミュージシャン）、ティム・ウィンセット（建築家）"
      },
      
      "Griffith University" => {
        description: "1971年創立のブリスベン・ゴールドコーストにある大学。環境科学、アジア研究で先駆的な役割を果たし、観光・ホスピタリティ教育でも有名。",
        highlights: "• 環境科学のパイオニア\n• 観光学で世界トップ3\n• ゴールドコーストキャンパスが人気\n• 音楽院（コンサバトリウム）が有名",
        famous_alumni: "デボラ・メイリング（ジャーナリスト）、サラ・カラザース（政治家）"
      },
      
      "Deakin University" => {
        description: "1974年創立のビクトリア州にある大学。オンライン教育のパイオニアとして知られ、スポーツ科学分野では世界トップクラスの評価を持つ。",
        highlights: "• スポーツ科学で世界No.1（上海ランキング）\n• オンライン教育のリーダー\n• 看護学が特に有名\n• 4つのキャンパスを展開",
        famous_alumni: "ジョン・ブランビー（元ビクトリア州首相）、ジミー・バーテル（AFL選手）"
      }
    }
    
    puts "=== オーストラリア有名大学の説明を追加 ==="
    
    descriptions.each do |uni_name, data|
      university = AuUniversity.find_by(name: uni_name)
      if university
        university.update!(
          description: data[:description],
          highlights: data[:highlights],
          famous_alumni: data[:famous_alumni]
        )
        puts "✓ #{uni_name}の説明を追加しました"
      else
        puts "✗ #{uni_name}が見つかりませんでした"
      end
    end
    
    puts "\n=== 完了 ==="
    puts "説明を追加した大学数: #{descriptions.keys.count}"
  end
end