class UserMailer < ApplicationMailer
  default from: 'College Spark <noreply@college-spark.app>'

  def password_reset(user)
    @user = user
    @reset_url = password_reset_url(@user.password_reset_token)
    
    mail(
      to: @user.email,
      subject: '[College Spark] パスワードリセットのご案内',
      from: 'College Spark <noreply@college-spark.app>'
    )
  end
end
