class Condition < ApplicationRecord
  # 名前で検索するスコープ
  scope :search_by_name, ->(name) { where('name LIKE ?', "%#{name}%") }
  
  # お気に入り関連
  has_many :favorites, dependent: :destroy
  has_many :favorited_by_users, through: :favorites, source: :user
  
  # 詳細専攻プログラム関連
  has_many :detailed_programs, dependent: :destroy
  
  # お気に入り数を取得
  def favorites_count
    favorites.count
  end
  
  # 学士レベル以上の専攻プログラムを取得
  def bachelor_programs
    detailed_programs.bachelor_and_above
  end
  
  # カテゴリー別の専攻プログラム数を取得
  def programs_by_category
    detailed_programs.bachelor_and_above.group(:major_category).count
  end
end
  
# 今は使わない 