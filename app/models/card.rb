class Card < ApplicationRecord
  belongs_to :deck
  belongs_to :creator, class_name: "User", optional: true

  TYPES = %w[prompt response].freeze
  STATUSES = %w[approved pending rejected].freeze

  scope :prompt, -> { where(card_type: "prompt") }
  scope :response, -> { where(card_type: "response") }
  scope :approved, -> { where(status: "approved") }
  scope :pending_review, -> { where(status: "pending") }

  validates :content, presence: true, length: { in: 1..280 }
  validates :card_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :pick_count, inclusion: { in: 1..3 }

  def prompt? = card_type == "prompt"
  def response? = card_type == "response"
  def approved? = status == "approved"
end
