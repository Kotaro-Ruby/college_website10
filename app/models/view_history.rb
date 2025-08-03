class ViewHistory < ApplicationRecord
  belongs_to :user
  belongs_to :condition
  
  validates :user_id, presence: true
  validates :condition_id, presence: true
  
  # デフォルトのスコープ：最新のものから順に
  default_scope { order(viewed_at: :desc) }
  
  # ユーザーごとの最新6件を取得
  scope :recent_for_user, ->(user) { where(user: user).limit(6) }
end
