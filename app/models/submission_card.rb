class SubmissionCard < ApplicationRecord
  belongs_to :submission
  belongs_to :card

  validates :position, numericality: { greater_than_or_equal_to: 0 }
end
