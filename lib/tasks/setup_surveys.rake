namespace :db do
  desc "Setup surveys table if missing"
  task setup_surveys: :environment do
    unless ActiveRecord::Base.connection.table_exists?('survey_responses')
      puts "Creating survey_responses table..."
      
      ActiveRecord::Schema.define do
        create_table :survey_responses do |t|
          t.integer :rating, null: false
          t.string :purpose
          t.text :comment
          t.string :email
          t.timestamps
        end
        
        add_index :survey_responses, :rating
        add_index :survey_responses, :purpose
        add_index :survey_responses, :created_at
      end
      
      puts "survey_responses table created successfully!"
    else
      puts "survey_responses table already exists."
    end
  end
end