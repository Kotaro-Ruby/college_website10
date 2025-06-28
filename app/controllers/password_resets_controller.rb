class PasswordResetsController < ApplicationController
  before_action :find_user_by_token, only: [:show, :update]
  
  def new
    # パスワードリセット申請フォーム
  end

  def create
    @user = User.find_by(email: params[:email]&.downcase)
    
    if @user
      @user.create_password_reset_token
      UserMailer.password_reset(@user).deliver_now
      redirect_to login_path, notice: 'パスワードリセットのメールを送信しました'
    else
      flash.now[:alert] = 'そのメールアドレスは登録されていません'
      render :new
    end
  end

  def show
    # パスワードリセットフォーム表示
    if @user.nil? || @user.password_reset_expired?
      redirect_to new_password_reset_path, alert: 'パスワードリセットリンクが無効または期限切れです'
    end
  end

  def update
    if @user.nil? || @user.password_reset_expired?
      redirect_to new_password_reset_path, alert: 'パスワードリセットリンクが無効または期限切れです'
      return
    end

    if params[:user][:password].present? && @user.update(password_params)
      @user.clear_password_reset
      session[:user_id] = @user.id
      redirect_to root_path, notice: 'パスワードが正常に更新されました'
    else
      flash.now[:alert] = 'パスワードの更新に失敗しました'
      render :show
    end
  end

  private

  def find_user_by_token
    @user = User.find_by(password_reset_token: params[:id])
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end