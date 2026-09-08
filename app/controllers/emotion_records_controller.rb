class EmotionRecordsController < ApplicationController
  def new
    @today = Date.current
    @emotions = Emotion.order(:display_order)
  end
end
