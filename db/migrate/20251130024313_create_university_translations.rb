class CreateUniversityTranslations < ActiveRecord::Migration[8.0]
  def change
    create_table :university_translations do |t|
      t.references :condition, null: false, foreign_key: true
      t.string :locale, null: false
      t.string :name, null: false

      t.timestamps
    end

    # 同じ大学に同じlocaleは1つだけ
    add_index :university_translations, [:condition_id, :locale], unique: true
  end
end
