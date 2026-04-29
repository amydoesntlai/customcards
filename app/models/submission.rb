class Submission < ApplicationRecord
  belongs_to :round
  belongs_to :user
  has_many :submission_cards, -> { order(:position) }, dependent: :destroy
  has_many :cards, through: :submission_cards

  validates :winner, inclusion: { in: [ true, false ] }

  def mark_winner!
    round.with_lock do
      raise ActiveRecord::RecordInvalid, "Round not in judging state" unless round.status == "judging"
      raise ActiveRecord::RecordInvalid, "Round already has a winner" if round.submissions.exists?(winner: true)

      transaction do
        update!(winner: true)
        round.update!(status: "complete")
        grp = round.game_room.game_room_players.find_by!(user: user)
        grp.increment!(:score)
      end
    end
  end

  def card_texts
    cards.map(&:content)
  end
end
