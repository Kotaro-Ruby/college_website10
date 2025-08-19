class AddHighlightsToAuUniversities < ActiveRecord::Migration[8.0]
  def change
    add_column :au_universities, :highlights, :text
    add_column :au_universities, :famous_alumni, :text
  end
end
