class Admin::ConditionsController < ApplicationController
  before_action :require_admin
  
  def index
    @conditions = Condition.order(:college).page(params[:page]).per(50)
  end
  
  def edit
    @condition = Condition.find(params[:id])
  end
  
  def update
    @condition = Condition.find(params[:id])
    
    if @condition.update(condition_params)
      redirect_to admin_conditions_path, notice: '更新しました'
    else
      render :edit
    end
  end
  
  private
  
  def condition_params
    params.require(:condition).permit(:Division, :tuition, :comment)
  end
  
  def require_admin
    # 管理者権限のチェック（簡易版）
    unless current_user && current_user.username == 'admin'
      redirect_to root_path, alert: '権限がありません'
    end
  end
end