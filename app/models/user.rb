class User < ApplicationRecord
  has_secure_password validations: false

  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 50 }, unless: :oauth_user?
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_nil: true, unless: :oauth_user?

  before_save { self.email = email.downcase }

  # 比較リスト関連

  # お気に入り関連
  has_many :favorites, dependent: :destroy
  has_many :favorite_conditions, through: :favorites, source: :condition

  # 閲覧履歴関連
  has_many :view_histories, dependent: :destroy
  has_many :viewed_conditions, through: :view_histories, source: :condition

  # お気に入りに追加済みかチェック
  def favorite?(condition)
    favorites.exists?(condition: condition)
  end

  # 比較リストの初期化
  def comparison_list
    if read_attribute(:comparison_list).present?
      JSON.parse(read_attribute(:comparison_list))
    else
      []
    end
  rescue JSON::ParserError
    []
  end

  # 比較リストの保存
  def comparison_list=(value)
    write_attribute(:comparison_list, value.to_json)
  end

  # パスワードリセット機能
  def create_password_reset_token
    self.password_reset_token = SecureRandom.urlsafe_base64
    self.password_reset_sent_at = Time.current
    save!

    Rails.logger.info "Password reset token created for user: #{email}"
    Rails.logger.info "Token: #{self.password_reset_token}"
    Rails.logger.info "Sent at: #{self.password_reset_sent_at}"
  end

  # パスワードリセットトークンの有効性チェック（2時間以内）
  def password_reset_expired?
    password_reset_sent_at < 2.hours.ago
  end

  # パスワードリセット後のクリア
  def clear_password_reset
    self.password_reset_token = nil
    self.password_reset_sent_at = nil
    save!
  end

  # OAuth認証用メソッド
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.image = auth.info.image
      user.username = generate_unique_username(auth.info.name || auth.info.email)
      user.password = SecureRandom.hex(16) # OAuth認証の場合はランダムパスワードを設定
    end
  end

  def oauth_user?
    provider.present? && uid.present?
  end

  private

  def self.generate_unique_username(base_name)
    username = base_name.gsub(/[^a-zA-Z0-9_]/, '_').slice(0, 40)
    counter = 1
    
    while User.exists?(username: username)
      username = "#{base_name.gsub(/[^a-zA-Z0-9_]/, '_').slice(0, 40)}_#{counter}"
      counter += 1
    end
    
    username
  end
end
