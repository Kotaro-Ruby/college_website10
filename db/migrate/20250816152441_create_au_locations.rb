class CreateAuLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :au_locations do |t|
      # 外部キー
      t.references :au_university, null: false, foreign_key: true

      # ロケーション情報
      t.string :cricos_provider_code, null: false
      t.string :institution_name
      t.string :location_name, null: false
      t.string :location_type

      # 住所情報
      t.string :address_line_1
      t.string :address_line_2
      t.string :address_line_3
      t.string :address_line_4
      t.string :city
      t.string :state
      t.string :postcode
      t.text :full_address  # 結合した完全な住所

      # メタ情報
      t.boolean :active, default: true

      t.timestamps
    end

    # インデックスの追加
    add_index :au_locations, :cricos_provider_code
    add_index :au_locations, :location_name
    add_index :au_locations, :city
    add_index :au_locations, :state
    add_index :au_locations, [ :au_university_id, :location_name ]
  end
end
