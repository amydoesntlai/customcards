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

ActiveRecord::Schema[8.1].define(version: 2026_05_09_000001) do
  create_table "cards", force: :cascade do |t|
    t.string "card_type", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.integer "deck_id", null: false
    t.integer "pick_count", default: 1, null: false
    t.string "status", default: "approved", null: false
    t.datetime "updated_at", null: false
    t.index ["card_type"], name: "index_cards_on_card_type"
    t.index ["creator_id"], name: "index_cards_on_creator_id"
    t.index ["deck_id"], name: "index_cards_on_deck_id"
    t.index ["status"], name: "index_cards_on_status"
  end

  create_table "decks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "owner_id"
    t.boolean "public", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_decks_on_owner_id"
  end

  create_table "game_room_players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_room_id", null: false
    t.datetime "last_seen_at"
    t.integer "score", default: 0, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["game_room_id", "user_id"], name: "index_game_room_players_on_game_room_id_and_user_id", unique: true
    t.index ["game_room_id"], name: "index_game_room_players_on_game_room_id"
    t.index ["user_id"], name: "index_game_room_players_on_user_id"
  end

  create_table "game_rooms", force: :cascade do |t|
    t.bigint "active_round_id"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "hand_size", default: 7, null: false
    t.integer "owner_id", null: false
    t.integer "rounds_to_win", default: 5, null: false
    t.string "status", default: "waiting", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_game_rooms_on_code", unique: true
    t.index ["owner_id"], name: "index_game_rooms_on_owner_id"
  end

  create_table "player_hands", force: :cascade do |t|
    t.integer "card_id", null: false
    t.datetime "created_at", null: false
    t.integer "game_room_player_id", null: false
    t.boolean "played", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_player_hands_on_card_id"
    t.index ["game_room_player_id", "card_id"], name: "index_player_hands_on_game_room_player_id_and_card_id", unique: true
    t.index ["game_room_player_id"], name: "index_player_hands_on_game_room_player_id"
  end

  create_table "rounds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_room_id", null: false
    t.bigint "judge_id", null: false
    t.integer "number", null: false
    t.bigint "prompt_card_id", null: false
    t.string "status", default: "submitting", null: false
    t.datetime "updated_at", null: false
    t.index ["game_room_id", "number"], name: "index_rounds_on_game_room_id_and_number", unique: true
    t.index ["game_room_id"], name: "index_rounds_on_game_room_id"
    t.index ["judge_id"], name: "index_rounds_on_judge_id"
    t.index ["prompt_card_id"], name: "index_rounds_on_prompt_card_id"
  end

  create_table "submission_cards", force: :cascade do |t|
    t.integer "card_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.integer "submission_id", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_submission_cards_on_card_id"
    t.index ["submission_id", "position"], name: "index_submission_cards_on_submission_id_and_position", unique: true
    t.index ["submission_id"], name: "index_submission_cards_on_submission_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "round_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "winner", default: false, null: false
    t.index ["round_id", "user_id"], name: "index_submissions_on_round_id_and_user_id", unique: true
    t.index ["round_id"], name: "index_submissions_on_round_id"
    t.index ["user_id"], name: "index_submissions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "session_token", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["session_token"], name: "index_users_on_session_token", unique: true
    t.index ["username"], name: "index_users_on_username"
  end

  add_foreign_key "cards", "decks"
  add_foreign_key "game_room_players", "game_rooms"
  add_foreign_key "game_room_players", "users"
  add_foreign_key "game_rooms", "users", column: "owner_id"
  add_foreign_key "player_hands", "cards"
  add_foreign_key "player_hands", "game_room_players"
  add_foreign_key "rounds", "game_rooms"
  add_foreign_key "submission_cards", "cards"
  add_foreign_key "submission_cards", "submissions"
  add_foreign_key "submissions", "rounds"
end
