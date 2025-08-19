class Au::UniversitiesController < ApplicationController
  def index
    @universities = AuUniversity.all

    # フィルタリング
    if params[:state].present?
      @universities = @universities.where(state: params[:state])
    end

    if params[:min_tuition].present?
      @universities = @universities.where("min_annual_tuition >= ?", params[:min_tuition])
    end

    if params[:max_tuition].present?
      @universities = @universities.where("max_annual_tuition <= ?", params[:max_tuition])
    end

    if params[:field].present?
      @universities = @universities.where("popular_fields LIKE ?", "%#{params[:field]}%")
    end

    # ソート
    case params[:sort]
    when "name"
      @universities = @universities.order(:name)
    when "tuition_low"
      @universities = @universities.order(:min_annual_tuition)
    when "tuition_high"
      @universities = @universities.order(max_annual_tuition: :desc)
    when "courses"
      @universities = @universities.order(total_courses_count: :desc)
    else
      @universities = @universities.order(:name)
    end

    @total_count = @universities.count
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

      # コース名でも検索
      if params[:search_courses] == "1"
        course_uni_ids = AuCourse.where("course_name LIKE ?", "%#{@query}%").pluck(:au_university_id).uniq
        @universities = @universities.or(AuUniversity.where(id: course_uni_ids))
      end
    end

    @total_count = @universities.count
    render :index
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

    @courses = @courses.page(params[:page]).per(20)
  end

  def about
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
end
