class ContactMailer < ApplicationMailer
  default from: 'College Spark <collegespark2025@gmail.com>'

  def contact_form(name, email, category, message)
    @name = name
    @email = email
    @category = category
    @message = message
    
    # カテゴリーを日本語に変換
    category_jp = case category
                  when 'site-bug' then 'サイトの不具合報告'
                  when 'data-error' then 'データの間違い'
                  when 'feature-request' then '新機能のご要望'
                  when 'general-question' then '一般的なご質問'
                  when 'other' then 'その他'
                  else category
                  end
    
    mail(
      to: 'collegespark2025@gmail.com',
      subject: "[College Spark] #{category_jp} - #{name}様より",
      reply_to: "#{name} <#{email}>",
      from: 'College Spark <collegespark2025@gmail.com>'
    )
  end
end
