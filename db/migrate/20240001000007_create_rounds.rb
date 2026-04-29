class CreateRounds < ActiveRecord::Migration[8.1]
  def change
    create_table :rounds do |t|
      t.references :game_room, null: false, foreign_key: true
      t.bigint :judge_id, null: false
      t.bigint :prompt_card_id, null: false
      t.string :status, null: false, default: "submitting"
      t.integer :number, null: false

      t.timestamps
    end

    add_index :rounds, [ :game_room_id, :number ], unique: true
    add_index :rounds, :judge_id
    add_index :rounds, :prompt_card_id
  end
end
