class SessionsController < ApplicationController
  def new
    # ログインフォーム表示
  end

  def create
    # メールアドレスまたはユーザー名での認証に対応
    user = User.find_by(email: params[:email]&.downcase) || User.find_by(username: params[:email])
    
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: 'ログインしました'
    else
      flash.now[:alert] = 'メールアドレスまたはパスワードが間違っています'
      render :new
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'ログアウトしました'
  end
end