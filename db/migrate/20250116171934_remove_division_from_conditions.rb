class RemoveDivisionFromConditions < ActiveRecord::Migration[8.0]
  def change
    remove_column :conditions, :division
  end
end
