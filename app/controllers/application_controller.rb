class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  helper_method :current_user, :logged_in?, :recently_viewed_colleges
  
  private
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def logged_in?
    !!current_user
  end
  
  def require_login
    unless logged_in?
      flash[:alert] = 'ログインが必要です'
      redirect_to login_path
    end
  end
  
  # 最近閲覧した大学の管理
  def add_to_recently_viewed(college)
    session[:recently_viewed] ||= []
    
    # 既に存在する場合は削除（重複回避）
    session[:recently_viewed].delete(college.id)
    
    # 先頭に追加
    session[:recently_viewed].unshift(college.id)
    
    # 最大5校まで保持
    session[:recently_viewed] = session[:recently_viewed].first(5)
  end
  
  def recently_viewed_colleges
    return [] unless session[:recently_viewed].present?
    
    # IDの配列から大学オブジェクトを取得（順序を保持）
    college_ids = session[:recently_viewed]
    colleges = Condition.where(id: college_ids)
    
    # 元の順序を保持してソート
    college_ids.map { |id| colleges.find { |c| c.id == id } }.compact
  end
end
