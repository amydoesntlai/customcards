class CreateGameRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :game_rooms do |t|
      t.string :code, null: false
      t.string :status, null: false, default: "waiting"
      t.integer :rounds_to_win, null: false, default: 5
      t.integer :hand_size, null: false, default: 7
      t.references :owner, null: false, foreign_key: { to_table: :users }
      # active_round_id added after rounds table exists — stored as plain integer to avoid circular FK
      t.bigint :active_round_id

      t.timestamps
    end

    add_index :game_rooms, :code, unique: true
  end
end
