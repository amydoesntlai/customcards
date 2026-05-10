class FixMultiPickCard < ActiveRecord::Migration[8.0]
  def up
    Card.where(content: "Coming this quarter: ___ vs. ___.", pick_count: 1).update_all(pick_count: 2)
  end

  def down
    Card.where(content: "Coming this quarter: ___ vs. ___.", pick_count: 2).update_all(pick_count: 1)
  end
end
