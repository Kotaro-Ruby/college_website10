class Condition < ApplicationRecord
    # 名前で検索するスコープ
    scope :search_by_name, ->(name) { where('name LIKE ?', "%#{name}%") }
  end
  
# 今は使わない 