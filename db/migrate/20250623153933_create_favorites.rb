class CreateFavorites < ActiveRecord::Migration[8.0]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :condition, null: false, foreign_key: true

      t.timestamps
    end

    # 同じユーザーが同じ大学を複数回お気に入りに追加できないようにする
    add_index :favorites, [ :user_id, :condition_id ], unique: true
  end
end
