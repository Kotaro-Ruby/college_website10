class Admin::UsersController < ApplicationController
  def index
    # 簡単な認証チェック（実際のプロダクションではより堅牢な認証が必要）
    if params[:secret] != 'admin123'
      render plain: "アクセス拒否"
      return
    end
    
    @users = User.all.order(created_at: :desc)
    @total_users = @users.count
    @users_this_month = @users.where('created_at >= ?', 1.month.ago).count
    @users_today = @users.where('created_at >= ?', 1.day.ago).count
  end
end