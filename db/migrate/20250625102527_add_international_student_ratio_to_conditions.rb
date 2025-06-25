class AddInternationalStudentRatioToConditions < ActiveRecord::Migration[8.0]
  def change
    add_column :conditions, :percent_non_resident_alien, :float
  end
end
