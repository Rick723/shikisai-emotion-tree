class TreesController < ApplicationController
  before_action :require_login, only: :show

  def show
    @today = Date.current
    @emotion_records = current_user.emotion_records
      .where(felt_on: @today)
      .includes(:emotion)
      .order(:id)
      .load
    @emotions = Emotion.order(:display_order)
  end
end
