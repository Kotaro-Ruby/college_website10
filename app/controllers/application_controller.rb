class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  helper_method :current_user, :logged_in?, :recently_viewed_colleges, :current_admin, :admin_logged_in?, :get_popular_colleges
  
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
    if logged_in?
      # ログインしている場合はデータベースに保存
      view_history = current_user.view_histories.find_or_initialize_by(condition: college)
      view_history.viewed_at = Time.current
      view_history.save
      
      # 古い履歴を削除（最新6件のみ保持）
      old_histories = current_user.view_histories.offset(6)
      old_histories.destroy_all if old_histories.any?
    else
      # ログインしていない場合はセッションに保存
      session[:recently_viewed] ||= []
      session[:recently_viewed].delete(college.id)
      session[:recently_viewed].unshift(college.id)
      session[:recently_viewed] = session[:recently_viewed].first(6)
    end
  end
  
  def recently_viewed_colleges
    if logged_in?
      # ログインしている場合はデータベースから取得
      current_user.view_histories.includes(:condition).limit(6).map(&:condition)
    else
      # ログインしていない場合はセッションから取得
      return [] unless session[:recently_viewed].present?
      college_ids = session[:recently_viewed]
      colleges = Condition.where(id: college_ids)
      college_ids.map { |id| colleges.find { |c| c.id == id } }.compact
    end
  end
  
  # セッションを一時的にクリアして6校制限をテストするためのヘルパー
  def clear_recently_viewed_for_testing
    session[:recently_viewed] = nil if params[:clear_session] == 'true'
  end
  
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
  
  # 人気の大学を取得（全ユーザーの閲覧履歴から）
  def get_popular_colleges
    # ViewHistoryテーブルからcondition_idごとの閲覧数をカウント
    popular_condition_ids = ViewHistory
      .group(:condition_id)
      .order('count_all DESC')
      .limit(5)
      .count
      .keys
    
    # 閲覧数が多い順に大学を取得
    if popular_condition_ids.any?
      Condition.where(id: popular_condition_ids).index_by(&:id).slice(*popular_condition_ids).values
    else
      # まだ閲覧履歴がない場合は、デフォルトの人気大学を返す
      Condition.where.not(students: nil, acceptance_rate: nil)
               .where('acceptance_rate > 0.1 AND acceptance_rate < 0.8')
               .order(students: :desc)
               .limit(5)
    end
  end
end
