class AddDatetimeCandidatesToConsultations < ActiveRecord::Migration[8.0]
  def change
    add_column :consultations, :datetime_candidates, :text
  end
end
