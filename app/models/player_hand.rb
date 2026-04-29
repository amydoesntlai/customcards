class PlayerHand < ApplicationRecord
  belongs_to :game_room_player
  belongs_to :card

  scope :unplayed, -> { where(played: false) }
end
