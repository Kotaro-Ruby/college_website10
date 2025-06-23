class Condition < ApplicationRecord
  # 名前で検索するスコープ
  scope :search_by_name, ->(name) { where('name LIKE ?', "%#{name}%") }
  
  # お気に入り関連
  has_many :favorites, dependent: :destroy
  has_many :favorited_by_users, through: :favorites, source: :user
  
  # お気に入り数を取得
  def favorites_count
    favorites.count
  end
end
  
# 今は使わない 