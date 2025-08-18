class AuLocation < ApplicationRecord
  # 関連
  belongs_to :au_university
  has_many :au_course_locations, dependent: :destroy
  has_many :au_courses, through: :au_course_locations
  
  # バリデーション
  validates :cricos_provider_code, presence: true
  validates :location_name, presence: true
  
  # スコープ
  scope :active, -> { where(active: true) }
  scope :by_state, ->(state) { where(state: state) }
  scope :by_city, ->(city) { where(city: city) }
  scope :main_campus, -> { where("location_type LIKE ?", "%Main%") }
  
  # コールバック
  before_save :build_full_address
  
  # 完全な住所を構築
  def build_full_address
    address_parts = [
      address_line_1,
      address_line_2,
      address_line_3,
      address_line_4,
      city,
      state,
      postcode
    ].compact.reject(&:blank?)
    
    self.full_address = address_parts.join(', ')
  end
  
  # メインキャンパスかどうか
  def main_campus?
    location_type&.downcase&.include?('main') || false
  end
  
  # 州の正式名称
  def state_full_name
    {
      'NSW' => 'New South Wales',
      'VIC' => 'Victoria',
      'QLD' => 'Queensland',
      'WA' => 'Western Australia',
      'SA' => 'South Australia',
      'TAS' => 'Tasmania',
      'ACT' => 'Australian Capital Territory',
      'NT' => 'Northern Territory'
    }[state] || state
  end
end