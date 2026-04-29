class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.text :content, null: false
      t.string :card_type, null: false
      t.references :deck, null: false, foreign_key: true
      t.bigint :creator_id
      t.string :status, null: false, default: "approved"
      t.integer :pick_count, null: false, default: 1

      t.timestamps
    end

    add_index :cards, :card_type
    add_index :cards, :status
    add_index :cards, :creator_id
  end
end
