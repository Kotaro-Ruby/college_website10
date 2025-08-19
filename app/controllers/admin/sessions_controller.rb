class Admin::SessionsController < ApplicationController
  layout "admin"

  # ログイン済みの管理者はダッシュボードにリダイレクト
  before_action :redirect_if_authenticated, only: [ :new, :create ]

  def new
    # 管理者が存在しない場合、セットアップページにリダイレクト
    unless Admin.exists_admin?
      redirect_to admin_setup_path
      nil
    end
  end

  def create
    admin = Admin.find_by(username: params[:username])

    if admin && admin.authenticate(params[:password])
      # ログイン成功
      admin.record_sign_in!
      session[:admin_id] = admin.id
      session[:admin_session_token] = admin.session_token
      session[:admin_last_activity] = Time.current

      flash[:notice] = "ログインしました"
      redirect_to admin_dashboard_path
    else
      # ログイン失敗
      flash.now[:alert] = "ユーザー名またはパスワードが間違っています"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if current_admin
      current_admin.regenerate_session_token!
    end

    session[:admin_id] = nil
    session[:admin_session_token] = nil
    session[:admin_last_activity] = nil

    flash[:notice] = "ログアウトしました"
    redirect_to admin_login_path
  end

  private

  def redirect_if_authenticated
    if admin_logged_in?
      redirect_to admin_dashboard_path
    end
  end
end
