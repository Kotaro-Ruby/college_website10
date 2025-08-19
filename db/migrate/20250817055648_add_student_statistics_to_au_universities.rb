class AddStudentStatisticsToAuUniversities < ActiveRecord::Migration[8.0]
  def change
    add_column :au_universities, :total_students_2023, :integer
    add_column :au_universities, :total_students_2022, :integer
    add_column :au_universities, :commencing_students_2023, :integer
    add_column :au_universities, :commencing_students_2022, :integer
    add_column :au_universities, :student_growth_rate, :float
  end
end
