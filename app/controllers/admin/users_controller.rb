class Admin::UsersController < AdminBaseController
  def index
    @users = User.all.order(created_at: :desc)
    @total_users = @users.count
    @users_this_month = @users.where("created_at >= ?", 1.month.ago).count
    @users_today = @users.where("created_at >= ?", 1.day.ago).count
    @users_this_week = @users.where("created_at >= ?", 1.week.ago).count

    # ページネーション用
    @users = @users.page(params[:page]).per(50)
  end

  def show
    @user = User.find(params[:id])
    @user_favorites = @user.favorites.includes(:condition)
  end

  def destroy
    @user = User.find(params[:id])
    username = @user.username

    if @user.destroy
      flash[:notice] = "ユーザー「#{username}」を削除しました"
    else
      flash[:alert] = "ユーザーの削除に失敗しました"
    end

    redirect_to admin_users_path
  end
end
