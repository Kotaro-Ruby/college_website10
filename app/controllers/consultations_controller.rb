class ConsultationsController < ApplicationController
  before_action :set_consultation, only: [:show]
  
  def new
    @consultation = Consultation.new
  end

  def create
    @consultation = Consultation.new(consultation_params)
    
    if @consultation.save
      begin
        # 相談予約をメールで通知
        ConsultationMailer.new_consultation_notification(@consultation).deliver_now
        
        Rails.logger.info "=" * 50
        Rails.logger.info "相談予約メール送信成功"
        Rails.logger.info "予約者: #{@consultation.name} (#{@consultation.email})"
        Rails.logger.info "宛先: collegespark2025@gmail.com"
        Rails.logger.info "送信時刻: #{Time.current}"
        Rails.logger.info "=" * 50
        
        redirect_to consultation_path(@consultation), notice: '無料相談のご予約を受け付けました。確認メールをお送りしています。'
      rescue => e
        Rails.logger.error "相談予約メール送信エラー: #{e.message}"
        # 予約は保存されているので、メール送信失敗でもリダイレクト
        redirect_to consultation_path(@consultation), notice: '無料相談のご予約を受け付けました。'
      end
    else
      render :new
    end
  end

  def show
    # 予約確認ページ
  end

  def index
    # ユーザー向けの一覧は表示しない
    redirect_to root_path
  end
  
  private
  
  def set_consultation
    @consultation = Consultation.find(params[:id])
  end
  
  def consultation_params
    permitted_params = params.require(:consultation).permit(
      :name, :email, :phone, :timezone, :consultation_type, :message,
      preferred_dates: [], preferred_times: []
    )
    
    # 複数の日時候補を処理
    if permitted_params[:preferred_dates].present? && permitted_params[:preferred_times].present?
      # 空の値を除去
      dates = permitted_params[:preferred_dates].reject(&:blank?)
      times = permitted_params[:preferred_times].reject(&:blank?)
      
      # 第1希望を設定（従来のフィールドとの互換性のため）
      if dates.first.present? && times.first.present?
        permitted_params[:preferred_date] = dates.first
        permitted_params[:preferred_time] = times.first
      end
      
      # 日時候補をJSONとして保存
      datetime_candidates = []
      [dates.length, times.length].min.times do |i|
        if dates[i].present? && times[i].present?
          datetime_candidates << {
            date: dates[i],
            time: times[i],
            priority: i + 1
          }
        end
      end
      
      permitted_params[:datetime_candidates] = datetime_candidates.to_json
    end
    
    permitted_params.except(:preferred_dates, :preferred_times)
  end
end
