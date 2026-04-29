class CreateSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :submissions do |t|
      t.references :round, null: false, foreign_key: true
      t.bigint :user_id, null: false
      t.boolean :winner, null: false, default: false

      t.timestamps
    end

    add_index :submissions, [ :round_id, :user_id ], unique: true
    add_index :submissions, :user_id
  end
end
