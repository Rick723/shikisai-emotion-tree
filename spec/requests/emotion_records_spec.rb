require "rails_helper"

RSpec.describe "Emotion input", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  before do
    user = create(:user)
    post login_path, params: { session: { email: user.email, password: user.password } }

    Emotion.delete_all
    Rails.application.load_seed
  end

  it "displays today's date in the application's time zone" do
    travel_to Time.utc(2026, 9, 8, 16, 0, 0) do
      get new_emotion_record_path

      expect(response).to have_http_status(:ok)
      date = response.parsed_body.at_css("time")
      expect(date["datetime"]).to eq("2026-09-09")
      expect(date.text).to eq("2026年9月9日")
    end
  end

  it "displays the eight stored emotions in display order with their translated names and colors" do
    get new_emotion_record_path

    choices = response.parsed_body.css(".emotion-form__choice")
    expect(choices.size).to eq(8)
    Emotion.order(:display_order).zip(choices).each do |emotion, choice|
      expect(choice.at_css('input[type="radio"]')["value"]).to eq(emotion.id.to_s)
      expect(choice.at_css("input")["data-emotion-color"]).to eq(emotion.color_code)
      expect(choice.text.strip).to eq(I18n.t("emotions.#{emotion.name}", raise: true))
      expect(choice.at_css(".tree-legend__swatch")["style"]).to eq("background-color: #{emotion.color_code}")
    end
  end

  it "reflects changes to stored names, colors and display order instead of fixed view values" do
    emotion = Emotion.find_by!(name: "happy")
    other = Emotion.find_by!(name: "other")
    emotion.update!(name: "temporary")
    other.update!(name: "happy")
    emotion.update!(name: "other", color_code: "#123456", display_order: 9)

    get new_emotion_record_path

    choices = response.parsed_body.css(".emotion-form__choice")
    expect(choices.first.at_css("input")["value"]).to eq(Emotion.find_by!(name: "fun").id.to_s)
    expect(choices.last.at_css("input")["value"]).to eq(emotion.id.to_s)
    expect(choices.last.at_css("input")["data-emotion-color"]).to eq("#123456")
    expect(choices.last.at_css(".tree-legend__swatch")["style"]).to eq("background-color: #123456")
    expect(choices.last.text.strip).to eq("その他")
  end
end
