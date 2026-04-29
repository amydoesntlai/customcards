class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :username, null: false
      t.string :session_token, null: false

      t.timestamps
    end

    add_index :users, :session_token, unique: true
    add_index :users, :username
  end
end
