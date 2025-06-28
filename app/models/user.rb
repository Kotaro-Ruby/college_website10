class User < ApplicationRecord
  has_secure_password
  
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 50 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_nil: true
  
  before_save { self.email = email.downcase }
  
  # 比較リスト関連
  
  # お気に入り関連
  has_many :favorites, dependent: :destroy
  has_many :favorite_conditions, through: :favorites, source: :condition
  
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
end
