class CreateViewHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :view_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :condition, null: false, foreign_key: true
      t.datetime :viewed_at

      t.timestamps
    end

    add_index :view_histories, [ :user_id, :viewed_at ]
    add_index :view_histories, [ :user_id, :condition_id ], unique: true
  end
end
