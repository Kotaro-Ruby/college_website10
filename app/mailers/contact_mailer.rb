class ContactMailer < ApplicationMailer
  default from: 'noreply@college-finder.com'

  def contact_form(name, email, category, message)
    @name = name
    @email = email
    @category = category
    @message = message
    
    mail(
      to: 'kotaro.swifty@gmail.com',
      subject: "[College Spark] お問い合わせ: #{@category}",
      reply_to: email
    )
  end
end
