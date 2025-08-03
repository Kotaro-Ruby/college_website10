class Admin::ConsultationsController < AdminBaseController
  before_action :set_consultation, only: [:show, :update, :destroy, :confirm, :cancel, :complete]
  
  def index
    @consultations = Consultation.all.order(created_at: :desc)
    @consultations = @consultations.where(status: params[:status]) if params[:status].present?
    @consultations = @consultations.where('preferred_date >= ?', Date.parse(params[:date_from])) if params[:date_from].present?
    @consultations = @consultations.where('preferred_date <= ?', Date.parse(params[:date_to])) if params[:date_to].present?
    # ページネーション（Kaminariがインストールされている場合）
    @consultations = @consultations.page(params[:page]).per(20) if defined?(Kaminari)
    
    @status_counts = {
      all: Consultation.count,
      pending: Consultation.pending.count,
      confirmed: Consultation.confirmed.count,
      completed: Consultation.completed.count,
      cancelled: Consultation.cancelled.count
    }
  end

  def show
    # 詳細表示
  end

  def update
    if @consultation.update(consultation_params)
      redirect_to admin_consultation_path(@consultation), notice: '相談情報を更新しました。'
    else
      render :show
    end
  end

  def destroy
    @consultation.destroy
    redirect_to admin_consultations_path, notice: '相談予約を削除しました。'
  end
  
  def confirm
    @consultation.update(status: 'confirmed')
    redirect_to admin_consultations_path, notice: '相談を確定しました。'
  end
  
  def cancel
    @consultation.update(status: 'cancelled')
    redirect_to admin_consultations_path, notice: '相談をキャンセルしました。'
  end
  
  def complete
    @consultation.update(status: 'completed')
    redirect_to admin_consultations_path, notice: '相談を完了にしました。'
  end
  
  private
  
  def set_consultation
    @consultation = Consultation.find(params[:id])
  end
  
  def consultation_params
    params.require(:consultation).permit(:admin_notes, :status)
  end
end
