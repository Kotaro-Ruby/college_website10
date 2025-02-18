class CreateConditions < ActiveRecord::Migration[8.0]
  def change
    create_table :conditions do |t|
      t.string :state

      t.timestamps
    end
  end
end
