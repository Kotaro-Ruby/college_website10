class PasswordResetsController < ApplicationController
  before_action :find_user_by_token, only: [:show, :update]
  
  def new
    # パスワードリセット申請フォーム
  end

  def create
    email = params[:email]&.downcase&.strip
    @user = User.find_by(email: email)
    
    respond_to do |format|
      if @user
        begin
          @user.create_password_reset_token
          UserMailer.password_reset(@user).deliver_now
          
          Rails.logger.info "パスワードリセットメール送信成功: #{email}"
          
          format.html { redirect_to login_path, notice: 'パスワードリセットのメールを送信しました' }
          format.json { 
            render json: { 
              status: 'success', 
              message: 'パスワードリセットのメールを送信しました。メールボックスをご確認ください。' 
            }
          }
          
        rescue => e
          Rails.logger.error "パスワードリセットメール送信エラー: #{e.message}"
          
          format.html { 
            flash.now[:alert] = 'メール送信に失敗しました。しばらく後でもう一度お試しください。'
            render :new 
          }
          format.json { 
            render json: { 
              status: 'error', 
              message: 'メール送信に失敗しました。しばらく後でもう一度お試しください。' 
            }
          }
        end
      else
        Rails.logger.warn "パスワードリセット: 未登録メールアドレス #{email}"
        
        format.html { 
          flash.now[:alert] = 'そのメールアドレスは登録されていません'
          render :new 
        }
        format.json { 
          render json: { 
            status: 'error', 
            message: 'そのメールアドレスは登録されていません。正しいメールアドレスを入力してください。' 
          }
        }
      end
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

    if params[:user][:password].present? && 
       params[:user][:password] == params[:user][:password_confirmation] &&
       @user.update(password_params)
      
      @user.clear_password_reset
      session[:user_id] = @user.id
      
      Rails.logger.info "パスワードリセット完了: #{@user.email}"
      redirect_to root_path, notice: 'パスワードが正常に更新されました。ログインしました。'
    else
      if params[:user][:password].blank?
        flash.now[:alert] = 'パスワードを入力してください'
      elsif params[:user][:password] != params[:user][:password_confirmation]
        flash.now[:alert] = 'パスワードと確認用パスワードが一致しません'
      elsif params[:user][:password].length < 6
        flash.now[:alert] = 'パスワードは6文字以上で入力してください'
      else
        flash.now[:alert] = 'パスワードの更新に失敗しました'
      end
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