class AddDetailsToConditions < ActiveRecord::Migration[8.0]
  def change
    add_column :conditions, :city, :string
    add_column :conditions, :address, :string
    add_column :conditions, :zip, :string
    add_column :conditions, :urbanicity, :string
    add_column :conditions, :website, :string
    add_column :conditions, :school_type, :string
    add_column :conditions, :graduation_rate, :float
  end
end
