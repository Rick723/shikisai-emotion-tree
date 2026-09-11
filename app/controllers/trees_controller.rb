class TreesController < ApplicationController
  before_action :require_login, only: :show

  def show
    current_date = Date.current
    @display_date = display_date(current_date)
    @is_today = @display_date == current_date
    @emotion_records = current_user.emotion_records
      .where(felt_on: @display_date)
      .includes(:emotion)
      .order(:id)
      .load
    @emotions = Emotion.order(:display_order)
  end

  private

  def display_date(current_date)
    value = params[:date]
    return current_date unless value.is_a?(String) && /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/.match?(value)

    date = Date.iso8601(value)
    date.year.positive? && date <= current_date ? date : current_date
  rescue Date::Error
    current_date
  end
end
