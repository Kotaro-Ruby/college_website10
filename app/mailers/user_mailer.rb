class UserMailer < ApplicationMailer
  default from: 'noreply@college-finder.com'

  def password_reset(user)
    @user = user
    @reset_url = password_reset_url(@user.password_reset_token)
    
    mail(
      to: @user.email,
      subject: 'パスワードリセットのご案内'
    )
  end
end
