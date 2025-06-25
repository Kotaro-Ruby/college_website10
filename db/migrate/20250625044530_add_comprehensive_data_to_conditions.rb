class AddComprehensiveDataToConditions < ActiveRecord::Migration[8.0]
  def change
    # JSON field to store all comprehensive College Scorecard data
    add_column :conditions, :comprehensive_data, :text
    
    # Add commonly used fields directly for faster queries
    add_column :conditions, :sat_math_25, :integer
    add_column :conditions, :sat_math_75, :integer
    add_column :conditions, :sat_reading_25, :integer
    add_column :conditions, :sat_reading_75, :integer
    add_column :conditions, :act_composite_25, :integer
    add_column :conditions, :act_composite_75, :integer
    add_column :conditions, :retention_rate, :float
    add_column :conditions, :earnings_6yr_median, :integer
    add_column :conditions, :earnings_10yr_median, :integer
    add_column :conditions, :pell_grant_rate, :float
    add_column :conditions, :federal_loan_rate, :float
    add_column :conditions, :median_debt, :integer
    add_column :conditions, :net_price_0_30k, :integer
    add_column :conditions, :net_price_30_48k, :integer
    add_column :conditions, :net_price_48_75k, :integer
    add_column :conditions, :net_price_75_110k, :integer
    add_column :conditions, :net_price_110k_plus, :integer
    add_column :conditions, :percent_white, :float
    add_column :conditions, :percent_black, :float
    add_column :conditions, :percent_hispanic, :float
    add_column :conditions, :percent_asian, :float
    add_column :conditions, :percent_men, :float
    add_column :conditions, :percent_women, :float
    add_column :conditions, :faculty_salary, :integer
    add_column :conditions, :room_board_cost, :integer
    add_column :conditions, :tuition_in_state, :integer
    add_column :conditions, :tuition_out_state, :integer
    add_column :conditions, :hbcu, :boolean, default: false
    add_column :conditions, :tribal, :boolean, default: false
    add_column :conditions, :hsi, :boolean, default: false
    add_column :conditions, :women_only, :boolean, default: false
    add_column :conditions, :men_only, :boolean, default: false
    add_column :conditions, :religious_affiliation, :integer
    add_column :conditions, :carnegie_basic, :integer
    add_column :conditions, :locale, :integer
    
    # Indexes for commonly searched fields
    add_index :conditions, :sat_math_25
    add_index :conditions, :sat_math_75
    add_index :conditions, :act_composite_25
    add_index :conditions, :act_composite_75
    add_index :conditions, :earnings_6yr_median
    add_index :conditions, :retention_rate
    add_index :conditions, :hbcu
    add_index :conditions, :tribal
    add_index :conditions, :hsi
  end
end
