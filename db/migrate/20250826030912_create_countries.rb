class CreateCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :countries do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :official_name
      t.string :capital
      t.string :currency_code
      t.string :currency_name
      t.string :currency_symbol
      t.text :languages
      t.bigint :population
      t.string :flag_emoji
      t.text :timezones

      t.timestamps
    end
    
    add_index :countries, :code, unique: true
  end
end
