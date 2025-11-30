class ColumnsController < ApplicationController
  def index
    # コラム一覧を表示
    @columns = [
      {
        title: "コミュニティカレッジとは？",
        subtitle: "メリット・デメリットを徹底解説【2025年版】",
        author: "College Spark",
        author_bio: "編集部",
        category: "留学ガイド",
        article_type: "コラム",
        published_at: "2025年11月",
        slug: "what-is-community-college",
        excerpt: "アメリカのコミュニティカレッジ（コミカレ）とは何か、4年制大学との違い、メリット・デメリット、編入制度まで徹底解説。留学費用を抑えたい方必見の完全ガイド。",
        url: "/p/what-is-community-college",
        featured: true,
        tags: [ "コミカレ", "留学費用", "編入", "2年制大学" ]
      },
      {
        title: "コミカレ留学の費用はいくら？",
        subtitle: "学費・生活費・節約術まで完全ガイド【2025年版】",
        author: "College Spark",
        author_bio: "編集部",
        category: "留学ガイド",
        article_type: "コラム",
        published_at: "2025年11月",
        slug: "community-college-cost",
        excerpt: "コミュニティカレッジ留学にかかる費用を徹底解説。学費、生活費、保険料などの内訳から、奨学金や節約術まで。4年制大学との比較で分かる、コミカレ留学のコスパの良さ。",
        url: "/p/community-college-cost",
        featured: true,
        tags: [ "コミカレ", "留学費用", "学費", "生活費", "奨学金" ]
      },
      {
        title: "コミカレから4年制大学へ編入する方法",
        subtitle: "編入成功のための完全ロードマップ【2025年版】",
        author: "College Spark",
        author_bio: "編集部",
        category: "留学ガイド",
        article_type: "コラム",
        published_at: "2025年11月",
        slug: "community-college-transfer",
        excerpt: "コミュニティカレッジから4年制大学への編入方法を徹底解説。必要なGPA、単位数、TOEFL/IELTSスコアから、TAG制度、人気の編入先大学、成功のためのタイムラインまで完全網羅。",
        url: "/p/community-college-transfer",
        featured: true,
        tags: [ "コミカレ", "編入", "4年制大学", "TAG", "UCLA" ]
      },
      {
        title: "コミュニティカレッジの選び方",
        subtitle: "失敗しない5つのポイント【2025年版】",
        author: "College Spark",
        author_bio: "編集部",
        category: "留学ガイド",
        article_type: "コラム",
        published_at: "2025年11月",
        slug: "how-to-choose-community-college",
        excerpt: "コミュニティカレッジ選びで失敗しないための5つのポイントを解説。立地、編入実績、専攻、費用、サポート体制など、自分に合ったコミカレを見つける方法を徹底ガイド。",
        url: "/p/how-to-choose-community-college",
        featured: true,
        tags: [ "コミカレ", "選び方", "編入", "立地", "費用" ]
      },
      {
        title: "コミカレ生活のリアル",
        subtitle: "1日のスケジュールから友達作りまで【体験談】",
        author: "College Spark",
        author_bio: "編集部",
        category: "留学体験記",
        article_type: "コラム",
        published_at: "2025年11月",
        slug: "community-college-life",
        excerpt: "コミュニティカレッジでの生活を徹底解説。1日のスケジュール、授業の様子、友達の作り方、アルバイト事情まで、リアルなコミカレライフをお届けします。",
        url: "/p/community-college-life",
        featured: true,
        tags: [ "コミカレ", "留学生活", "体験談", "友達", "バイト" ]
      },
      {
        title: "コミカレで取るべき授業",
        subtitle: "編入に有利な科目と避けるべき罠【2025年版】",
        author: "College Spark",
        author_bio: "編集部",
        category: "留学ガイド",
        article_type: "コラム",
        published_at: "2025年11月",
        slug: "community-college-courses",
        excerpt: "コミュニティカレッジで取るべき授業を徹底解説。編入に必要な一般教養、専攻別のおすすめ科目、GPA維持のコツ、避けるべき落とし穴まで完全ガイド。",
        url: "/p/community-college-courses",
        featured: true,
        tags: [ "コミカレ", "授業", "編入", "GPA", "単位" ]
      }
    ]

    # 将来的にはBlogモデルに type フィールドを追加して
    # @columns = Blog.where(article_type: 'column').published.recent
  end
end
