class AddSlugToConditions < ActiveRecord::Migration[7.0]
  def change
    add_column :conditions, :slug, :string
    add_index :conditions, :slug, unique: true
  end
end

