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
  
  # SAT平均スコアを計算
  def sat_average
    return nil unless sat_math_25.present? && sat_reading_25.present? && sat_math_75.present? && sat_reading_75.present?
    (sat_math_25 + sat_reading_25 + sat_math_75 + sat_reading_75) / 4.0
  end
  
  # SAT範囲を表示用に取得
  def sat_range_display
    return "N/A" unless sat_math_25.present? && sat_reading_25.present? && sat_math_75.present? && sat_reading_75.present?
    min_total = sat_math_25 + sat_reading_25
    max_total = sat_math_75 + sat_reading_75
    "#{min_total}-#{max_total}"
  end
end
  
# 今は使わない 