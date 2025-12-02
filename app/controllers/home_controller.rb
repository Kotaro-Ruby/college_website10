class HomeController < ApplicationController
  # 特定のアクションでカスタムレイアウトを使用
  layout "country_layout", only: [ :canada, :australia, :newzealand ]

  def top
    # Force no cache for this page during development only
    if Rails.env.development?
      response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "0"
    end
  end

  def index
    # セッションクリア（テスト用）
    clear_recently_viewed_for_testing

    # 人気大学のデータを取得（実際の閲覧データに基づく）
    @popular_colleges = get_popular_colleges

    # 最新記事を取得（コラムとブログの混合）
    @recent_articles = get_recent_articles

    # 最新の留学ニュースを取得（公開済みのみ、最新10件）
    @recent_news = News.published.recent.limit(10)

    # THE分野別ランキングデータを取得
    @subject_rankings = get_the_subject_rankings

    # DBベースのランキングデータを取得
    @db_rankings = get_db_rankings
  end

  def get_recent_articles
    # 静的なコラムデータ
    columns = [
      {
        title: "これ以上自分を嫌いになりたくない",
        subtitle: "何も成し遂げたことがなかった私が、人生をかけて選んだ道",
        author: "運営者",
        author_bio: "College Spark編集部",
        category: "留学体験記",
        article_type: "コラム",
        published_at: "2025年7月8日",
        slug: "my-turning-point",
        excerpt: "大学の附属高校に通っていた私は、何も考えず、エスカレーター的に大学へ進むことを決めた。決めたと言っても、それが既定路線で、特に考えることもなく周りと方向を合わせただけと言っていいだろう。そんな中で気がついた「自分に自信がない」という事実が、私の人生を大きく変えることになった。",
        url: "/p/my-turning-point",
        featured: true,
        tags: [ "挑戦", "自信", "海外進学", "転機" ],
        created_at: 1.day.ago
      }
    ]

    # ブログ記事を取得
    blogs = Blog.published.recent.limit(4).map do |blog|
      {
        title: blog.title,
        subtitle: blog.subtitle,
        author: blog.author,
        category: blog.category,
        article_type: "ブログ",
        published_at: blog.published_at&.strftime("%Y年%m月%d日"),
        slug: blog.slug,
        excerpt: strip_tags(blog.content),
        url: "/blogs/#{blog.slug}",
        featured: false,
        created_at: blog.created_at
      }
    end

    # コラムとブログを混合して最新順にソート、最大5件
    (columns + blogs).sort_by { |article| article[:created_at] }.reverse.first(5)
  end

  def search
  end

  def about
  end


  def degreeseeking
  end

  def info
  end

  def recruit
  end

  def contact
  end

  def send_contact
    name = params[:name]
    email = params[:email]
    category = params[:category]
    message = params[:message]

    # デバッグ情報をログに出力
    Rails.logger.info "=" * 50
    Rails.logger.info "お問い合わせフォーム送信データ:"
    Rails.logger.info "名前: #{name}"
    Rails.logger.info "メール: #{email}"
    Rails.logger.info "カテゴリー: #{category}"
    Rails.logger.info "メッセージ: #{message}"
    Rails.logger.info "=" * 50

    if name.present? && email.present? && category.present? && message.present?
      begin
        # メール送信
        mail = ContactMailer.contact_form(name, email, category, message)
        mail.deliver_now

        # お問い合わせ内容をファイルに記録（バックアップとして）
        save_contact_to_file(name, email, category, message)

        # ログ出力
        Rails.logger.info "=" * 50
        Rails.logger.info "お問い合わせメール送信成功"
        Rails.logger.info "送信者: #{name} (#{email})"
        Rails.logger.info "カテゴリー: #{category}"
        Rails.logger.info "宛先: collegespark2025@gmail.com"
        Rails.logger.info "送信時刻: #{Time.current}"
        Rails.logger.info "=" * 50

        flash[:notice] = "✅ お問い合わせを受け付けました！ご連絡いただきありがとうございます。24時間以内にcollegespark2025@gmail.comからご連絡いたします。"
        redirect_to contact_path

      rescue Net::SMTPAuthenticationError => e
        Rails.logger.error "SMTP認証エラー: #{e.message}"
        save_contact_to_file(name, email, category, message) # ファイルには保存
        flash[:alert] = "メール送信に問題が発生しました。お問い合わせ内容は記録されました。"
        redirect_to contact_path

      rescue Net::TimeoutError => e
        Rails.logger.error "メール送信タイムアウト: #{e.message}"
        save_contact_to_file(name, email, category, message) # ファイルには保存
        flash[:alert] = "メール送信がタイムアウトしました。お問い合わせ内容は記録されました。"
        redirect_to contact_path

      rescue => e
        Rails.logger.error "メール送信エラー: #{e.class.name} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        save_contact_to_file(name, email, category, message) # ファイルには保存

        error_message = Rails.env.development? ?
          "メール送信エラー: #{e.message}" :
          "メール送信に失敗しましたが、お問い合わせ内容は記録されました。"

        flash[:alert] = error_message
        redirect_to contact_path
      end
    else
      missing_fields = []
      missing_fields << "名前" unless name.present?
      missing_fields << "メールアドレス" unless email.present?
      missing_fields << "カテゴリー" unless category.present?
      missing_fields << "メッセージ" unless message.present?

      flash[:alert] = "以下の項目を入力してください: #{missing_fields.join(', ')}"
      redirect_to contact_path
    end
  end

  def canada
  end

  def australia
  end

  def newzealand
  end

  def study_abroad_types
  end

  def scholarships
  end

  def visa_guide
  end

  def english_tests
  end

  def majors_careers
  end

  def life_guide
  end

  def ivy_league
  end

  def states
  end

  def terms
  end

  def why_study_abroad
  end

  def news_index
    @news_items = News.published.recent

    # 国別フィルター
    if params[:country].present?
      @news_items = @news_items.where(country: params[:country])
    end

    @news_items = @news_items.page(params[:page]).per(12)

    # 国のリストを取得（公開済みニュースのみ）
    @countries = News.published.distinct.pluck(:country).compact.sort

    # 各国の件数を取得
    @country_counts = News.published.group(:country).count
    @total_count = News.published.count
  end

  def news_detail
    @news = News.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "ニュースが見つかりませんでした"
  end

  private

  def get_db_rankings
    # 4年制・非営利大学のみを対象（Carnegie分類15以上が4年制大学、学生数1000人以上）
    base_scope = Condition.where("carnegie_basic >= 15")
                          .where(privateorpublic: [ "私立", "州立" ])
                          .where("students >= 1000")

    {
      affordable: base_scope.where.not(tuition_in_state: nil)
                          .where("tuition_in_state > 0")
                          .order(tuition_in_state: :asc)
                          .limit(3),
      high_acceptance: base_scope.where.not(acceptance_rate: nil)
                               .where("acceptance_rate > 0.5 AND acceptance_rate < 1.0")
                               .order(acceptance_rate: :desc)
                               .limit(3),
      high_graduation: base_scope.where.not(graduation_rate: nil)
                                .where("graduation_rate > 0.5 AND graduation_rate < 1.0")
                                .order(graduation_rate: :desc)
                                .limit(3),
      large_enrollment: base_scope.where.not(students: nil)
                                .where("students > 0")
                                .order(students: :desc)
                                .limit(3),
      high_earnings: base_scope.where.not(earnings_10yr_median: nil)
                              .where("earnings_10yr_median > 0")
                              .order(earnings_10yr_median: :desc)
                              .limit(3),
      high_sat: base_scope.where.not(sat_math_75: nil, sat_reading_75: nil)
                        .where("sat_math_75 > 700 AND sat_reading_75 > 700")
                        .order(Arel.sql("(sat_math_75 + sat_reading_75) DESC"))
                        .limit(3)
    }
  end

  def get_the_subject_rankings
    {
      "人文科学" => [
        "Massachusetts Institute of Technology",
        "Stanford University",
        "Harvard University",
        "Princeton University",
        "University of California-Berkeley"
      ],
      "ビジネス・経済学" => [
        "Massachusetts Institute of Technology",
        "Stanford University",
        "Harvard University",
        "University of California-Berkeley",
        "University of Chicago"
      ],
      "コンピューターサイエンス" => [
        "Massachusetts Institute of Technology",
        "Stanford University",
        "Carnegie Mellon University",
        "Princeton University",
        "University of California-Berkeley"
      ],
      "教育学" => [
        "Stanford University",
        "University of California-Berkeley",
        "Harvard University",
        "University of Michigan-Ann Arbor",
        "University of California-Los Angeles"
      ],
      "工学" => [
        "Harvard University",
        "Stanford University",
        "Massachusetts Institute of Technology",
        "University of California-Berkeley",
        "California Institute of Technology"
      ],
      "法学" => [
        "Stanford University",
        "Harvard University",
        "New York University",
        "Columbia University",
        "University of California-Berkeley"
      ],
      "生命科学" => [
        "Harvard University",
        "Massachusetts Institute of Technology",
        "Stanford University",
        "Yale University",
        "Princeton University"
      ],
      "医学・健康科学" => [
        "Harvard University",
        "Johns Hopkins University",
        "Stanford University",
        "Yale University",
        "University of Pennsylvania"
      ],
      "物理科学" => [
        "California Institute of Technology",
        "Harvard University",
        "Stanford University",
        "Massachusetts Institute of Technology",
        "Princeton University"
      ],
      "心理学" => [
        "Stanford University",
        "Princeton University",
        "Harvard University",
        "University of California-Berkeley",
        "Yale University"
      ],
      "社会科学" => [
        "Massachusetts Institute of Technology",
        "Stanford University",
        "Harvard University",
        "Princeton University",
        "University of California-Berkeley"
      ]
    }
  end

  def save_contact_to_file(name, email, category, message)
    require "csv"

    # ファイルのパスを設定
    contacts_dir = Rails.root.join("storage", "contacts")
    FileUtils.mkdir_p(contacts_dir) unless Dir.exist?(contacts_dir)

    csv_file = contacts_dir.join("contact_submissions.csv")
    txt_file = contacts_dir.join("contact_submissions.txt")

    # 現在の日時
    timestamp = Time.current.strftime("%Y-%m-%d %H:%M:%S")

    # CSVファイルに記録
    CSV.open(csv_file, "a", encoding: "UTF-8") do |csv|
      # ヘッダーを追加（ファイルが新規作成の場合）
      if File.size(csv_file) == 0
        csv << [ "日時", "名前", "メールアドレス", "カテゴリー", "メッセージ" ]
      end
      csv << [ timestamp, name, email, category, message ]
    end

    # テキストファイルに記録（人間が読みやすい形式）
    File.open(txt_file, "a", encoding: "UTF-8") do |file|
      file.puts "=" * 80
      file.puts "お問い合わせ受信: #{timestamp}"
      file.puts "=" * 80
      file.puts "名前: #{name}"
      file.puts "メールアドレス: #{email}"
      file.puts "カテゴリー: #{category}"
      file.puts "メッセージ:"
      file.puts message
      file.puts "=" * 80
      file.puts ""
    end

    Rails.logger.info "お問い合わせ内容をファイルに保存しました: #{csv_file}"
  rescue => e
    Rails.logger.error "ファイル保存エラー: #{e.message}"
  end

  public

  def rankings
    # 4年制・非営利大学のみを対象
    base_scope = Condition
      .where(privateorpublic: [ "私立", "州立" ])
      .where("carnegie_basic >= 15")
      .includes(:university_translations)

    # 学費が安い大学TOP50
    @cheap_tuition = base_scope
      .where.not(tuition: nil)
      .where("tuition > 0")
      .order(tuition: :asc)
      .limit(50)

    # 合格率が高い大学TOP50（入りやすい）
    @high_acceptance = base_scope
      .where.not(acceptance_rate: nil)
      .where("acceptance_rate > 0")
      .order(acceptance_rate: :desc)
      .limit(50)

    # 卒業率が高い大学TOP50
    @high_graduation = base_scope
      .where.not(graduation_rate: nil)
      .where("graduation_rate > 0")
      .order(graduation_rate: :desc)
      .limit(50)

    # 卒業後の年収が高い大学TOP50
    @high_earnings = base_scope
      .where.not(earnings_10yr_median: nil)
      .where("earnings_10yr_median > 0")
      .order(earnings_10yr_median: :desc)
      .limit(50)
  end
end
