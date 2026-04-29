class CreateGameRoomPlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :game_room_players do |t|
      t.references :game_room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.integer :score, null: false, default: 0
      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :game_room_players, [ :game_room_id, :user_id ], unique: true
  end
end
