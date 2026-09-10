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
      expect(choice.at_css("input")["data-emotion-name"]).to eq(I18n.t("emotions.#{emotion.name}", raise: true))
      expect(choice.text.strip).to eq(I18n.t("emotions.#{emotion.name}", raise: true))
      expect(choice.at_css(".tree-legend__swatch")["style"]).to eq("background-color: #{emotion.color_code}")
    end
  end

  it "renders a non-submitting confirmation dialog for the current input and placement" do
    get new_emotion_record_path

    page = response.parsed_body
    controller_scope = page.at_css('[data-controller="emotion-input"]')
    dialog = controller_scope.at_css('dialog#emotion-confirmation[aria-labelledby="emotion-confirmation-title"]')
    confirmation_button = controller_scope.at_css('button[data-action="emotion-input#openConfirmation"]')

    expect(controller_scope["data-emotion-input-today-value"]).to eq(I18n.l(Date.current, format: "%Y年%-m月%-d日"))
    expect(controller_scope.at_css('textarea[data-emotion-input-target="memo"]')).to be_present
    expect(confirmation_button.text.strip).to eq("この位置で確認する")
    expect(confirmation_button["type"]).to eq("button")
    expect(confirmation_button["disabled"]).to eq("")
    expect(dialog).to be_present
    expect(dialog.at_css('input[type="time"][data-emotion-input-target="feltAt"]')).to be_present
    expect(dialog.at_css('button[type="button"][data-action="emotion-input#back"]')&.text&.strip).to eq("戻る")
    expect(dialog.at_css('button[type="button"][data-action="emotion-input#confirm"]')&.text&.strip).to eq("この場所に残す")
    expect(controller_scope.css("form, button[type='submit']")).to be_empty
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
