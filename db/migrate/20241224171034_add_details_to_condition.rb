class AddDetailsToCondition < ActiveRecord::Migration[8.0]
  def change
    add_column :conditions, :tuition, :decimal
    add_column :conditions, :students, :integer
    add_column :conditions, :major, :string
    add_column :conditions, :GPA, :decimal
    add_column :conditions, :privateorpublic, :string
  end
end
