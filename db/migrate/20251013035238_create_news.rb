class CreateNews < ActiveRecord::Migration[8.0]
  def change
    create_table :news do |t|
      t.string :title
      t.string :url
      t.text :description
      t.string :image_url
      t.datetime :published_at
      t.string :source
      t.string :country
      t.string :japanese_title
      t.text :japanese_description
      t.integer :status

      t.timestamps
    end
  end
end
