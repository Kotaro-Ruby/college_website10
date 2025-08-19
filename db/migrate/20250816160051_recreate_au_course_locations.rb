class RecreateAuCourseLocations < ActiveRecord::Migration[8.0]
  def change
    # First, remove the broken table completely
    drop_table :au_course_locations, if_exists: true

    # Create the table with proper columns
    create_table :au_course_locations do |t|
      t.integer :au_course_id, null: false
      t.integer :au_location_id, null: false
      t.boolean :active, default: true

      t.timestamps
    end

    # Add foreign keys
    add_foreign_key :au_course_locations, :au_courses
    add_foreign_key :au_course_locations, :au_locations

    # Add indexes
    add_index :au_course_locations, :au_course_id
    add_index :au_course_locations, :au_location_id
    add_index :au_course_locations, [ :au_course_id, :au_location_id ], unique: true, name: 'idx_au_course_location_unique'
  end
end
