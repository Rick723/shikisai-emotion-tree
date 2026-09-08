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

ActiveRecord::Schema[8.1].define(version: 2026_09_08_000002) do
  create_table "emotion_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "afterglow", null: false
    t.datetime "created_at", null: false
    t.bigint "emotion_id", null: false
    t.time "felt_at"
    t.date "felt_on", null: false
    t.text "memo"
    t.decimal "position_x", precision: 5, scale: 2, null: false
    t.decimal "position_y", precision: 5, scale: 2, null: false
    t.integer "strength", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["emotion_id"], name: "index_emotion_records_on_emotion_id"
    t.index ["user_id", "felt_on"], name: "index_emotion_records_on_user_id_and_felt_on"
    t.check_constraint "`afterglow` between 0 and 100", name: "chk_emotion_records_afterglow_range"
    t.check_constraint "`position_x` between 0.00 and 100.00", name: "chk_emotion_records_position_x_range"
    t.check_constraint "`position_y` between 0.00 and 100.00", name: "chk_emotion_records_position_y_range"
    t.check_constraint "`strength` between 0 and 100", name: "chk_emotion_records_strength_range"
  end

  create_table "emotions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "color_code", limit: 7, null: false
    t.datetime "created_at", null: false
    t.integer "display_order", null: false
    t.string "name", limit: 30, null: false
    t.datetime "updated_at", null: false
    t.index ["display_order"], name: "index_emotions_on_display_order", unique: true
    t.index ["name"], name: "index_emotions_on_name", unique: true
    t.check_constraint "`display_order` >= 1", name: "chk_emotions_display_order_positive"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", limit: 20, null: false
    t.string "password_digest", null: false
    t.datetime "password_reset_expires_at"
    t.string "password_reset_token_digest"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["password_reset_token_digest"], name: "index_users_on_password_reset_token_digest", unique: true
  end

  add_foreign_key "emotion_records", "emotions"
  add_foreign_key "emotion_records", "users", on_delete: :cascade
end
