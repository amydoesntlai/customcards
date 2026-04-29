class CreateDecks < ActiveRecord::Migration[8.1]
  def change
    create_table :decks do |t|
      t.string :name, null: false
      t.boolean :public, null: false, default: false
      t.bigint :owner_id

      t.timestamps
    end

    add_index :decks, :owner_id
  end
end
