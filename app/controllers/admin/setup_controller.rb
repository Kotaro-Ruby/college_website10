class Admin::SetupController < ApplicationController
  layout 'admin'
  
  # 管理者が既に存在する場合、ログインページにリダイレクト
  before_action :redirect_if_admin_exists, except: [:show]
  
  def show
    # 管理者が存在する場合、ログインページにリダイレクト
    if Admin.exists_admin?
      redirect_to admin_login_path
      return
    end
    
    @admin = Admin.new
  end
  
  def create
    @admin = Admin.create_initial_admin(
      setup_params[:username],
      setup_params[:email],
      setup_params[:password]
    )
    
    if @admin
      # 初期管理者作成成功
      @admin.record_sign_in!
      session[:admin_id] = @admin.id
      session[:admin_session_token] = @admin.session_token
      session[:admin_last_activity] = Time.current
      
      flash[:notice] = "初期管理者が作成され、ログインしました"
      redirect_to admin_dashboard_path
    else
      # 作成失敗
      @admin = Admin.new(setup_params)
      flash.now[:alert] = "管理者の作成に失敗しました"
      render :show, status: :unprocessable_entity
    end
  end
  
  private
  
  def setup_params
    params.require(:admin).permit(:username, :email, :password, :password_confirmation)
  end
  
  def redirect_if_admin_exists
    if Admin.exists_admin?
      redirect_to admin_login_path
    end
  end
end