class Country < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  
  serialize :languages, coder: JSON
  serialize :timezones, coder: JSON
  serialize :borders, coder: JSON
  serialize :alt_spellings, coder: JSON
  serialize :car_signs, coder: JSON
  serialize :demonyms, coder: JSON
  serialize :translations, coder: JSON
  serialize :tld, coder: JSON
  serialize :idd_suffixes, coder: JSON
  serialize :capital_latlng, coder: JSON
  serialize :country_latlng, coder: JSON
  
  def main_language
    languages&.values&.first
  end
  
  def timezone_range
    return "" if timezones.blank?
    
    if timezones.size == 1
      timezones.first
    else
      "#{timezones.first} to #{timezones.last}"
    end
  end
  
  def area_formatted
    return "N/A" if area.blank?
    "#{number_with_delimiter(area.to_i)} km²"
  end
  
  def neighboring_countries
    borders || []
  end
end
