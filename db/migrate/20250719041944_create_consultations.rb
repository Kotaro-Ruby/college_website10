class CreateConsultations < ActiveRecord::Migration[8.0]
  def change
    create_table :consultations do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.date :preferred_date
      t.string :preferred_time
      t.string :timezone
      t.string :consultation_type
      t.text :message
      t.string :status, default: 'pending'
      t.text :admin_notes

      t.index :email
      t.index :status
      t.index :preferred_date

      t.timestamps
    end
  end
end
