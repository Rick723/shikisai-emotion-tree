class CalendarsController < ApplicationController
  before_action :require_login, only: :show

  def show
    @month = display_month
    @emotion_records = current_user.emotion_records
      .where(felt_on: @month..@month.end_of_month)
      .includes(:emotion)
      .load
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
end
