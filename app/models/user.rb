class User < ApplicationRecord
  has_many :game_room_players, dependent: :destroy
  has_many :game_rooms, through: :game_room_players
  has_many :owned_rooms, class_name: "GameRoom", foreign_key: :owner_id, dependent: :nullify
  has_many :created_cards, class_name: "Card", foreign_key: :creator_id, dependent: :nullify
  has_many :owned_decks, class_name: "Deck", foreign_key: :owner_id, dependent: :nullify

  before_create :generate_session_token

  validates :username, presence: true,
                       length: { in: 2..20 },
                       format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only letters, numbers, and underscores" }
  validates :session_token, presence: true, uniqueness: true

  def self.from_session_token(token)
    find_by(session_token: token)
  end

  def regenerate_session_token!
    update!(session_token: SecureRandom.urlsafe_base64(24))
  end

  private

  def generate_session_token
    self.session_token = SecureRandom.urlsafe_base64(24)
  end
end
