class DetailedProgram < ApplicationRecord
  belongs_to :condition

  validates :cip_code, presence: true
  validates :program_title, presence: true
  validates :condition_id, uniqueness: { scope: :cip_code }

  # 学位レベルの定数
  CREDENTIAL_LEVELS = {
    1 => "Certificate",
    2 => "Associate Degree",
    3 => "Bachelor's Degree",
    4 => "Master's Degree",
    5 => "Doctoral Degree"
  }.freeze

  # CIPコードから専攻カテゴリーを判定
  def self.determine_category_from_cip(cip_code)
    case cip_code.to_s[0..1]
    when "01" then "Agriculture"
    when "03" then "Natural Resources"
    when "09" then "Communication"
    when "11" then "Computer Science"
    when "13" then "Education"
    when "14" then "Engineering"
    when "16" then "Foreign Languages"
    when "23" then "English Literature"
    when "26" then "Biology"
    when "27" then "Mathematics"
    when "42" then "Psychology"
    when "45" then "Social Sciences"
    when "50" then "Visual Arts"
    when "52" then "Business"
    when "51" then "Health Professions"
    when "54" then "History"
    when "38" then "Philosophy"
    when "40" then "Physical Sciences"
    when "22" then "Legal Studies"
    else "Other"
    end
  end

  # 日本語カテゴリー名を取得
  def category_name_jp
    case major_category
    when "Agriculture" then "農業・農学"
    when "Natural Resources" then "天然資源・環境科学"
    when "Communication" then "コミュニケーション学"
    when "Computer Science" then "コンピューターサイエンス"
    when "Education" then "教育学"
    when "Engineering" then "工学"
    when "Foreign Languages" then "外国語・文学"
    when "English Literature" then "英語・文学"
    when "Biology" then "生物学"
    when "Mathematics" then "数学・統計学"
    when "Psychology" then "心理学"
    when "Social Sciences" then "社会科学"
    when "Visual Arts" then "視覚・舞台芸術"
    when "Business" then "経営学"
    when "Health Professions" then "健康・医療"
    when "History" then "歴史学"
    when "Philosophy" then "哲学・宗教学"
    when "Physical Sciences" then "物理科学"
    when "Legal Studies" then "法学・刑事司法"
    else "その他"
    end
  end

  # 学位レベル名を取得
  def credential_level_name
    CREDENTIAL_LEVELS[credential_level] || "Unknown"
  end

  # 学士レベル以上のプログラムのみ
  scope :bachelor_and_above, -> { where(credential_level: [ 3, 4, 5 ]) }

  # カテゴリー別のスコープ
  scope :by_category, ->(category) { where(major_category: category) }

  # 人気順（卒業者数順）
  scope :popular, -> { order(graduates_count: :desc) }
end
