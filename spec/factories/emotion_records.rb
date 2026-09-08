FactoryBot.define do
  factory :emotion_record do
    association :user
    association :emotion
    strength { 50 }
    afterglow { 50 }
    position_x { 50.0 }
    position_y { 50.0 }
    felt_on { Date.current }
    felt_at { nil }
    memo { nil }
  end
end
