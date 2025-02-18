class AddCollegeToCondition < ActiveRecord::Migration[8.0]
  def change
    add_column :conditions, :college, :string
  end
end
