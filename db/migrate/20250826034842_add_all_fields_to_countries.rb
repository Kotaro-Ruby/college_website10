class AddAllFieldsToCountries < ActiveRecord::Migration[8.0]
  def change
    add_column :countries, :area, :float
    add_column :countries, :landlocked, :boolean
    add_column :countries, :borders, :text
    add_column :countries, :alt_spellings, :text
    add_column :countries, :region, :string
    add_column :countries, :subregion, :string
    add_column :countries, :un_member, :boolean
    add_column :countries, :independent, :boolean
    add_column :countries, :status, :string
    add_column :countries, :gini_coefficient, :float
    add_column :countries, :gini_year, :integer
    add_column :countries, :car_signs, :text
    add_column :countries, :car_side, :string
    add_column :countries, :start_of_week, :string
    add_column :countries, :coat_of_arms_png, :string
    add_column :countries, :coat_of_arms_svg, :string
    add_column :countries, :flag_png, :string
    add_column :countries, :flag_svg, :string
    add_column :countries, :flag_alt, :string
    add_column :countries, :maps_google, :string
    add_column :countries, :maps_openstreetmap, :string
    add_column :countries, :fifa_code, :string
    add_column :countries, :postal_code_format, :string
    add_column :countries, :postal_code_regex, :string
    add_column :countries, :demonyms, :text
    add_column :countries, :translations, :text
    add_column :countries, :tld, :text
    add_column :countries, :idd_root, :string
    add_column :countries, :idd_suffixes, :text
    add_column :countries, :capital_latlng, :text
    add_column :countries, :country_latlng, :text
  end
end
