class Admin::ConditionsController < AdminBaseController
  def index
    @conditions = Condition.order(:college)
    
    # 検索機能
    if params[:search].present?
      @conditions = @conditions.where("college ILIKE ?", "%#{params[:search]}%")
    end
    
    # ページネーション
    @conditions = @conditions.page(params[:page]).per(50)
    @total_conditions = Condition.count
  end
  
  def show
    @condition = Condition.find(params[:id])
  end
  
  def edit
    @condition = Condition.find(params[:id])
  end
  
  def update
    @condition = Condition.find(params[:id])
    
    if @condition.update(condition_params)
      redirect_to admin_conditions_path, notice: '大学情報を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @condition = Condition.find(params[:id])
    college_name = @condition.college
    
    if @condition.destroy
      flash[:notice] = "大学「#{college_name}」を削除しました"
    else
      flash[:alert] = "大学の削除に失敗しました"
    end
    
    redirect_to admin_conditions_path
  end
  
  private
  
  def condition_params
    params.require(:condition).permit(
      :college, :state, :city, :tuition, :students, :privateorpublic, 
      :GPA, :acceptance_rate, :graduation_rate, :Division, :comment,
      :pcip_business, :pcip_engineering, :pcip_computer_science,
      :pcip_psychology, :pcip_health_professions, :pcip_biological_sciences,
      :pcip_visual_performing_arts, :pcip_social_sciences, :pcip_education,
      :pcip_liberal_arts, :pcip_physical_sciences, :pcip_mathematics,
      :pcip_communications, :pcip_architecture, :pcip_agriculture,
      :international_student_ratio
    )
  end
end