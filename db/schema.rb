# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_06_24_033937) do
  create_table "active_storage_tables", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "conditions", force: :cascade do |t|
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "tuition"
    t.integer "students"
    t.string "major"
    t.decimal "GPA"
    t.string "privateorpublic"
    t.string "college"
    t.string "Division"
    t.float "acceptance_rate"
    t.string "city"
    t.string "address"
    t.string "zip"
    t.string "urbanicity"
    t.string "website"
    t.string "school_type"
    t.float "graduation_rate"
    t.string "slug"
    t.text "comment"
    t.decimal "pcip_agriculture", precision: 5, scale: 4
    t.decimal "pcip_natural_resources", precision: 5, scale: 4
    t.decimal "pcip_communication", precision: 5, scale: 4
    t.decimal "pcip_computer_science", precision: 5, scale: 4
    t.decimal "pcip_education", precision: 5, scale: 4
    t.decimal "pcip_engineering", precision: 5, scale: 4
    t.decimal "pcip_foreign_languages", precision: 5, scale: 4
    t.decimal "pcip_english", precision: 5, scale: 4
    t.decimal "pcip_biology", precision: 5, scale: 4
    t.decimal "pcip_mathematics", precision: 5, scale: 4
    t.decimal "pcip_psychology", precision: 5, scale: 4
    t.decimal "pcip_sociology", precision: 5, scale: 4
    t.decimal "pcip_social_sciences", precision: 5, scale: 4
    t.decimal "pcip_visual_arts", precision: 5, scale: 4
    t.decimal "pcip_business", precision: 5, scale: 4
    t.decimal "pcip_health_professions", precision: 5, scale: 4
    t.decimal "pcip_history", precision: 5, scale: 4
    t.decimal "pcip_philosophy", precision: 5, scale: 4
    t.decimal "pcip_physical_sciences", precision: 5, scale: 4
    t.decimal "pcip_law", precision: 5, scale: 4
    t.index ["slug"], name: "index_conditions_on_slug", unique: true
  end

  create_table "detailed_programs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "favorites", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "condition_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["condition_id"], name: "index_favorites_on_condition_id"
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "comparison_list"
  end

  add_foreign_key "favorites", "conditions"
  add_foreign_key "favorites", "users"
end
