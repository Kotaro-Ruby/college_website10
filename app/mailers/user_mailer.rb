class UserMailer < ApplicationMailer
  default from: "College Spark <collegespark2025@gmail.com>"

  def password_reset(user)
    @user = user
    # Use the actual token as the ID parameter for the password_reset route
    host = default_url_options[:host] || "localhost"
    port = default_url_options[:port] || 3000
    protocol = Rails.env.production? ? "https" : "http"
    base_url = port == 80 || port == 443 ? "#{protocol}://#{host}" : "#{protocol}://#{host}:#{port}"
    @reset_url = "#{base_url}/password_resets/#{@user.password_reset_token}"

    Rails.logger.info "Password reset email URL generated: #{@reset_url}"
    Rails.logger.info "User token: #{@user.password_reset_token}"

    mail(
      to: @user.email,
      subject: "[College Spark] パスワードリセットのご案内",
      from: "College Spark <collegespark2025@gmail.com>"
    )
  end
end
