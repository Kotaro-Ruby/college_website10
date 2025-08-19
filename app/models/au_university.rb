class AuUniversity < ApplicationRecord
  # 関連
  has_many :au_courses, dependent: :destroy
  has_many :au_locations, dependent: :destroy

  # バリデーション
  validates :name, presence: true
  validates :cricos_provider_code, presence: true, uniqueness: true
  validates :slug, uniqueness: true, allow_nil: true

  # スコープ
  scope :active, -> { where(active: true) }
  scope :by_state, ->(state) { where(state: state) }
  scope :ordered_by_ranking, -> { order(world_ranking: :asc) }
  scope :ordered_by_name, -> { order(name: :asc) }
  scope :with_bachelor_programs, -> { where("bachelor_courses_count > 0") }

  # コールバック
  before_save :generate_slug
  before_save :format_website

  # 人気分野の取得/設定（カンマ区切り文字列として保存）
  def popular_fields_list
    popular_fields&.split(",")&.map(&:strip) || []
  end

  def popular_fields_list=(fields)
    self.popular_fields = Array(fields).join(", ")
  end

  # 年間授業料のフォーマット済み表示
  def formatted_tuition_range
    return "N/A" unless min_annual_tuition && max_annual_tuition

    min = number_to_currency(min_annual_tuition)
    max = number_to_currency(max_annual_tuition)
    "#{min} - #{max}"
  end

  # 州の正式名称
  def state_full_name
    {
      "NSW" => "New South Wales",
      "VIC" => "Victoria",
      "QLD" => "Queensland",
      "WA" => "Western Australia",
      "SA" => "South Australia",
      "TAS" => "Tasmania",
      "ACT" => "Australian Capital Territory",
      "NT" => "Northern Territory"
    }[state] || state
  end

  # Group of Eight（オーストラリアの名門8大学）判定
  def group_of_eight?
    [
      "The University of Melbourne",
      "The Australian National University",
      "The University of Sydney",
      "The University of Queensland",
      "UNSW",
      "Monash University",
      "The University of Western Australia",
      "The University of Adelaide"
    ].include?(name)
  end

  # 検索用メソッド
  def self.search(query)
    return none if query.blank?

    where("name LIKE ? OR trading_name LIKE ? OR city LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%")
  end

  # コース統計の更新
  def update_course_statistics(courses_data)
    # この処理は後でCoursesテーブルを作成した後に実装
    # 今は仮の実装
    self.total_courses_count = courses_data.size if courses_data
    save
  end

  private

  def generate_slug
    self.slug ||= name.parameterize if name.present?
  end

  def format_website
    return if website.blank?

    # httpやhttpsが付いていない場合は追加
    unless website.match?(/^https?:\/\//)
      self.website = "https://#{website}"
    end
  end

  def number_to_currency(amount)
    return nil unless amount
    "$#{amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
end
