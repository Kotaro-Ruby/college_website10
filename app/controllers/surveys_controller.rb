class SurveysController < ApplicationController
  protect_from_forgery with: :null_session, only: [:create]
  
  def create
    survey_params_hash = survey_params.to_h
    survey_params_hash[:user_ip] = request.remote_ip
    survey_params_hash[:user_agent] = request.user_agent
    
    survey = SurveyResponse.new(survey_params_hash)
    
    if survey.save
      render json: { status: 'success', message: 'アンケートを保存しました' }
    else
      render json: { status: 'error', message: survey.errors.full_messages.join(', ') }, status: 422
    end
  rescue => e
    render json: { status: 'error', message: 'サーバーエラーが発生しました' }, status: 500
  end
  
  def admin
    redirect_to root_path unless admin_access?
    
    @total_responses = SurveyResponse.count
    @average_rating = SurveyResponse.average_rating
    @rating_distribution = SurveyResponse.rating_distribution
    @recent_responses = SurveyResponse.recent.limit(50)
    @purpose_distribution = SurveyResponse.where.not(purpose: [nil, '']).group(:purpose).count
  end
  
  private
  
  def survey_params
    params.permit(:rating, :purpose, :feedback)
  end
  
  def admin_access?
    # 簡単な管理者認証（本番環境では適切な認証を実装してください）
    params[:admin_key] == 'college_spark_admin_2025' || 
    request.headers['X-Admin-Key'] == 'college_spark_admin_2025'
  end
end