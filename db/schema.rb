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

ActiveRecord::Schema[8.0].define(version: 2025_10_13_035238) do
  create_table "active_storage_tables", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "admins", force: :cascade do |t|
    t.string "username", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "admin"
    t.datetime "last_sign_in_at"
    t.string "session_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["session_token"], name: "index_admins_on_session_token"
    t.index ["username"], name: "index_admins_on_username", unique: true
  end

  create_table "au_course_locations", force: :cascade do |t|
    t.integer "au_course_id", null: false
    t.integer "au_location_id", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["au_course_id", "au_location_id"], name: "idx_au_course_location_unique", unique: true
    t.index ["au_course_id"], name: "index_au_course_locations_on_au_course_id"
    t.index ["au_location_id"], name: "index_au_course_locations_on_au_location_id"
  end

  create_table "au_courses", force: :cascade do |t|
    t.integer "au_university_id", null: false
    t.string "cricos_course_code", null: false
    t.string "course_name", null: false
    t.string "vet_national_code"
    t.string "course_level"
    t.boolean "dual_qualification", default: false
    t.boolean "foundation_studies", default: false
    t.string "field_of_education_broad"
    t.string "field_of_education_narrow"
    t.string "field_of_education_detailed"
    t.integer "duration_weeks"
    t.decimal "duration_years"
    t.boolean "work_component", default: false
    t.decimal "work_component_hours_per_week"
    t.integer "work_component_weeks"
    t.integer "work_component_total_hours"
    t.string "course_language", default: "English"
    t.decimal "tuition_fee"
    t.decimal "non_tuition_fee"
    t.decimal "estimated_total_cost"
    t.decimal "annual_tuition_fee"
    t.boolean "expired", default: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "field_of_education_2_broad"
    t.string "field_of_education_2_narrow"
    t.string "field_of_education_2_detailed"
    t.string "institution_name"
    t.index ["annual_tuition_fee"], name: "index_au_courses_on_annual_tuition_fee"
    t.index ["au_university_id", "active"], name: "index_au_courses_on_au_university_id_and_active"
    t.index ["au_university_id", "course_level"], name: "index_au_courses_on_au_university_id_and_course_level"
    t.index ["au_university_id"], name: "index_au_courses_on_au_university_id"
    t.index ["course_level"], name: "index_au_courses_on_course_level"
    t.index ["cricos_course_code"], name: "index_au_courses_on_cricos_course_code", unique: true
    t.index ["duration_weeks"], name: "index_au_courses_on_duration_weeks"
    t.index ["field_of_education_2_broad"], name: "index_au_courses_on_field_of_education_2_broad"
    t.index ["field_of_education_broad"], name: "index_au_courses_on_field_of_education_broad"
  end

  create_table "au_locations", force: :cascade do |t|
    t.integer "au_university_id", null: false
    t.string "cricos_provider_code", null: false
    t.string "location_name", null: false
    t.string "location_type"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "address_line_3"
    t.string "address_line_4"
    t.string "city"
    t.string "state"
    t.string "postcode"
    t.text "full_address"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["au_university_id", "location_name"], name: "index_au_locations_on_university_and_name", unique: true
    t.index ["au_university_id"], name: "index_au_locations_on_au_university_id"
    t.index ["cricos_provider_code"], name: "index_au_locations_on_cricos_provider_code"
  end

  create_table "au_universities", force: :cascade do |t|
    t.string "name", null: false
    t.string "cricos_provider_code", null: false
    t.string "trading_name"
    t.string "institution_type"
    t.integer "institution_capacity"
    t.string "city"
    t.string "state"
    t.string "postcode"
    t.text "postal_address"
    t.string "website"
    t.integer "total_courses_count", default: 0
    t.integer "bachelor_courses_count", default: 0
    t.integer "masters_courses_count", default: 0
    t.integer "doctoral_courses_count", default: 0
    t.decimal "min_annual_tuition"
    t.decimal "max_annual_tuition"
    t.decimal "avg_annual_tuition"
    t.string "popular_fields"
    t.integer "world_ranking"
    t.integer "domestic_ranking"
    t.string "slug"
    t.text "description"
    t.boolean "active", default: true
    t.json "comprehensive_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "total_students_2023"
    t.integer "total_students_2022"
    t.integer "commencing_students_2023"
    t.integer "commencing_students_2022"
    t.float "student_growth_rate"
    t.integer "overseas_students_2023"
    t.integer "overseas_commencing_2023"
    t.float "overseas_percentage"
    t.text "highlights"
    t.text "famous_alumni"
    t.text "images"
    t.text "image_credits"
    t.index ["active"], name: "index_au_universities_on_active"
    t.index ["avg_annual_tuition"], name: "index_au_universities_on_avg_annual_tuition"
    t.index ["cricos_provider_code"], name: "index_au_universities_on_cricos_provider_code", unique: true
    t.index ["name"], name: "index_au_universities_on_name"
    t.index ["slug"], name: "index_au_universities_on_slug", unique: true
    t.index ["state"], name: "index_au_universities_on_state"
    t.index ["world_ranking"], name: "index_au_universities_on_world_ranking"
  end

  create_table "blogs", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.string "author"
    t.string "category"
    t.datetime "published_at"
    t.boolean "featured"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_blogs_on_category"
    t.index ["featured"], name: "index_blogs_on_featured"
    t.index ["published_at"], name: "index_blogs_on_published_at"
    t.index ["slug"], name: "index_blogs_on_slug", unique: true
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

  create_table "consultations", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.date "preferred_date"
    t.string "preferred_time"
    t.string "timezone"
    t.string "consultation_type"
    t.text "message"
    t.string "status", default: "pending"
    t.text "admin_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "datetime_candidates"
    t.index ["email"], name: "index_consultations_on_email"
    t.index ["preferred_date"], name: "index_consultations_on_preferred_date"
    t.index ["status"], name: "index_consultations_on_status"
  end

  create_table "countries", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.string "official_name"
    t.string "capital"
    t.string "currency_code"
    t.string "currency_name"
    t.string "currency_symbol"
    t.text "languages"
    t.integer "population"
    t.string "flag_emoji"
    t.text "timezones"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "area"
    t.boolean "landlocked"
    t.text "borders"
    t.text "alt_spellings"
    t.string "region"
    t.string "subregion"
    t.boolean "un_member"
    t.boolean "independent"
    t.string "status"
    t.float "gini_coefficient"
    t.integer "gini_year"
    t.text "car_signs"
    t.string "car_side"
    t.string "start_of_week"
    t.string "coat_of_arms_png"
    t.string "coat_of_arms_svg"
    t.string "flag_png"
    t.string "flag_svg"
    t.string "flag_alt"
    t.string "maps_google"
    t.string "maps_openstreetmap"
    t.string "fifa_code"
    t.string "postal_code_format"
    t.string "postal_code_regex"
    t.text "demonyms"
    t.text "translations"
    t.text "tld"
    t.string "idd_root"
    t.text "idd_suffixes"
    t.text "capital_latlng"
    t.text "country_latlng"
  end

  create_table "detailed_programs", force: :cascade do |t|
    t.integer "condition_id", null: false
    t.string "cip_code", null: false
    t.string "program_title", null: false
    t.string "program_title_jp"
    t.integer "credential_level"
    t.string "credential_title"
    t.integer "graduates_count"
    t.string "major_category"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cip_code"], name: "index_detailed_programs_on_cip_code"
    t.index ["condition_id", "cip_code"], name: "index_detailed_programs_on_condition_id_and_cip_code", unique: true
    t.index ["condition_id"], name: "index_detailed_programs_on_condition_id"
    t.index ["credential_level"], name: "index_detailed_programs_on_credential_level"
    t.index ["major_category"], name: "index_detailed_programs_on_major_category"
  end

  create_table "favorites", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "condition_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["condition_id"], name: "index_favorites_on_condition_id"
    t.index ["user_id", "condition_id"], name: "index_favorites_on_user_id_and_condition_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "news", force: :cascade do |t|
    t.string "title"
    t.string "url"
    t.text "description"
    t.string "image_url"
    t.datetime "published_at"
    t.string "source"
    t.string "country"
    t.string "japanese_title"
    t.text "japanese_description"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "image"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  create_table "view_histories", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "condition_id", null: false
    t.datetime "viewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["condition_id"], name: "index_view_histories_on_condition_id"
    t.index ["user_id", "condition_id"], name: "index_view_histories_on_user_id_and_condition_id", unique: true
    t.index ["user_id", "viewed_at"], name: "index_view_histories_on_user_id_and_viewed_at"
    t.index ["user_id"], name: "index_view_histories_on_user_id"
  end

  add_foreign_key "au_course_locations", "au_courses"
  add_foreign_key "au_course_locations", "au_locations"
  add_foreign_key "au_courses", "au_universities"
  add_foreign_key "au_locations", "au_universities"
  add_foreign_key "detailed_programs", "conditions"
  add_foreign_key "favorites", "conditions"
  add_foreign_key "favorites", "users"
  add_foreign_key "view_histories", "conditions"
  add_foreign_key "view_histories", "users"
end
