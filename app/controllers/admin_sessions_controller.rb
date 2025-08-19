class AdminSessionsController < ApplicationController
  before_action :redirect_if_logged_in, only: [ :new, :create ]

  def new
    # ログインページを表示
  end

  def create
    admin = Admin.find_by(username: params[:username])

    if admin&.authenticate(params[:password])
      # ログイン成功
      admin.record_sign_in!
      session[:admin_id] = admin.id
      session[:admin_session_token] = admin.session_token

      flash[:success] = "ログインしました"
      redirect_to admin_dashboard_path
    else
      # ログイン失敗
      flash.now[:alert] = "ユーザー名またはパスワードが正しくありません"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # ログアウト
    if current_admin
      current_admin.regenerate_session_token!
    end

    session[:admin_id] = nil
    session[:admin_session_token] = nil
    flash[:success] = "ログアウトしました"
    redirect_to admin_login_path
  end

  private

  def redirect_if_logged_in
    if admin_logged_in?
      redirect_to admin_dashboard_path
    end
  end

  def current_admin
    @current_admin ||= begin
      if session[:admin_id] && session[:admin_session_token]
        admin = Admin.find_by(id: session[:admin_id])
        admin if admin&.session_token == session[:admin_session_token]
      end
    end
  end

  def admin_logged_in?
    current_admin.present?
  end
end
