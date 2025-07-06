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
  
  private
  
  def survey_params
    params.permit(:rating, :purpose, :feedback)
  end
end