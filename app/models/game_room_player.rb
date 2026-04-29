class GameRoomPlayer < ApplicationRecord
  belongs_to :game_room
  belongs_to :user
  has_many :player_hands, dependent: :destroy
  has_many :hand_cards, through: :player_hands, source: :card

  STATUSES = %w[active disconnected kicked].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :score, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(status: "active") }

  def unplayed_cards
    player_hands.where(played: false).includes(:card).map(&:card)
  end

  def mark_seen!
    update!(last_seen_at: Time.current, status: "active")
  end
end
