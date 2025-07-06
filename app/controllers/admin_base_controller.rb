class AdminBaseController < ApplicationController
  layout 'admin'
  
  before_action :require_admin_login
  before_action :check_session_timeout
  
  # 管理者認証機能
  def current_admin
    @current_admin ||= begin
      if session[:admin_id] && session[:admin_session_token]
        admin = Admin.find_by(id: session[:admin_id])
        # セッショントークンの検証
        if admin && admin.session_token == session[:admin_session_token]
          admin
        else
          nil
        end
      else
        nil
      end
    end
  end
  
  def admin_logged_in?
    !!current_admin
  end
  
  def require_admin_login
    unless admin_logged_in?
      flash[:alert] = "管理者認証が必要です"
      redirect_to admin_login_path
    end
  end
  
  # セッションタイムアウト（30分）
  def check_session_timeout
    if session[:admin_last_activity]
      if session[:admin_last_activity] < 30.minutes.ago
        logout_admin
        flash[:alert] = "セッションがタイムアウトしました。再度ログインしてください"
        redirect_to admin_login_path
        return
      end
    end
    
    # セッションのアクティビティを更新
    session[:admin_last_activity] = Time.current
  end
  
  def logout_admin
    if current_admin
      current_admin.regenerate_session_token!
    end
    
    session[:admin_id] = nil
    session[:admin_session_token] = nil
    session[:admin_last_activity] = nil
    @current_admin = nil
  end
  
  # ヘルパーメソッドとして使用可能にする
  helper_method :current_admin, :admin_logged_in?
  
  private
  
  # CSRF保護を強化
  protect_from_forgery with: :exception
end