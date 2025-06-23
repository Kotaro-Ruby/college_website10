class UsersController < ApplicationController
  before_action :require_login, only: [:show, :edit, :update, :destroy]
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: 'ユーザー登録が完了しました'
    else
      render :new
    end
  end
  
  def show
    # ユーザープロフィール表示
  end
  
  def edit
    # ユーザー情報編集フォーム
  end
  
  def update
    if @user.update(user_update_params)
      redirect_to profile_path, notice: 'プロフィールが更新されました！'
    else
      render :edit
    end
  end
  
  def destroy
    @user.destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'アカウントが削除されました。'
  end

  private
  
  def set_user
    @user = current_user
  end
  
  def require_login
    unless logged_in?
      redirect_to login_path, alert: 'ログインが必要です。'
    end
  end

  def user_params
    params.require(:user).permit(:username, :password, :password_confirmation)
  end
  
  def user_update_params
    if params[:user][:password].present?
      params.require(:user).permit(:username, :password, :password_confirmation)
    else
      params.require(:user).permit(:username)
    end
  end
end