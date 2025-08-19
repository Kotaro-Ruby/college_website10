class Admin::DashboardController < AdminBaseController
  def index
    @total_users = User.count
    @total_colleges = Condition.count
    @total_survey_responses = SurveyResponse.count
    @total_admins = Admin.count

    # 最近の活動統計
    @users_this_week = User.where("created_at >= ?", 1.week.ago).count
    @survey_responses_this_week = SurveyResponse.where("created_at >= ?", 1.week.ago).count

    # 人気の大学（お気に入り数上位）
    @popular_colleges = Condition.joins(:favorites)
                                .group("conditions.id")
                                .order("COUNT(favorites.id) DESC")
                                .limit(10)
                                .select("conditions.*, COUNT(favorites.id) as favorites_count")

    # 最近のユーザー
    @recent_users = User.order(created_at: :desc).limit(5)

    # 最近のアンケート回答
    @recent_surveys = SurveyResponse.order(created_at: :desc).limit(5)
  end
end
