class AddDivisiontoConditions < ActiveRecord::Migration[8.0]
  def change
    add_column :conditions, :Division, :string
  end
end
