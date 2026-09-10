require "rails_helper"

RSpec.describe "Calendar month and records", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  around do |example|
    # UTC is still August, but the application's current date is September 1.
    travel_to(Time.utc(2026, 8, 31, 16, 0, 0)) { example.run }
  end

  before do
    Rails.application.load_seed
    post login_path, params: { session: { email: user.email, password: user.password } }
  end

  def expect_month(value)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css(".calendar-grid__month time")["datetime"]).to eq(value)
  end

  def emotion_named(name)
    Emotion.find_by!(name: name)
  end

  def calendar_cell(date)
    response.parsed_body.at_css(".calendar-grid__date[datetime='#{date}']").parent
  end

  def swatch_colors(element)
    element.css(".calendar-grid__swatch").map { |swatch| swatch["style"] }
  end

  it "uses the application's current month when unspecified" do
    get calendar_path

    expect_month("2026-09")
  end

  it "accepts the current month" do
    get calendar_path, params: { month: "2026-09" }

    expect_month("2026-09")
  end

  ["2024-02", "2026-02", "2026-04", "2026-08", "2025-12"].each do |value|
    it "renders all dates and weekday positions for #{value}" do
      get calendar_path, params: { month: value }

      expect_month(value)
      month = Date.iso8601("#{value}-01")
      dates = response.parsed_body.css(".calendar-grid__date")
      expect(dates.map { |date| date["datetime"] }).to eq((month..month.end_of_month).map(&:iso8601))
      expect(dates.map(&:text)).to eq((1..month.end_of_month.day).map(&:to_s))
      rows = response.parsed_body.css(".calendar-grid tbody tr")
      expect(rows.map { |row| row.css("td").size }.uniq).to eq([7])
      cells = rows.flat_map { |row| row.css("td").to_a }
      expect(cells.take(month.wday).all? { |cell| cell["class"] == "calendar-grid__empty" }).to be(true)
      expect(cells[month.wday].at_css("time")["datetime"]).to eq(month.iso8601)
    end
  end

  ["", "invalid", "2026-9", "26-09", "2026-09-01", " 2026-09", "2026-09\n",
   "2026-00", "2026-13", "0000-01", "2026-10", "2027-01", ["2026-08"], { value: "2026-08" }].each do |value|
    it "falls back to the current month for #{value.inspect}" do
      get calendar_path, params: { month: value }

      expect_month("2026-09")
    end
  end

  it "fetches only the user's target-month records with their emotions, including both boundaries" do
    emotion = emotion_named("happy")
    first = create(:emotion_record, user: user, emotion: emotion, felt_on: "2024-02-01")
    last = create(:emotion_record, user: user, emotion: emotion, felt_on: "2024-02-29")
    create(:emotion_record, user: user, emotion: emotion, felt_on: "2024-01-31")
    create(:emotion_record, user: user, emotion: emotion, felt_on: "2024-03-01")
    create(:emotion_record, emotion: emotion, felt_on: "2024-02-15")

    get calendar_path, params: { month: "2024-02" }

    expect_month("2024-02")
    records = controller.view_assigns.fetch("emotion_records")
    expect(records).to be_loaded
    expect(records.map(&:id)).to contain_exactly(first.id, last.id)
    expect(records.all? { |record| record.association(:emotion).loaded? }).to be(true)
    expect(records.map(&:emotion)).to eq([emotion, emotion])
  end

  it "returns no records when only another user has records in the month" do
    create(:emotion_record, emotion: emotion_named("happy"), felt_on: "2026-09-01")

    get calendar_path

    expect_month("2026-09")
    expect(controller.view_assigns.fetch("emotion_records")).to be_empty
  end

  it "shows no cell colors for a day without records and shows all eight legend emotions in display order" do
    get calendar_path

    colors = calendar_cell("2026-09-01").at_css(".calendar-grid__colors")
    expect(colors["aria-label"]).to eq("感情の色なし")
    expect(colors.css(".calendar-grid__swatch")).to be_empty

    legend = response.parsed_body.at_css(".calendar-legend")
    expect(legend["aria-label"]).to eq("感情の色")
    expect(legend.css(".calendar-legend__item").map { |item| item.text.strip })
      .to eq(%w[うれしい たのしい 安心した 感謝 悲しい イライラ 不安 その他])
    expect(legend.css(".tree-legend__swatch").map { |swatch| swatch["style"] }).to eq(
      Emotion.order(:display_order).map { |emotion| "background-color: #{emotion.color_code}" }
    )
  end

  it "deduplicates an emotion using its maximum strength and shows only the top three emotions" do
    felt_on = Date.new(2026, 9, 5)
    create(:emotion_record, user: user, emotion: emotion_named("happy"), strength: 30, felt_on: felt_on)
    create(:emotion_record, user: user, emotion: emotion_named("happy"), strength: 80, felt_on: felt_on)
    create(:emotion_record, user: user, emotion: emotion_named("other"), strength: 70, felt_on: felt_on)
    create(:emotion_record, user: user, emotion: emotion_named("anxious"), strength: 60, felt_on: felt_on)
    create(:emotion_record, user: user, emotion: emotion_named("irritated"), strength: 50, felt_on: felt_on)

    get calendar_path

    colors = calendar_cell("2026-09-05").at_css(".calendar-grid__colors")
    expect(colors["aria-label"]).to eq("うれしい、その他、不安")
    expect(swatch_colors(colors)).to eq([
      "background-color: #E6A6B6",
      "background-color: #D6D3CF",
      "background-color: #8585C7"
    ])
    expect(colors.css(".calendar-grid__swatch").size).to eq(3)
    expect(swatch_colors(colors)).not_to include("background-color: #F28C6B")
  end

  it "orders equal-strength emotions by display order" do
    felt_on = Date.new(2026, 9, 12)
    create(:emotion_record, user: user, emotion: emotion_named("sad"), strength: 60, felt_on: felt_on)
    create(:emotion_record, user: user, emotion: emotion_named("grateful"), strength: 60, felt_on: felt_on)
    create(:emotion_record, user: user, emotion: emotion_named("happy"), strength: 60, felt_on: felt_on)

    get calendar_path

    colors = calendar_cell("2026-09-12").at_css(".calendar-grid__colors")
    expect(colors["aria-label"]).to eq("うれしい、感謝、悲しい")
    expect(swatch_colors(colors)).to eq([
      "background-color: #E6A6B6",
      "background-color: #BDE7C5",
      "background-color: #61749B"
    ])
  end

  it "keeps records from different dates in their own cells and uses emotion labels and colors" do
    create(:emotion_record, user: user, emotion: emotion_named("fun"), felt_on: "2026-09-19")
    create(:emotion_record, user: user, emotion: emotion_named("sad"), felt_on: "2026-09-20")

    get calendar_path

    first_colors = calendar_cell("2026-09-19").at_css(".calendar-grid__colors")
    second_colors = calendar_cell("2026-09-20").at_css(".calendar-grid__colors")
    expect(first_colors["aria-label"]).to eq("たのしい")
    expect(swatch_colors(first_colors)).to eq(["background-color: #FFD89A"])
    expect(second_colors["aria-label"]).to eq("悲しい")
    expect(swatch_colors(second_colors)).to eq(["background-color: #61749B"])
  end
end
