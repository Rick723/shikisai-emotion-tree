require "rails_helper"

RSpec.describe Emotion, type: :model do
  describe "validations" do
    it "saves a valid emotion" do
      emotion = described_class.new(name: "happy", color_code: "#E6A6B6", display_order: 1)

      expect(emotion.save).to be true
      expect(emotion.reload).to have_attributes(name: "happy", color_code: "#E6A6B6", display_order: 1)
    end

    it "requires name, color_code and display_order" do
      emotion = described_class.new
      emotion.validate

      %i[name color_code display_order].each do |attribute|
        expect(emotion.errors.of_kind?(attribute, :blank)).to be true
      end
    end

    it "accepts lowercase names with underscores between words and up to 30 characters" do
      ["happy", "very_happy", "a" * 30].each do |name|
        expect(build(:emotion, name: name)).to be_valid
      end
    end

    it "rejects invalid name formats and names longer than 30 characters" do
      ["Happy", "happy1", "_happy", "happy_", "very__happy", "very happy", "happy\n", "a" * 31].each do |name|
        emotion = build(:emotion, name: name)
        expect(emotion).to be_invalid
        expect(emotion.errors[:name]).to be_present
      end
    end

    it "rejects duplicate names" do
      existing = create(:emotion)
      emotion = build(:emotion, name: existing.name)

      expect(emotion).to be_invalid
      expect(emotion.errors.of_kind?(:name, :taken)).to be true
    end

    it "accepts six-digit hexadecimal colors in either case" do
      ["#E6A6B6", "#e6a6b6"].each do |color_code|
        expect(build(:emotion, color_code: color_code)).to be_valid
      end
    end

    it "rejects invalid color formats" do
      ["E6A6B6", "#FFF", "#E6A6B60", "#GGGGGG", "#E6A6B6\n"].each do |color_code|
        emotion = build(:emotion, color_code: color_code)
        expect(emotion).to be_invalid
        expect(emotion.errors.of_kind?(:color_code, :invalid)).to be true
      end
    end

    it "rejects display orders below one or without an integer value" do
      [0, -1, 1.5, "abc"].each do |display_order|
        emotion = build(:emotion, display_order: display_order)
        expect(emotion).to be_invalid
        expect(emotion.errors[:display_order]).to be_present
      end
    end

    it "rejects duplicate display orders" do
      existing = create(:emotion)
      emotion = build(:emotion, display_order: existing.display_order)

      expect(emotion).to be_invalid
      expect(emotion.errors.of_kind?(:display_order, :taken)).to be true
    end
  end

  describe "factory" do
    it "builds and saves emotions with distinct names and orders while allowing the same color" do
      expect(build(:emotion)).to be_valid
      emotions = create_list(:emotion, 2)

      expect(emotions).to all(be_persisted)
      expect(emotions.map(&:name).uniq.size).to eq(2)
      expect(emotions.map(&:display_order).uniq.size).to eq(2)
      expect(emotions.map(&:color_code).uniq).to eq(["#E6A6B6"])
    end
  end

  describe "association" do
    it "declares emotion records with restricted deletion" do
      association = described_class.reflect_on_association(:emotion_records)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:restrict_with_error)
    end
  end

  describe "fixed emotion seeds" do
    let(:expected_emotions) do
      [
        ["happy", "#E6A6B6", 1],
        ["fun", "#FFD89A", 2],
        ["relieved", "#E9A76F", 3],
        ["grateful", "#BDE7C5", 4],
        ["sad", "#61749B", 5],
        ["irritated", "#F28C6B", 6],
        ["anxious", "#8585C7", 7],
        ["other", "#D6D3CF", 8]
      ]
    end

    before do
      described_class.delete_all
      Rails.application.load_seed
    end

    it "stores the eight specified names, colors and orders" do
      expect(described_class.order(:display_order).pluck(:name, :color_code, :display_order))
        .to eq(expected_emotions)
    end

    it "does not duplicate or replace records when rerun" do
      original_ids = described_class.order(:display_order).pluck(:id)

      expect { Rails.application.load_seed }.not_to change(described_class, :count)
      expect(described_class.order(:display_order).pluck(:id)).to eq(original_ids)
      expect(described_class.order(:display_order).pluck(:name, :color_code, :display_order))
        .to eq(expected_emotions)
    end

    it "provides the specified Japanese labels through I18n" do
      labels = described_class.order(:display_order).map do |emotion|
        I18n.t("emotions.#{emotion.name}", locale: :ja, raise: true)
      end

      expect(labels).to eq(%w[うれしい たのしい 安心した 感謝 悲しい イライラ 不安 その他])
    end
  end
end
