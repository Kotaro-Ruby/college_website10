class Admin::SurveysController < AdminBaseController
  def index
    @total_responses = SurveyResponse.count
    @average_rating = SurveyResponse.average_rating
    @rating_distribution = SurveyResponse.rating_distribution
    @recent_responses = SurveyResponse.order(created_at: :desc).limit(50)
    @purpose_distribution = SurveyResponse.where.not(purpose: [nil, '']).group(:purpose).count
    
    # 週次統計
    @responses_this_week = SurveyResponse.where('created_at >= ?', 1.week.ago).count
    @responses_this_month = SurveyResponse.where('created_at >= ?', 1.month.ago).count
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
        headers['Content-Disposition'] = "attachment; filename=\"survey_responses_#{Date.current}.csv\""
        headers['Content-Type'] = 'text/csv'
      }
    end
  end
end