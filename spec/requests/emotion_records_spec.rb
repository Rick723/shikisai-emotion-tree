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
    expect(controller_scope.at_css('input[name="emotion_record[strength]"]')["value"]).to eq("50")
    expect(controller_scope.at_css('output[data-emotion-input-target="strengthValue"]').text).to eq("50")
    expect(controller_scope.at_css('input[name="emotion_record[afterglow]"]')["value"]).to eq("50")
    expect(controller_scope.at_css('output[data-emotion-input-target="afterglowValue"]').text).to eq("50")
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

  it "renders validation errors with 422 and retains the submitted values" do
    emotion = Emotion.order(:display_order).first
    attributes = {
      emotion_id: emotion.id,
      strength: 72,
      afterglow: 64,
      position_x: 38.25,
      position_y: 41.75,
      felt_at: "13:45",
      memo: "あ" * 201
    }

    expect do
      post emotion_records_path, params: { emotion_record: attributes }
    end.not_to change(user.emotion_records, :count)

    expect(response).to have_http_status(422)
    page = response.parsed_body
    form = page.at_css('form[action="/emotion_records"][method="post"]')
    expect(page.at_css("h1").text).to eq("今日を彩る")
    expect(page.at_css('[role="alert"]').text).to include("メモ は200文字以内で入力してください")
    expect(form.at_css("input[name='emotion_record[emotion_id]'][value='#{emotion.id}']")["checked"]).to eq("checked")
    expect(form.at_css('input[name="emotion_record[strength]"]')["value"]).to eq("72")
    expect(form.at_css('output[data-emotion-input-target="strengthValue"]').text).to eq("72")
    expect(form.at_css('input[name="emotion_record[afterglow]"]')["value"]).to eq("64")
    expect(form.at_css('output[data-emotion-input-target="afterglowValue"]').text).to eq("64")
    expect(form.at_css('input[name="emotion_record[position_x]"]')["value"]).to eq("38.25")
    expect(form.at_css('input[name="emotion_record[position_y]"]')["value"]).to eq("41.75")
    expect(form.at_css('input[name="emotion_record[felt_at]"]')["value"]).to start_with("13:45")
    expect(form.at_css('textarea[name="emotion_record[memo]"]').text).to eq(attributes[:memo])
  end

  it "ignores submitted user_id and felt_on values" do
    emotion = Emotion.order(:display_order).first
    other_user = create(:user)

    travel_to Time.zone.local(2026, 9, 10, 14, 0, 0) do
      expect do
        post emotion_records_path, params: {
          emotion_record: {
            emotion_id: emotion.id,
            user_id: other_user.id,
            strength: 50,
            afterglow: 50,
            position_x: 40,
            position_y: 40,
            felt_on: "2020-01-01"
          }
        }
      end.to change(user.emotion_records, :count).by(1)

      record = EmotionRecord.order(:id).last
      expect(record.user).to eq(user)
      expect(record.felt_on).to eq(Date.new(2026, 9, 10))
    end
  end

  it "does not save an invalid emotion_id and re-renders the form without a server error" do
    expect do
      post emotion_records_path, params: {
        emotion_record: {
          emotion_id: 999_999_999,
          strength: 50,
          afterglow: 50,
          position_x: 40,
          position_y: 40
        }
      }
    end.not_to change(user.emotion_records, :count)

    expect(response).to have_http_status(422)
    expect(response.parsed_body.at_css('[role="alert"]').text).to include("感情の種類 を選択してください")
    expect(response.parsed_body.at_css('form[action="/emotion_records"][method="post"]')).to be_present
  end

  it "retains invalid position values without restoring them as a valid preview position" do
    emotion = Emotion.order(:display_order).first

    expect do
      post emotion_records_path, params: {
        emotion_record: {
          emotion_id: emotion.id,
          strength: 50,
          afterglow: 50,
          position_x: "not-a-number",
          position_y: 101
        }
      }
    end.not_to change(user.emotion_records, :count)

    expect(response).to have_http_status(422)
    form = response.parsed_body.at_css('form[action="/emotion_records"][method="post"]')
    expect(form.at_css('input[name="emotion_record[position_x]"]')["value"]).to eq("not-a-number")
    expect(form.at_css('input[name="emotion_record[position_y]"]')["value"]).to eq("101")
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
