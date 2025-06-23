class AddComparisonListToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :comparison_list, :text
  end
end
