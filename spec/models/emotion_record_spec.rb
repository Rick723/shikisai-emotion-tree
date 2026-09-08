require "rails_helper"

RSpec.describe EmotionRecord, type: :model do
  it "saves a valid record with its user and emotion associations" do
    record = build(:emotion_record, position_x: "12.34", position_y: "98.76")

    expect { record.save! }.to change(described_class, :count).by(1)
    expect(record.reload).to have_attributes(position_x: BigDecimal("12.34"), position_y: BigDecimal("98.76"))
    expect(record.user.emotion_records).to include(record)
    expect(record.emotion.emotion_records).to include(record)
  end

  describe "validations" do
    [:user, :emotion, :felt_on].each do |attribute|
      it "requires #{attribute}" do
        record = build(:emotion_record, attribute => nil)

        expect(record).to be_invalid
        expect(record.errors[attribute]).to be_present
      end
    end

    [:strength, :afterglow, :position_x, :position_y].each do |attribute|
      it "accepts the boundaries for #{attribute}" do
        [0, 100].each do |value|
          expect(build(:emotion_record, attribute => value)).to be_valid
        end
      end

      it "rejects missing, nonnumeric and out-of-range #{attribute}" do
        values = [:strength, :afterglow].include?(attribute) ? [nil, "abc", -1, 101] : [nil, "abc", -0.01, 100.01]
        values.each do |value|
          record = build(:emotion_record, attribute => value)

          expect(record).to be_invalid
          expect(record.errors[attribute]).to be_present
        end
      end
    end

    it "requires integer strength and afterglow" do
      [:strength, :afterglow].each do |attribute|
        record = build(:emotion_record, attribute => 50.5)

        expect(record).to be_invalid
        expect(record.errors.of_kind?(attribute, :not_an_integer)).to be true
      end
    end

    it "allows nil felt_at and memo without filling in a time" do
      record = create(:emotion_record, felt_at: nil, memo: nil)

      expect(record.reload).to have_attributes(felt_at: nil, memo: nil)
    end

    it "preserves an explicitly supplied time" do
      record = create(:emotion_record, felt_at: "14:30:00")

      expect(record.reload.felt_at.strftime("%H:%M:%S")).to eq("14:30:00")
    end

    it "allows a 200-character memo and rejects 201 characters" do
      record = create(:emotion_record, memo: "あ" * 200)
      expect(record.reload.memo).to eq("あ" * 200)

      record.memo += "あ"
      expect(record).to be_invalid
      expect(record.errors.of_kind?(:memo, :too_long)).to be true
    end

    it "saves multiple records for the same user, date and emotion" do
      record = create(:emotion_record)

      expect do
        create(:emotion_record, user: record.user, emotion: record.emotion, felt_on: record.felt_on)
      end.to change(described_class, :count).by(1)
    end
  end

  describe "deletion rules" do
    it "destroys a user's records when the user is destroyed" do
      record = create(:emotion_record)

      expect { record.user.destroy! }.to change(described_class, :count).by(-1)
      expect(Emotion.exists?(record.emotion_id)).to be true
    end

    it "prevents destroying an emotion with records" do
      record = create(:emotion_record)
      emotion = record.emotion

      expect(emotion.destroy).to be false
      expect(emotion.errors[:base]).to be_present
      expect(described_class.exists?(record.id)).to be true
      expect(Emotion.exists?(emotion.id)).to be true
    end
  end
end
