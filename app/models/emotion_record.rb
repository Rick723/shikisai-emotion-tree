class EmotionRecord < ApplicationRecord
  belongs_to :user
  belongs_to :emotion

  validates :strength, :afterglow,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :position_x, :position_y,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :felt_on, presence: true
  validates :memo, length: { maximum: 200 }
end
