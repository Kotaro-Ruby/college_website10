class AddAcceptanceRateToConditions < ActiveRecord::Migration[8.0]
  def change
    add_column :conditions, :acceptance_rate, :float
  end
end
