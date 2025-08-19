class FixAuLocations < ActiveRecord::Migration[8.0]
  def change
    # Drop the existing table
    drop_table :au_locations if table_exists?(:au_locations)
    
    # Recreate with proper structure
    create_table :au_locations do |t|
      t.references :au_university, null: false, foreign_key: true
      t.string :cricos_provider_code, null: false
      t.string :location_name, null: false
      t.string :location_type
      t.string :address_line_1
      t.string :address_line_2
      t.string :address_line_3
      t.string :address_line_4
      t.string :city
      t.string :state
      t.string :postcode
      t.text :full_address
      t.boolean :active, default: true
      
      t.timestamps
    end
    
    # Add indexes
    add_index :au_locations, :cricos_provider_code
    add_index :au_locations, [:au_university_id, :location_name], unique: true, name: 'index_au_locations_on_university_and_name'
  end
end
