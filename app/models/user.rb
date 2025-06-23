class User < ApplicationRecord
  has_secure_password
  
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 50 }
  validates :password, length: { minimum: 6 }, allow_nil: true
  
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
end
