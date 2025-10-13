class News < ApplicationRecord
  # ステータス定義
  enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft

  # バリデーション
  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  validates :published_at, presence: true

  # スコープ
  scope :recent, -> { order(published_at: :desc) }
  scope :by_country, ->(country) { where(country: country) if country.present? }

  # デフォルト値
  after_initialize :set_default_status, if: :new_record?

  private

  def set_default_status
    self.status ||= :draft
  end
end
