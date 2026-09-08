class Emotion < ApplicationRecord
  has_many :emotion_records, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 30 }, uniqueness: true,
                   format: { with: /\A[a-z]+(?:_[a-z]+)*\z/ }
  validates :color_code, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }
  validates :display_order, presence: true, uniqueness: true,
                            numericality: { only_integer: true, greater_than_or_equal_to: 1 }
end
