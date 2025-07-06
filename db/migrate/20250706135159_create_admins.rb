class CreateAdmins < ActiveRecord::Migration[8.0]
  def change
    create_table :admins do |t|
      t.string :username, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, default: 'admin'
      t.datetime :last_sign_in_at
      t.string :session_token

      t.timestamps
    end
    add_index :admins, :username, unique: true
    add_index :admins, :email, unique: true
    add_index :admins, :session_token
  end
end
