class CreateSubmissionCards < ActiveRecord::Migration[8.1]
  def change
    create_table :submission_cards do |t|
      t.references :submission, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.integer :position, null: false

      t.timestamps
    end

    add_index :submission_cards, [ :submission_id, :position ], unique: true
  end
end
