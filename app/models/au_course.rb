class AuCourse < ApplicationRecord
  # 関連
  belongs_to :au_university
  has_many :au_course_locations, dependent: :destroy
  has_many :au_locations, through: :au_course_locations

  # バリデーション
  validates :cricos_course_code, presence: true, uniqueness: true
  validates :course_name, presence: true

  # スコープ
  scope :active, -> { where(active: true) }
  scope :bachelor, -> { where("course_level LIKE ?", "%Bachelor%") }
  scope :masters, -> { where("course_level LIKE ?", "%Master%") }
  scope :doctoral, -> { where("course_level LIKE ?", "%Doctor%").or(where("course_level LIKE ?", "%PhD%")) }
  scope :by_field, ->(field) { where(field_of_education_broad: field) }
  scope :ordered_by_tuition, -> { order(annual_tuition_fee: :asc) }
  scope :with_work_component, -> { where(work_component: true) }

  # コールバック
  before_save :calculate_duration_years
  before_save :calculate_annual_tuition

  # 学位レベルのカテゴリー
  def degree_category
    case course_level
    when /Bachelor/i
      "Bachelor"
    when /Master/i
      "Masters"
    when /Doctor|PhD/i
      "Doctoral"
    when /Diploma/i
      "Diploma"
    when /Certificate/i
      "Certificate"
    when /Foundation/i
      "Foundation"
    else
      "Other"
    end
  end

  # 期間を年単位で取得
  def duration_in_years
    return nil unless duration_weeks
    (duration_weeks / 52.0).round(1)
  end

  # フォーマット済み授業料
  def formatted_tuition
    return "N/A" unless tuition_fee
    "$#{tuition_fee.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  # 年間授業料のフォーマット
  def formatted_annual_tuition
    return "N/A" unless annual_tuition_fee
    "$#{annual_tuition_fee.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  # 専攻分野の日本語表記
  def field_of_education_jp
    field_mappings = {
      "Natural and Physical Sciences" => "自然科学・物理科学",
      "Information Technology" => "情報技術",
      "Engineering and Related Technologies" => "工学・関連技術",
      "Architecture and Building" => "建築・建設",
      "Agriculture, Environmental and Related Studies" => "農業・環境学",
      "Health" => "健康・医療",
      "Education" => "教育",
      "Management and Commerce" => "経営・商学",
      "Society and Culture" => "社会・文化",
      "Creative Arts" => "創造芸術",
      "Food, Hospitality and Personal Services" => "食品・ホスピタリティ・サービス"
    }
    field_mappings[field_of_education_broad] || field_of_education_broad
  end

  # 検索メソッド
  def self.search(query)
    return none if query.blank?

    where("course_name LIKE ? OR field_of_education_broad LIKE ?",
          "%#{query}%", "%#{query}%")
  end

  # 主要コースかどうか
  def major_course?
    degree_category.in?([ "Bachelor", "Masters", "Doctoral" ])
  end

  private

  def calculate_duration_years
    self.duration_years = duration_weeks / 52.0 if duration_weeks.present?
  end

  def calculate_annual_tuition
    return unless tuition_fee.present? && duration_years.present? && duration_years > 0
    self.annual_tuition_fee = tuition_fee / duration_years
  end
end
