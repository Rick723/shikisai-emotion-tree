class CalendarsController < ApplicationController
  before_action :require_login, only: :show

  def show
    @month = display_month
    @emotion_records = current_user.emotion_records
      .where(felt_on: @month..@month.end_of_month)
      .includes(:emotion)
      .load
    @daily_emotions = daily_emotions(@emotion_records)
    @emotions = Emotion.order(:display_order)
  end

  private

  def display_month
    current_month = Date.current.beginning_of_month
    value = params[:month]
    return current_month unless value.is_a?(String) && /\A[0-9]{4}-[0-9]{2}\z/.match?(value)

    month = Date.iso8601("#{value}-01")
    month.year.positive? && month <= current_month ? month : current_month
  rescue Date::Error
    current_month
  end

  def daily_emotions(records)
    records.group_by(&:felt_on).transform_values do |daily_records|
      daily_records
        .group_by(&:emotion_id)
        .values
        .map { |emotion_records| emotion_records.max_by(&:strength) }
        .sort_by { |record| [-record.strength, record.emotion.display_order] }
        .first(3)
        .map(&:emotion)
    end
  end
end
