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

ActiveRecord::Schema[8.0].define(version: 2025_07_08_014500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.string "preferred_language", default: "ar"
    t.string "governorate"
    t.string "city"
    t.date "date_of_birth"
    t.boolean "admin", default: false
    t.index ["admin", "created_at"], name: "index_users_on_admin_and_created_at"
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["date_of_birth"], name: "index_users_on_date_of_birth"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["governorate", "city"], name: "index_users_on_governorate_and_city"
    t.index ["governorate"], name: "index_users_on_governorate"
    t.index ["phone_number"], name: "index_users_on_phone_number"
    t.index ["preferred_language"], name: "index_users_on_preferred_language"
    t.check_constraint "date_of_birth IS NULL OR date_of_birth < CURRENT_DATE", name: "date_of_birth_in_past"
    t.check_constraint "first_name IS NULL OR length(first_name::text) >= 2", name: "first_name_min_length"
    t.check_constraint "last_name IS NULL OR length(last_name::text) >= 2", name: "last_name_min_length"
    t.check_constraint "preferred_language IS NULL OR (preferred_language::text = ANY (ARRAY['ar'::character varying, 'en'::character varying]::text[]))", name: "valid_language"
  end

  add_foreign_key "sessions", "users"
end
