class Consultation < ApplicationRecord
  # バリデーション
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :preferred_date, presence: true
  validates :preferred_time, presence: true
  validates :timezone, presence: true
  validates :consultation_type, presence: true, inclusion: { in: %w[general university_selection application_support scholarship visa other] }
  validates :message, presence: true
  
  # スコープ
  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :upcoming, -> { where('preferred_date >= ?', Date.today) }
  
  # 相談タイプの日本語表示
  def consultation_type_display
    {
      'general' => '大学留学全般',
      'university_selection' => '大学選び',
      'application_support' => '出願サポート',
      'scholarship' => '奨学金相談',
      'visa' => 'ビザ相談',
      'other' => 'その他'
    }[consultation_type]
  end
  
  # ステータスの日本語表示
  def status_display
    {
      'pending' => '予約確認中',
      'confirmed' => '予約確定',
      'completed' => '相談完了',
      'cancelled' => 'キャンセル'
    }[status]
  end
  
  # 日時候補を取得
  def datetime_candidates_list
    return [] unless datetime_candidates.present?
    
    begin
      JSON.parse(datetime_candidates)
    rescue JSON::ParserError
      []
    end
  end
  
  # 日時候補の表示用文字列
  def datetime_candidates_display
    candidates = datetime_candidates_list
    return "#{preferred_date} #{preferred_time}" if candidates.empty?
    
    candidates.map.with_index(1) do |candidate, index|
      "第#{index}希望: #{candidate['date']} #{candidate['time']}"
    end.join(' / ')
  end
end
