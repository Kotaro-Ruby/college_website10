class AddMissingColumnsToAuCourses < ActiveRecord::Migration[8.0]
  def change
    # Field of Education 2の追加（セカンド専攻）
    add_column :au_courses, :field_of_education_2_broad, :string
    add_column :au_courses, :field_of_education_2_narrow, :string
    add_column :au_courses, :field_of_education_2_detailed, :string

    # Institution Name（Excel上の大学名）を保存
    add_column :au_courses, :institution_name, :string

    # インデックスの追加
    add_index :au_courses, :field_of_education_2_broad
  end
end
