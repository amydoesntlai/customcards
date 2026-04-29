class Deck < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true
  has_many :cards, dependent: :destroy

  scope :public_decks, -> { where(public: true) }
  scope :builtin, -> { where(owner_id: nil) }

  validates :name, presence: true, length: { in: 1..60 }

  def response_cards = cards.response.approved
  def prompt_cards = cards.prompt.approved
end
