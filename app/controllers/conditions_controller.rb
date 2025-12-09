class ConditionsController < ApplicationController
  # 結果を取得するメインアクション
  def results
    Rails.logger.debug("Results action called with params: #{params.inspect}")
    scope = Condition.all

    # 大学名検索の処理（英語名・日本語名・都市名対応）
    if params[:college_name].present?
      query = params[:college_name].strip
      query_lower = query.downcase

      # 日本語かどうか判定
      is_japanese = query.match?(/\p{Hiragana}|\p{Katakana}|\p{Han}/)

      if is_japanese
        # 日本語名で検索
        translation_ids = UniversityTranslation
          .where(locale: "ja")
          .where("LOWER(name) LIKE ?", "%#{query_lower}%")
          .pluck(:condition_id)

        if translation_ids.any?
          scope = scope.where(id: translation_ids)
        else
          # 該当なしの場合は空の結果を返す
          scope = scope.none
        end
      else
        # 英語検索（大学名のみ）
        search_patterns = [
          query_lower,
          query_lower.gsub(/[^a-z0-9\s]/, ""),
          query_lower.gsub(/\s+/, ""),
          query_lower.split.join("%")
        ]

        # 大学名での検索条件
        college_conditions = search_patterns.map do |pattern|
          "LOWER(REPLACE(college, ' ', '')) LIKE ?"
        end.join(" OR ")
        college_values = search_patterns.map { |pattern| "%#{pattern.gsub(/\s+/, '')}%" }

        scope = scope.where(college_conditions, *college_values)
      end

      Rails.logger.debug("College name search: #{query} (Japanese: #{is_japanese})")
      Rails.logger.debug("Generated SQL Query: #{scope.to_sql}")
    end

    # State の処理（大学名検索の場合はスキップ）
    unless params[:college_name].present?
      if params[:state].blank? || params[:state] == "選択してください"
        # フロントエンドでバリデーションを行うため、サーバー側では検索ページにリダイレクト
        redirect_to "/search" and return
      elsif params[:state] != "指定しない"
        state = params[:state]
        # 日本語表記から州コードを抽出 例: "カリフォルニア州(CA)" -> "CA"
        if state.match(/\(([A-Z]{2})\)$/)
          state_code = state.match(/\(([A-Z]{2})\)$/)[1]
          scope = scope.where("state = ?", state_code)
        else
          # 既に州コードの場合はそのまま使用
          scope = scope.where("state = ?", state)
        end
      end
    end

    # 大学タイプの処理（大学名検索の場合はスキップ）
    unless params[:college_name].present?
      if params[:privateorpublic].present?
        university_type = params[:privateorpublic]

        case university_type
        when "4年制"
          # 4年制（私立+州立）: Carnegie 15以上
          scope = scope.where("carnegie_basic >= 15").where(privateorpublic: ["私立", "州立"])
        when "4年制私立"
          scope = scope.where("carnegie_basic >= 15").where(privateorpublic: "私立")
        when "4年制州立"
          scope = scope.where("carnegie_basic >= 15").where(privateorpublic: "州立")
        when "2年制（コミカレ等）"
          # 2年制: Carnegie 1-14
          scope = scope.where("carnegie_basic BETWEEN 1 AND 14")
        when "営利"
          scope = scope.where(privateorpublic: "営利")
        end
      end
    end

    # Tuition の処理（大学名検索の場合はスキップ）
    unless params[:college_name].present?
      if params[:tuition].present? && params[:tuition] != "指定しない"
        tuition_range = parse_tuition_range(params[:tuition])
        if tuition_range
          Rails.logger.debug("Tuition range is valid: #{tuition_range.inspect}")
          # tuition_range[1] が無限大の場合、999999に設定する
          max_tuition = tuition_range[1] == Float::INFINITY ? 999_999 : tuition_range[1]
          # 範囲内のデータとnil/0（N/A）を検索に含める
          scope = scope.where("(tuition BETWEEN ? AND ?) OR tuition IS NULL OR tuition = 0", tuition_range[0], max_tuition)
        else
          Rails.logger.debug("Invalid tuition range: #{params[:tuition]}")
        end
      end
    end

    # Students の処理（大学名検索の場合はスキップ）
    unless params[:college_name].present?
      if params[:students].present?
        students_ranges = parse_students_range(params[:students])  # 複数の範囲を処理

        if students_ranges
          # 複数の範囲を OR 条件で処理する場合
          # SQL文字列を安全に構築
          conditions = students_ranges.map { "students BETWEEN ? AND ?" }
          sql_string = conditions.join(" OR ")
          scope = scope.where(sql_string, *students_ranges.flatten)
        else
          Rails.logger.debug("Invalid students range: #{params[:students]}")
        end
      end

      # SATスコアの処理
      if params[:sat_score].present? && params[:sat_score] != "指定しない"
        sat_range = parse_sat_range(params[:sat_score])
        if sat_range
          Rails.logger.debug("SAT range is valid: #{sat_range.inspect}")
          # SAT数学と読解の合計スコアで検索（25th percentileで検索）
          scope = scope.where("(sat_math_25 + sat_reading_25) BETWEEN ? AND ? OR (sat_math_75 + sat_reading_75) BETWEEN ? AND ?",
                             sat_range[0], sat_range[1], sat_range[0], sat_range[1])
          Rails.logger.debug("Query for SAT: #{scope.to_sql}")
        else
          Rails.logger.debug("Invalid SAT range: #{params[:sat_score]}")
        end
      end

      # ACTスコアの処理
      if params[:act_score].present? && params[:act_score] != "指定しない"
        act_range = parse_act_range(params[:act_score])
        if act_range
          Rails.logger.debug("ACT range is valid: #{act_range.inspect}")
          # ACT総合スコアで検索（25th percentileで検索）
          scope = scope.where("act_composite_25 BETWEEN ? AND ? OR act_composite_75 BETWEEN ? AND ?",
                             act_range[0], act_range[1], act_range[0], act_range[1])
          Rails.logger.debug("Query for ACT: #{scope.to_sql}")
        else
          Rails.logger.debug("Invalid ACT range: #{params[:act_score]}")
        end
      end

      # Division の処理
      if params[:Division].present?
        divisions = params[:Division].split(",") # 選択肢がカンマ区切りで渡されることを想定
        if divisions.include?("すべて")
          # 「すべて」が含まれている場合、Division の条件を無視
          Rails.logger.debug("All Divisions selected, no filtering applied.")
        else
          # OR 条件で抽出する
          scope = scope.where("Division IN (?)", divisions)
          Rails.logger.debug("Filtering by Divisions: #{divisions.inspect}")
        end
      end

      # Major の処理
      if params[:major].present? && params[:major] != "未選択"
        # 専攻フィルタリング：選択された専攻分野で検索
        majors = params[:major].is_a?(Array) ? params[:major] : params[:major].split(",").map(&:strip)
        major_conditions = []

        majors.each do |major|
          case major
          when "agriculture"
            major_conditions << "pcip_agriculture > 0"
          when "natural_resources"
            major_conditions << "pcip_natural_resources > 0"
          when "communication"
            major_conditions << "pcip_communication > 0"
          when "computer_science"
            major_conditions << "pcip_computer_science > 0"
          when "education"
            major_conditions << "pcip_education > 0"
          when "engineering"
            major_conditions << "pcip_engineering > 0"
          when "foreign_languages"
            major_conditions << "pcip_foreign_languages > 0"
          when "english"
            major_conditions << "pcip_english > 0"
          when "biology"
            major_conditions << "pcip_biology > 0"
          when "mathematics"
            major_conditions << "pcip_mathematics > 0"
          when "psychology"
            major_conditions << "pcip_psychology > 0"
          when "sociology"
            major_conditions << "pcip_sociology > 0"
          when "social_sciences"
            major_conditions << "pcip_social_sciences > 0"
          when "visual_arts"
            major_conditions << "pcip_visual_arts > 0"
          when "business"
            major_conditions << "pcip_business > 0"
          when "health_professions"
            major_conditions << "pcip_health_professions > 0"
          when "history"
            major_conditions << "pcip_history > 0"
          when "philosophy"
            major_conditions << "pcip_philosophy > 0"
          when "physical_sciences"
            major_conditions << "pcip_physical_sciences > 0"
          when "law"
            major_conditions << "pcip_law > 0"
          end
        end

        if major_conditions.any?
          scope = scope.where(major_conditions.join(" OR "))
          Rails.logger.debug("Filtering by majors: #{majors.inspect}")
        end
      else
        Rails.logger.debug("No major selected, no filtering applied.")
      end

      # Urbanicity の処理
      if params[:urbanicity].present?
        urbanicities = params[:urbanicity].split(",").map(&:strip)

        # 日本語表示名をDBの値にマッピング
        db_urbanicities = urbanicities.map do |urbanicity|
          case urbanicity
          when "大都市"
            [ "11" ]  # City: Large
          when "中小都市"
            [ "12", "13" ]  # City: Midsize/Small
          when "郊外"
            [ "21", "22", "23" ]  # Suburb
          when "地方の町"
            [ "31", "32", "33" ]  # Town
          when "田舎"
            [ "41", "42", "43" ]  # Rural
          else
            urbanicity
          end
        end.flatten

        if db_urbanicities.any?
          scope = scope.where(urbanicity: db_urbanicities)
          Rails.logger.debug("Filtering by urbanicities: #{db_urbanicities.inspect}")
        end
      end

      # Graduation Rate の処理
      if params[:graduation_rate].present? && params[:graduation_rate] != "指定しない"
        # パラメータから数値を抽出 (例: "50%~" → 50)
        if params[:graduation_rate].match?(/(\d+)%~/)
          min_rate = params[:graduation_rate].match(/(\d+)%~/)[1].to_f / 100.0
          scope = scope.where("graduation_rate >= ?", min_rate)
          Rails.logger.debug("Filtering by graduation rate >= #{min_rate}")
        end
      end
    end

    # ソート処理の追加
    if params[:sort].present?
      sort_column, sort_direction = params[:sort].split("-")

      case sort_column
      when "name"
        scope = scope.order(Arel.sql("college #{sort_direction == 'asc' ? 'ASC' : 'DESC'}"))
      when "state"
        scope = scope.order(Arel.sql("state #{sort_direction == 'asc' ? 'ASC' : 'DESC'}"))
      when "students"
        scope = scope.order(Arel.sql("students #{sort_direction == 'asc' ? 'ASC' : 'DESC'} NULLS LAST"))
      when "tuition"
        scope = scope.order(Arel.sql("tuition #{sort_direction == 'asc' ? 'ASC' : 'DESC'} NULLS LAST"))
      when "graduation"
        scope = scope.order(Arel.sql("graduation_rate #{sort_direction == 'asc' ? 'ASC' : 'DESC'} NULLS LAST"))
      end

      Rails.logger.debug("Sorting by #{sort_column} #{sort_direction}")
    end

    # 件数のみ返す場合（動的件数表示用）
    if params[:count_only] == "true"
      render json: { count: scope.count }
      return
    end

    # ページネーションの追加
    page = params[:page] || 1
    per_page = params[:per_page] || 20

    @results = scope.page(page).per(per_page)
    @total_count = scope.count
    Rails.logger.debug("Generated SQL Query: #{@results.to_sql}")

    render "results"
  end

  def autocomplete
    query = params[:q].to_s.strip.downcase
    return render json: [] if query.length < 2

    # 検索結果を格納
    results = []

    # 英語名で検索（部分一致）
    english_matches = Condition
      .where("LOWER(college) LIKE ?", "%#{query}%")
      .includes(:university_translations)
      .limit(10)

    english_matches.each do |college|
      ja_name = college.university_translations.find { |t| t.locale == "ja" }&.name
      results << {
        id: college.id,
        slug: college.slug,
        name: college.college,
        ja_name: ja_name,
        city: college.city,
        state: college.state,
        match_type: "english"
      }
    end

    # 日本語名で検索
    if query.match?(/\p{Hiragana}|\p{Katakana}|\p{Han}/)
      ja_matches = UniversityTranslation
        .where(locale: "ja")
        .where("LOWER(name) LIKE ?", "%#{query}%")
        .includes(:condition)
        .limit(10)

      ja_matches.each do |translation|
        next unless translation.condition
        # 既に英語名検索で見つかっていたらスキップ
        next if results.any? { |r| r[:id] == translation.condition.id }

        results << {
          id: translation.condition.id,
          slug: translation.condition.slug,
          name: translation.condition.college,
          ja_name: translation.name,
          city: translation.condition.city,
          state: translation.condition.state,
          match_type: "japanese"
        }
      end
    end

    # 最大10件に制限
    render json: results.first(10)
  end

  def show
    @college = Condition.find_by(slug: params[:id]) || Condition.find_by(id: params[:id])
    Rails.logger.debug("College found: #{@college.inspect}")

    # 検索結果からの参照元URLを保存
    if request.referer && request.referer.include?("/results")
      session[:search_results_url] = request.referer
    end

    if @college
      begin
        # Unsplash APIから大学の画像を取得
        @unsplash_service = UnsplashService.new
        Rails.logger.info "Fetching photo for: #{@college.college}"
        @college_photo = @unsplash_service.get_cached_photo(@college.college, "USA")
        Rails.logger.info "Photo result: #{@college_photo.inspect}"
      rescue => e
        Rails.logger.error "Error fetching photo: #{e.message}"
        @college_photo = nil
      end

      # 閲覧履歴に追加
      add_to_recently_viewed(@college) rescue nil

      # 関連大学を取得（同じ州で4年制・非営利、日本語名があるものを優先）
      @related_colleges = Condition
        .where(state: @college.state)
        .where.not(id: @college.id)
        .where(privateorpublic: [ "私立", "州立" ])
        .where("carnegie_basic >= 15")
        .includes(:university_translations)
        .order(Arel.sql("CASE WHEN id IN (SELECT condition_id FROM university_translations WHERE locale = 'ja') THEN 0 ELSE 1 END"))
        .limit(6)

      render :show
    else
      redirect_to :fallback_page
    end
  end

  def fallback_page
    render plain: "申し訳ありませんが、このページはまだ作成されていません。", status: :not_found
  end

  private

    # tuitionの追加処理
    def parse_tuition_range(tuition_param)
    return nil unless tuition_param.present?

    # ユーザーが選んだパラメータが「~$9999」形式の場合
    if tuition_param.match?(/^~\$\d+(?:,\d{3})*$/)
      max_value = tuition_param.gsub("~$", "").gsub(",", "").to_i
      [ 0, max_value ]  # 0 から最大金額まで

    # ユーザーが選んだパラメータが「$3000~$9999」形式の場合
    elsif tuition_param.match?(/^\$\d+(?:,\d{3})*~\$\d+(?:,\d{3})*$/)
      range = tuition_param.scan(/\d+(?:,\d{3})*/).map { |num| num.gsub(",", "").to_i }
      range.minmax  # 範囲を最小値と最大値として返す

    # ユーザーが選んだパラメータが「$3000~」形式の場合
    elsif tuition_param.match?(/^\$\d+(?:,\d{3})*~$/)
      min_value = tuition_param.gsub("$", "").gsub(",", "").to_i
      # 無制限を最大値（例えば999999）に変換
      [ min_value, 999_999 ]  # 最小金額から最大金額まで

    else
      nil
    end
  end

  # studentsの追加処理
  def parse_students_range(students_param)
    Rails.logger.debug("Students param received: #{students_param}")

    # 学生数範囲の日本語を対応する数字に変換
    students_param = students_param.gsub("小規模(~2999人)", "0~2999")
                                   .gsub("中規模(3000人~9999人)", "3000~9999")
                                   .gsub("大規模(10,000人~29,999人)", "10000~29999")
                                   .gsub("超大規模(30,000人~)", "30000~")

    return nil unless students_param.present?

    ranges = []

    students_param.split(",").each do |range_str|
      Rails.logger.debug("Processing range string: #{range_str}")

      # 範囲の解析
      if range_str.match?(/(\d+)(~?)(\d*)/)
        match_data = range_str.match(/(\d+)(~?)(\d*)/)
        min_value = match_data[1].to_i
        max_value = match_data[3].present? ? match_data[3].to_i : nil

        # "小規模" (0~2999) と "超大規模" (30000~) の特殊ケース
        if min_value == 0 && max_value.nil?
          ranges << [ 0, 2999 ]  # 0〜2999
        elsif min_value == 30000 && max_value.nil?
          ranges << [ 30000, 1000000 ]  # 30000〜非常に大きな値（1000000 など）
        elsif max_value
          ranges << [ min_value, max_value ]
        else
          ranges << [ min_value, min_value ]
        end

        Rails.logger.debug("Parsed range: #{ranges.inspect}")
      else
        Rails.logger.debug("No match for students range: #{range_str}")
      end
    end

    Rails.logger.debug("Final ranges: #{ranges.inspect}")
    ranges.empty? ? nil : ranges
  end


# Graduation Rate の範囲をパースする
def parse_graduation_rate_range(param)
  return nil unless param.present?

  # 例: "50~60" → [0.5, 0.6]
  if param.match?(/^(\d{1,2}|100)~(\d{1,2}|100)$/)
    range = param.split("~").map(&:to_f).map { |v| v / 100.0 }
    return range.minmax
  elsif param.match?(/^~(\d{1,2}|100)$/)
    max = param.gsub("~", "").to_f / 100.0
    return [ 0.0, max ]
  elsif param.match?(/^(\d{1,2}|100)~$/)
    min = param.gsub("~", "").to_f / 100.0
    return [ min, 1.0 ]
  end

  nil
end



  # SATスコアの範囲を解析するメソッド
  def parse_sat_range(sat_param)
    return nil unless sat_param.present?

    case sat_param
    when "800~1000"
      [ 800, 1000 ]
    when "1000~1200"
      [ 1000, 1200 ]
    when "1200~1400"
      [ 1200, 1400 ]
    when "1400~1600"
      [ 1400, 1600 ]
    else
      nil
    end
  end

  # ACTスコアの範囲を解析するメソッド
  def parse_act_range(act_param)
    return nil unless act_param.present?

    case act_param
    when "10~15"
      [ 10, 15 ]
    when "16~20"
      [ 16, 20 ]
    when "21~25"
      [ 21, 25 ]
    when "26~30"
      [ 26, 30 ]
    when "31~36"
      [ 31, 36 ]
    else
      nil
    end
  end
end
