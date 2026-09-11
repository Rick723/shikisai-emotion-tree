require "rails_helper"

RSpec.describe "Tree", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  around do |example|
    # UTC is still September 9, but the application's current date is September 10.
    travel_to(Time.utc(2026, 9, 9, 16, 0, 0)) { example.run }
  end

  before do
    Rails.application.load_seed
    post login_path, params: { session: { email: user.email, password: user.password } }
  end

  def emotion_named(name)
    Emotion.find_by!(name: name)
  end

  it "displays today's date in the application time zone" do
    get tree_path

    expect(response).to have_http_status(:ok)
    date = response.parsed_body.at_css(".tree-page__date time")
    expect(date["datetime"]).to eq("2026-09-10")
    expect(date.text).to eq("2026年9月10日（木）")
  end

  it "displays a valid past date" do
    get tree_path, params: { date: "2026-09-08" }

    expect(response).to have_http_status(:ok)
    expect(controller.view_assigns.fetch("display_date")).to eq(Date.new(2026, 9, 8))
    date = response.parsed_body.at_css(".tree-page__date time")
    expect(date["datetime"]).to eq("2026-09-08")
    expect(date.text).to eq("2026年9月8日（火）")
  end

  it "fetches only the current user's records for today and preloads their emotions in id order" do
    emotion = emotion_named("happy")
    first = create(:emotion_record, user: user, emotion: emotion, felt_on: Date.current)
    second = create(:emotion_record, user: user, emotion: emotion, felt_on: Date.current)

    get tree_path

    records = controller.view_assigns.fetch("emotion_records")
    expect(records).to be_loaded
    expect(records.map(&:id)).to eq([first.id, second.id])
    expect(records.all? { |record| record.association(:emotion).loaded? }).to be(true)
  end

  it "excludes another user's records" do
    create(:emotion_record, emotion: emotion_named("happy"), felt_on: Date.current)

    get tree_path

    expect(controller.view_assigns.fetch("emotion_records")).to be_empty
    expect(response.parsed_body.css(".tree-visual__color")).to be_empty
  end

  it "excludes the current user's records from other dates" do
    create(:emotion_record, user: user, emotion: emotion_named("happy"), felt_on: Date.current - 1.day)
    create(:emotion_record, user: user, emotion: emotion_named("fun"), felt_on: Date.current + 1.day)

    get tree_path

    expect(controller.view_assigns.fetch("emotion_records")).to be_empty
    expect(response.parsed_body.css(".tree-visual__color")).to be_empty
  end

  it "fetches only the current user's records for the specified past date" do
    emotion = emotion_named("happy")
    expected = create(:emotion_record, user: user, emotion: emotion, felt_on: Date.new(2026, 9, 8))
    create(:emotion_record, user: user, emotion: emotion, felt_on: Date.new(2026, 9, 7))
    create(:emotion_record, emotion: emotion, felt_on: Date.new(2026, 9, 8))

    get tree_path, params: { date: "2026-09-08" }

    records = controller.view_assigns.fetch("emotion_records")
    expect(records.map(&:id)).to eq([expected.id])
    expect(response.parsed_body.css(".tree-visual__color").size).to eq(1)
  end

  it "draws multiple records on one tree" do
    create(:emotion_record, user: user, emotion: emotion_named("happy"), felt_on: Date.current)
    create(:emotion_record, user: user, emotion: emotion_named("sad"), felt_on: Date.current)

    get tree_path

    tree = response.parsed_body.at_css(".tree-visual__layers")
    expect(tree.css(".tree-visual__base").size).to eq(1)
    expect(tree.css(".tree-visual__color").size).to eq(2)
    expect(tree["aria-label"]).to eq("今日の感情を2件重ねた木")
  end

  it "reflects each record's color, position, strength, and afterglow in the drawing" do
    create(
      :emotion_record,
      user: user,
      emotion: emotion_named("grateful"),
      felt_on: Date.current,
      position_x: 38.25,
      position_y: 41.75,
      strength: 72,
      afterglow: 64
    )

    get tree_path

    style = response.parsed_body.at_css(".tree-visual__color")["style"]
    expect(style).to include("--tree-color: #BDE7C5")
    expect(style).to include("--tree-x: 38.25%")
    expect(style).to include("--tree-y: 41.75%")
    expect(style).to include("--tree-radius: 24.4%")
    expect(style).to include("--tree-opacity: 0.712")
  end

  it "shows the base tree, guidance, and input link when today has no records" do
    get tree_path

    page = response.parsed_body
    expect(page.at_css(".tree-visual__base")).to be_present
    expect(page.css(".tree-visual__color")).to be_empty
    expect(page.at_css(".tree-page__notice").text.strip).to eq("今日はまだ感情が記録されていません。")
    link = page.at_css(".tree-visual__empty a")
    expect(link.text.strip).to eq("今日を彩る")
    expect(link["href"]).to eq(new_emotion_record_path)
  end

  it "shows the previous-day link and does not link to the future when displaying today" do
    get tree_path

    navigation = response.parsed_body.at_css(".tree-page__date-navigation")
    previous_link = navigation.at_css("a")
    expect(previous_link.text.strip).to eq("前日")
    expect(previous_link["href"]).to eq(tree_path(date: "2026-09-09"))
    expect(navigation.css("a").size).to eq(1)
    expect(navigation.at_css("[aria-disabled='true']").text.strip).to eq("翌日")
  end

  it "links to the previous and next days when displaying a past date" do
    get tree_path, params: { date: "2026-09-08" }

    links = response.parsed_body.css(".tree-page__date-navigation a")
    expect(links.map { |link| [link.text.strip, link["href"]] }).to eq(
      [
        ["前日", tree_path(date: "2026-09-07")],
        ["翌日", tree_path(date: "2026-09-09")]
      ]
    )
  end

  it "falls back to today when a future date is specified" do
    get tree_path, params: { date: "2026-09-11" }

    expect(response).to have_http_status(:ok)
    expect(controller.view_assigns.fetch("display_date")).to eq(Date.current)
    expect(response.parsed_body.at_css(".tree-page__date time")["datetime"]).to eq("2026-09-10")
  end

  it "falls back to today for an invalid format or nonexistent date" do
    ["2026/09/08", "2026-02-30"].each do |date_parameter|
      get tree_path, params: { date: date_parameter }

      expect(response).to have_http_status(:ok)
      expect(controller.view_assigns.fetch("display_date")).to eq(Date.current)
    end
  end

  it "does not raise an error for an unexpected date parameter type" do
    get tree_path, params: { date: { value: "2026-09-08" } }

    expect(response).to have_http_status(:ok)
    expect(controller.view_assigns.fetch("display_date")).to eq(Date.current)
  end

  it "shows the base tree without an input link when a past date has no records" do
    get tree_path, params: { date: "2026-09-08" }

    page = response.parsed_body
    expect(page.at_css(".tree-visual__base")).to be_present
    expect(page.css(".tree-visual__color")).to be_empty
    expect(page.at_css(".tree-page__notice").text.strip).to eq("この日は感情が記録されていません。")
    expect(page.at_css(".tree-visual__layers")["aria-label"]).to eq("2026年9月8日の感情がまだない淡い緑の基礎木")
    expect(page.at_css(".tree-visual__empty")).to be_nil
  end

  it "displays the stored emotions in display order with their names and colors" do
    get tree_path

    items = response.parsed_body.css(".tree-legend__item")
    expect(items.map { |item| item.text.strip })
      .to eq(%w[うれしい たのしい 安心した 感謝 悲しい イライラ 不安 その他])
    expect(items.map { |item| item.at_css(".tree-legend__swatch")["style"] }).to eq(
      Emotion.order(:display_order).map { |emotion| "background-color: #{emotion.color_code}" }
    )
  end
end
