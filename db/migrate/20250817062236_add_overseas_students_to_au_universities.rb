class AddOverseasStudentsToAuUniversities < ActiveRecord::Migration[8.0]
  def change
    add_column :au_universities, :overseas_students_2023, :integer
    add_column :au_universities, :overseas_commencing_2023, :integer
    add_column :au_universities, :overseas_percentage, :float
  end
end
