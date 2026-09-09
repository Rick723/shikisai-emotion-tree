class EmotionRecordsController < ApplicationController
  before_action :require_login, only: :new

  def new
    @today = Date.current
    @emotions = Emotion.order(:display_order)
  end
end
