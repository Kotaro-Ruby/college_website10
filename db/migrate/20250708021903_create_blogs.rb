class CreateBlogs < ActiveRecord::Migration[8.0]
  def change
    create_table :blogs do |t|
      t.string :title
      t.text :content
      t.string :author
      t.string :category
      t.datetime :published_at
      t.boolean :featured
      t.string :slug

      t.timestamps
    end

    add_index :blogs, :slug, unique: true
    add_index :blogs, :published_at
    add_index :blogs, :featured
    add_index :blogs, :category
  end
end
