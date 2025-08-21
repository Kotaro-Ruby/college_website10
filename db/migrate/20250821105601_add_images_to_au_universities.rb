class AddImagesToAuUniversities < ActiveRecord::Migration[8.0]
  def change
    add_column :au_universities, :images, :text
    add_column :au_universities, :image_credits, :text
  end
end
