require "rails_helper"

RSpec.describe "Calendar month and records", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  around do |example|
    # UTC is still August, but the application's current date is September 1.
    travel_to(Time.utc(2026, 8, 31, 16, 0, 0)) { example.run }
  end

  before do
    post login_path, params: { session: { email: user.email, password: user.password } }
  end

  def expect_month(value)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css(".calendar-grid__month time")["datetime"]).to eq(value)
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
      expect(response.parsed_body.at_css(".tree-page__notice").text).to include("感情の色は表示サンプル")
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
    emotion = create(:emotion)
    first = create(:emotion_record, user: user, emotion: emotion, felt_on: "2024-02-01")
    last = create(:emotion_record, user: user, emotion: emotion, felt_on: "2024-02-29")
    create(:emotion_record, user: user, emotion: emotion, felt_on: "2024-01-31")
    create(:emotion_record, user: user, emotion: emotion, felt_on: "2024-03-01")
    create(:emotion_record, emotion: emotion, felt_on: "2024-02-15")

    get calendar_path, params: { month: "2024-02" }

    expect_month("2024-02")
    # ISSUE 29 will consume these records; there is intentionally no record output in the view yet.
    records = controller.view_assigns.fetch("emotion_records")
    expect(records).to be_loaded
    expect(records.map(&:id)).to contain_exactly(first.id, last.id)
    expect(records.all? { |record| record.association(:emotion).loaded? }).to be(true)
    expect(records.map(&:emotion)).to eq([emotion, emotion])
  end

  it "returns no records when only another user has records in the month" do
    create(:emotion_record, felt_on: "2026-09-01")

    get calendar_path

    expect_month("2026-09")
    expect(controller.view_assigns.fetch("emotion_records")).to be_empty
  end
end
