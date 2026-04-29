class Round < ApplicationRecord
  belongs_to :game_room
  belongs_to :judge, class_name: "User"
  belongs_to :prompt_card, class_name: "Card"
  has_many :submissions, dependent: :destroy

  STATUSES = %w[submitting judging complete].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :number, numericality: { greater_than: 0 }

  scope :complete, -> { where(status: "complete") }

  def non_judge_players
    game_room.active_players.reject { |grp| grp.user_id == judge_id }
  end

  def all_submitted?
    submissions.count >= non_judge_players.count
  end

  def advance_to_judging!
    with_lock do
      return false unless status == "submitting" && all_submitted?
      update!(status: "judging")
    end
    true
  end
end
