class AddDivisionToCondition < ActiveRecord::Migration[8.0]
  def change
    add_column :conditions, :division, :string
  end
end
