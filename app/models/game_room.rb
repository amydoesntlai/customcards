class GameRoom < ApplicationRecord
  belongs_to :owner, class_name: "User"
  belongs_to :active_round, class_name: "Round", optional: true
  has_many :game_room_players, dependent: :destroy
  has_many :players, through: :game_room_players, source: :user
  has_many :rounds, dependent: :destroy

  STATUSES = %w[waiting playing finished].freeze

  before_validation :generate_code, on: :create

  validates :code, presence: true, uniqueness: true, length: { is: 6 }
  validates :status, inclusion: { in: STATUSES }
  validates :rounds_to_win, inclusion: { in: 1..20 }
  validates :hand_size, inclusion: { in: 3..10 }

  scope :waiting, -> { where(status: "waiting") }

  def broadcast_stream = "game_room:#{id}"

  def active_players
    game_room_players.where(status: "active").includes(:user)
  end

  def full? = active_players.count >= 10

  def waiting? = status == "waiting"
  def playing? = status == "playing"
  def finished? = status == "finished"

  def next_judge
    active = active_players.order(:created_at).map(&:user)
    last_judge = rounds.order(:number).last&.judge
    idx = last_judge ? ((active.index(last_judge) || -1) + 1) % active.size : 0
    active[idx]
  end

  def winner_player
    return nil unless finished?
    game_room_players.order(score: :desc).first
  end

  private

  def generate_code
    loop do
      self.code = SecureRandom.alphanumeric(6).upcase
      break unless GameRoom.exists?(code: code)
    end
  end
end
