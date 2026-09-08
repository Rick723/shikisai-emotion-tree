FactoryBot.define do
  factory :emotion do
    # Synthetic test data, separate from the fixed eight-emotion seed.
    sequence(:name, "emotion_a")
    color_code { "#E6A6B6" }
    sequence(:display_order) { |n| 100 + n }
  end
end
