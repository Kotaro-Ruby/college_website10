class Admin < ApplicationRecord
  has_secure_password
  
  # バリデーション
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 30 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :role, inclusion: { in: %w[admin super_admin], message: "無効な権限です" }
  
  # コールバック
  before_save { self.email = email.downcase }
  before_create :generate_session_token
  
  # 権限管理
  def super_admin?
    role == 'super_admin'
  end
  
  def admin?
    role == 'admin' || super_admin?
  end
  
  # セッション管理
  def generate_session_token
    self.session_token = SecureRandom.urlsafe_base64
  end
  
  def regenerate_session_token!
    generate_session_token
    save!
  end
  
  # ログイン時の処理
  def record_sign_in!
    self.last_sign_in_at = Time.current
    regenerate_session_token!
  end
  
  # 管理者の作成（初回セットアップ用）
  def self.create_initial_admin(username, email, password)
    admin = new(
      username: username,
      email: email,
      password: password,
      role: 'super_admin'
    )
    
    if admin.save
      admin
    else
      nil
    end
  end
  
  # 管理者が存在するかチェック
  def self.exists_admin?
    exists?
  end
end
