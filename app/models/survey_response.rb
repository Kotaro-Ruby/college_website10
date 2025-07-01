class SurveyResponse < ApplicationRecord
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :purpose, inclusion: { in: ['research', 'specific', 'browsing', 'other'] }, allow_blank: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_rating, ->(rating) { where(rating: rating) }
  
  def self.average_rating
    average(:rating).to_f.round(2)
  end
  
  def self.rating_distribution
    group(:rating).count
  end
  
  def purpose_display
    case purpose
    when 'research' then '留学の情報収集'
    when 'specific' then '特定の大学を探している'
    when 'browsing' then 'なんとなく見ている'
    when 'other' then 'その他'
    else '未回答'
    end
  end
end