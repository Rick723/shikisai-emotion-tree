require "rails_helper"

RSpec.describe "Emotion input", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  before do
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

  it "renders a form with a non-submitting preview button and a submitting confirmation button" do
    get new_emotion_record_path

    page = response.parsed_body
    controller_scope = page.at_css('[data-controller="emotion-input"]')
    dialog = controller_scope.at_css('dialog#emotion-confirmation[aria-labelledby="emotion-confirmation-title"]')
    confirmation_button = controller_scope.at_css('button[data-action="emotion-input#openConfirmation"]')

    expect(controller_scope["data-emotion-input-today-value"]).to eq(I18n.l(Date.current, format: "%Y年%-m月%-d日"))
    expect(controller_scope.name).to eq("form")
    expect(controller_scope["action"]).to eq(emotion_records_path)
    expect(controller_scope["method"]).to eq("post")
    expect(controller_scope.at_css('textarea[name="emotion_record[memo]"][data-emotion-input-target="memo"]')).to be_present
    expect(controller_scope.at_css('input[name="emotion_record[position_x]"][data-emotion-input-target="positionX"]')).to be_present
    expect(controller_scope.at_css('input[name="emotion_record[position_y]"][data-emotion-input-target="positionY"]')).to be_present
    expect(confirmation_button.text.strip).to eq("この位置で確認する")
    expect(confirmation_button["type"]).to eq("button")
    expect(confirmation_button["disabled"]).to eq("")
    expect(dialog).to be_present
    expect(dialog.at_css('input[type="time"][name="emotion_record[felt_at]"][data-emotion-input-target="feltAt"]')).to be_present
    expect(dialog.at_css('button[type="button"][data-action="emotion-input#back"]')&.text&.strip).to eq("戻る")
    expect(dialog.at_css('button[type="submit"]')&.text&.strip).to eq("この場所に残す")
  end

  it "saves the current user's emotion record for today and redirects to the tree" do
    emotion = Emotion.order(:display_order).first

    travel_to Time.zone.local(2026, 9, 10, 14, 0, 0) do
      expect do
        post emotion_records_path, params: {
          emotion_record: {
            emotion_id: emotion.id,
            strength: 72,
            afterglow: 64,
            position_x: 38.25,
            position_y: 41.75,
            felt_at: "13:45",
            memo: "穏やかな気持ち"
          }
        }
      end.to change(user.emotion_records, :count).by(1)

      expect(response).to redirect_to(tree_path)
      expect(response).to have_http_status(:see_other)

      record = user.emotion_records.order(:id).last
      expect(record).to have_attributes(
        emotion_id: emotion.id,
        strength: 72,
        afterglow: 64,
        position_x: 38.25,
        position_y: 41.75,
        felt_on: Date.new(2026, 9, 10),
        memo: "穏やかな気持ち"
      )
      expect(record.felt_at.strftime("%H:%M")).to eq("13:45")
    end
  end

  it "allows the same user to save multiple emotion records on the same day" do
    emotion = Emotion.order(:display_order).first
    params = {
      emotion_record: {
        emotion_id: emotion.id,
        strength: 50,
        afterglow: 50,
        position_x: 40,
        position_y: 40
      }
    }

    expect do
      2.times { post emotion_records_path, params: params }
    end.to change(user.emotion_records, :count).by(2)

    expect(user.emotion_records.order(:id).last(2).map(&:felt_on)).to all(eq(Date.current))
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
