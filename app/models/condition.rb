class Condition < ApplicationRecord
  # 名前で検索するスコープ
  scope :search_by_name, ->(name) { where("name LIKE ?", "%#{name}%") }

  # お気に入り関連
  has_many :favorites, dependent: :destroy
  has_many :favorited_by_users, through: :favorites, source: :user

  # 詳細専攻プログラム関連
  has_many :detailed_programs, dependent: :destroy

  # 多言語翻訳
  has_many :university_translations, dependent: :destroy

  # 日本語名を取得
  def name_ja
    university_translations.find_by(locale: 'ja')&.name
  end

  # 表示用の名前（日本語名があれば「日本語名（英語名）」形式）
  def display_name
    if name_ja.present?
      "#{name_ja}（#{college}）"
    else
      college
    end
  end

  # SEO用タイトル（日本語名があれば優先）
  def seo_title
    name_ja.present? ? "#{name_ja}（#{college}）" : college
  end

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

  # 閲覧数を取得（インスタンス変数またはViewHistoryから取得）
  def view_count
    @view_count || ViewHistory.where(condition_id: id).count
  end
end

# 今は使わない
