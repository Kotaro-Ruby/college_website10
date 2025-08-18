class AuCourseLocation < ApplicationRecord
  # 関連
  belongs_to :au_course
  belongs_to :au_location
  
  # バリデーション
  validates :au_course_id, uniqueness: { scope: :au_location_id }
  
  # スコープ
  scope :active, -> { where(active: true) }
end