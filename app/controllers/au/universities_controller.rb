class Au::UniversitiesController < ApplicationController
  def index
    @universities = AuUniversity.all

    # フィルタリング
    if params[:state].present?
      @universities = @universities.where(state: params[:state])
    end

    # 授業料範囲のチェックボックス処理
    if params[:tuition_range].present? && params[:tuition_range].is_a?(Array)
      tuition_conditions = []
      params[:tuition_range].each do |range|
        min, max = range.split('-').map(&:to_i)
        # 大学の最低授業料が選択範囲の最大値以下、かつ最高授業料が選択範囲の最小値以上
        # これにより、選択範囲内にコースがある大学を取得
        tuition_conditions << "(min_annual_tuition <= #{max} AND (max_annual_tuition >= #{min} OR max_annual_tuition IS NULL))"
      end
      @universities = @universities.where(tuition_conditions.join(' OR '))
    elsif params[:min_tuition].present? || params[:max_tuition].present?
      # スライダーからの授業料フィルタリング
      min_tuition = params[:min_tuition].to_i
      max_tuition = params[:max_tuition].to_i
      
      if min_tuition > 0 || max_tuition < 80000
        @universities = @universities.where(
          "(min_annual_tuition <= ? AND (max_annual_tuition >= ? OR max_annual_tuition IS NULL))",
          max_tuition, min_tuition
        )
      end
    end

    # 複数の専攻分野での検索に対応
    if params[:fields].present?
      if params[:fields].is_a?(Array)
        # 配列の場合、いずれかの分野を含む大学を検索
        field_conditions = params[:fields].map { |f| "popular_fields LIKE ?" }.join(" OR ")
        field_values = params[:fields].map { |f| "%#{f}%" }
        @universities = @universities.where(field_conditions, *field_values)
      else
        # 単一の値の場合
        @universities = @universities.where("popular_fields LIKE ?", "%#{params[:fields]}%")
      end
    end

    # ソート
    case params[:sort]
    when "name"
      @universities = @universities.order(:name)
    when "students"
      @universities = @universities.order(total_students_2023: :desc)
    when "courses"
      @universities = @universities.order(total_courses_count: :desc)
    else
      @universities = @universities.order(:name)
    end

    @total_count = @universities.count
    
    # AJAXリクエストに対応
    respond_to do |format|
      format.html # 通常のHTMLレスポンス
      format.json { render json: @universities }
    end
  end

  def search
    @query = params[:q]
    @universities = AuUniversity.all

    if @query.present?
      # 大学名、都市、州で検索
      @universities = @universities.where(
        "name LIKE ? OR city LIKE ? OR state LIKE ?",
        "%#{@query}%", "%#{@query}%", "%#{@query}%"
      )
    end

    # 分野での絞り込み
    if params[:fields].present? && params[:fields].is_a?(Array)
      field_conditions = params[:fields].map { |field| "popular_fields LIKE ?" }.join(" OR ")
      field_values = params[:fields].map { |field| "%#{field}%" }
      @universities = @universities.where(field_conditions, *field_values)
    end

    # ソート
    case params[:sort]
    when "name"
      @universities = @universities.order(:name)
    when "students"
      @universities = @universities.order(total_students_2023: :desc)
    when "courses"
      @universities = @universities.order(total_courses_count: :desc)
    else
      @universities = @universities.order(:name)
    end

    @total_count = @universities.count
    
    # AJAXリクエストに対応
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @universities }
    end
  end

  def show
    @university = AuUniversity.find(params[:id])
    @courses = @university.au_courses.active

    # コースのフィルタリング
    if params[:level].present?
      case params[:level]
      when "bachelor"
        @courses = @courses.bachelor
      when "masters"
        @courses = @courses.masters
      when "doctoral"
        @courses = @courses.doctoral
      end
    end

    if params[:field].present?
      @courses = @courses.where(field_of_education_broad: params[:field])
    end

    # 並べ替え
    case params[:sort]
    when "name"
      @courses = @courses.order(:course_name)
    when "tuition_asc"
      @courses = @courses.order(annual_tuition_fee: :asc)
    when "tuition_desc"
      @courses = @courses.order(annual_tuition_fee: :desc)
    when "duration_asc"
      @courses = @courses.order(duration_years: :asc)
    when "duration_desc"
      @courses = @courses.order(duration_years: :desc)
    else
      @courses = @courses.order(:course_name) # デフォルトはコース名順
    end

    @courses = @courses.page(params[:page]).per(20)
  end

  def about
    # 国の基本情報を取得
    @country = Country.find_by(code: 'AU')
    
    # オーストラリアの大学統計情報
    @total_universities = AuUniversity.count
    @total_courses = AuCourse.count
    @total_students = AuUniversity.sum("COALESCE(total_students_2023, 0)")
    @total_international_students = AuUniversity.sum("COALESCE(overseas_students_2023, 0)")

    # 州別の大学数
    @universities_by_state = AuUniversity.group(:state).count

    # 人気の専攻分野（コースの分野別集計）
    @popular_fields = AuCourse.group(:field_of_education_broad)
                              .count
                              .sort_by { |_, count| -count }
                              .first(10)

    # トップ大学（学生数順）
    @top_universities = AuUniversity.where.not(total_students_2023: nil)
                                    .order(total_students_2023: :desc)
                                    .limit(8)
  end

  def group_of_eight
  end

  def popular_cities
  end

  def scholarships
  end
end
