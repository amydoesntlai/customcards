class CreatePlayerHands < ActiveRecord::Migration[8.1]
  def change
    create_table :player_hands do |t|
      t.references :game_room_player, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.boolean :played, null: false, default: false

      t.timestamps
    end

    add_index :player_hands, [ :game_room_player_id, :card_id ], unique: true
  end
end
