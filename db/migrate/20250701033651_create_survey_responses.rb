class CreateSurveyResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :survey_responses do |t|
      t.integer :rating
      t.string :purpose
      t.text :feedback
      t.string :user_ip
      t.string :user_agent

      t.timestamps
    end
  end
end
