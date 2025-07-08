class Blog < ApplicationRecord
  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true
  validates :author, presence: true
  validates :category, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }

  before_validation :generate_slug, on: :create
  
  scope :published, -> { where.not(published_at: nil).where('published_at <= ?', Time.current) }
  scope :draft, -> { where(published_at: nil) }
  scope :featured, -> { where(featured: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :recent, -> { order(published_at: :desc) }

  CATEGORIES = [
    '留学体験記',
    '大学レビュー',
    '留学準備',
    'ビザ・手続き',
    '現地生活',
    'その他'
  ].freeze
  
  # テンプレート関連
  TEMPLATES = {
    'experience_story' => '体験談テンプレート',
    'university_review' => '大学レビューテンプレート',
    'how_to_guide' => 'ハウツー記事テンプレート',
    'interview' => 'インタビュー記事テンプレート'
  }.freeze

  def published?
    published_at.present? && published_at <= Time.current
  end

  def draft?
    !published?
  end

  private

  def generate_slug
    if title.present? && slug.blank?
      base_slug = title.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
      self.slug = base_slug
      counter = 1
      while Blog.exists?(slug: self.slug)
        self.slug = "#{base_slug}-#{counter}"
        counter += 1
      end
    end
  end
end
