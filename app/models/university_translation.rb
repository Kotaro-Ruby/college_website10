class UniversityTranslation < ApplicationRecord
  belongs_to :condition

  validates :locale, presence: true
  validates :name, presence: true
  validates :locale, uniqueness: { scope: :condition_id }
end
