class Admin::SurveysController < AdminBaseController
  def index
    begin
      # Check if table exists
      unless ActiveRecord::Base.connection.table_exists?("survey_responses")
        @table_missing = true
        @total_responses = 0
        @average_rating = 0
        @rating_distribution = {}
        @recent_responses = []
        @purpose_distribution = {}
        @responses_this_week = 0
        @responses_this_month = 0
        return
      end

      @total_responses = SurveyResponse.count
      @average_rating = SurveyResponse.average_rating
      @rating_distribution = SurveyResponse.rating_distribution
      @recent_responses = SurveyResponse.order(created_at: :desc).limit(50)
      @purpose_distribution = SurveyResponse.where.not(purpose: [ nil, "" ]).group(:purpose).count

      # 週次統計
      @responses_this_week = SurveyResponse.where("created_at >= ?", 1.week.ago).count
      @responses_this_month = SurveyResponse.where("created_at >= ?", 1.month.ago).count
    rescue => e
      Rails.logger.error "Error in surveys admin: #{e.message}"
      @error_message = "データベースエラーが発生しました: #{e.message}"
      @total_responses = 0
      @average_rating = 0
      @rating_distribution = {}
      @recent_responses = []
      @purpose_distribution = {}
      @responses_this_week = 0
      @responses_this_month = 0
    end
  end

  def show
    @survey = SurveyResponse.find(params[:id])
  end

  def destroy
    @survey = SurveyResponse.find(params[:id])

    if @survey.destroy
      flash[:notice] = "アンケート回答を削除しました"
    else
      flash[:alert] = "削除に失敗しました"
    end

    redirect_to admin_surveys_path
  end

  def destroy_all
    count = SurveyResponse.count
    SurveyResponse.destroy_all

    flash[:notice] = "#{count}件のアンケートデータを削除しました"
    redirect_to admin_surveys_path
  end

  def export_csv
    @surveys = SurveyResponse.order(created_at: :desc)

    respond_to do |format|
      format.csv {
        headers["Content-Disposition"] = "attachment; filename=\"survey_responses_#{Date.current}.csv\""
        headers["Content-Type"] = "text/csv"
      }
    end
  end
end
