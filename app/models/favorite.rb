class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :condition

  # バリデーション
  validates :user_id, presence: true
  validates :condition_id, presence: true
  validates :user_id, uniqueness: { scope: :condition_id, message: "この大学は既にお気に入りに追加されています" }
end
