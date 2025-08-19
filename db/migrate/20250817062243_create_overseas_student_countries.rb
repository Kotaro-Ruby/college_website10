class CreateOverseasStudentCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :overseas_student_countries do |t|
      t.references :au_university, foreign_key: true
      t.string :country
      t.integer :student_count
      t.float :percentage
      t.integer :rank

      t.timestamps
    end
  end
end
