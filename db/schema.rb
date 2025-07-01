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

ActiveRecord::Schema[8.0].define(version: 2025_07_01_033651) do
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
    t.text "comprehensive_data"
    t.integer "sat_math_25"
    t.integer "sat_math_75"
    t.integer "sat_reading_25"
    t.integer "sat_reading_75"
    t.integer "act_composite_25"
    t.integer "act_composite_75"
    t.float "retention_rate"
    t.integer "earnings_6yr_median"
    t.integer "earnings_10yr_median"
    t.float "pell_grant_rate"
    t.float "federal_loan_rate"
    t.integer "median_debt"
    t.integer "net_price_0_30k"
    t.integer "net_price_30_48k"
    t.integer "net_price_48_75k"
    t.integer "net_price_75_110k"
    t.integer "net_price_110k_plus"
    t.float "percent_white"
    t.float "percent_black"
    t.float "percent_hispanic"
    t.float "percent_asian"
    t.float "percent_men"
    t.float "percent_women"
    t.integer "faculty_salary"
    t.integer "room_board_cost"
    t.integer "tuition_in_state"
    t.integer "tuition_out_state"
    t.boolean "hbcu", default: false
    t.boolean "tribal", default: false
    t.boolean "hsi", default: false
    t.boolean "women_only", default: false
    t.boolean "men_only", default: false
    t.integer "religious_affiliation"
    t.integer "carnegie_basic"
    t.integer "locale"
    t.float "percent_non_resident_alien"
    t.index ["act_composite_25"], name: "index_conditions_on_act_composite_25"
    t.index ["act_composite_75"], name: "index_conditions_on_act_composite_75"
    t.index ["earnings_6yr_median"], name: "index_conditions_on_earnings_6yr_median"
    t.index ["hbcu"], name: "index_conditions_on_hbcu"
    t.index ["hsi"], name: "index_conditions_on_hsi"
    t.index ["retention_rate"], name: "index_conditions_on_retention_rate"
    t.index ["sat_math_25"], name: "index_conditions_on_sat_math_25"
    t.index ["sat_math_75"], name: "index_conditions_on_sat_math_75"
    t.index ["slug"], name: "index_conditions_on_slug", unique: true
    t.index ["tribal"], name: "index_conditions_on_tribal"
  end

  create_table "detailed_programs", force: :cascade do |t|
    t.integer "condition_id", null: false
    t.string "cip_code", limit: 255, null: false
    t.string "program_title", limit: 255, null: false
    t.string "program_title_jp", limit: 255
    t.integer "credential_level"
    t.string "credential_title", limit: 255
    t.integer "graduates_count"
    t.string "major_category", limit: 255
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["cip_code"], name: "index_detailed_programs_on_cip_code"
    t.index ["condition_id", "cip_code"], name: "index_detailed_programs_on_condition_id_and_cip_code", unique: true
    t.index ["credential_level"], name: "index_detailed_programs_on_credential_level"
    t.index ["major_category"], name: "index_detailed_programs_on_major_category"
  end

  create_table "favorites", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "condition_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["condition_id"], name: "index_favorites_on_condition_id"
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "survey_responses", force: :cascade do |t|
    t.integer "rating"
    t.string "purpose"
    t.text "feedback"
    t.string "user_ip"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "comparison_list"
    t.string "email"
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token"
  end

  add_foreign_key "detailed_programs", "conditions"
  add_foreign_key "favorites", "conditions"
  add_foreign_key "favorites", "users"
end
