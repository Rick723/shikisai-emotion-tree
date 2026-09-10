class EmotionRecordsController < ApplicationController
  before_action :require_login, only: [:new, :create]

  def new
    @emotion_record = current_user.emotion_records.new
    @today = Date.current
    @emotions = Emotion.order(:display_order)
  end

  def create
    @emotion_record = current_user.emotion_records.new(
      emotion_record_params.merge(felt_on: Date.current)
    )

    if @emotion_record.save
      redirect_to tree_path, status: :see_other
    else
      head :unprocessable_entity
    end
  end

  private

  def emotion_record_params
    params.expect(
      emotion_record: [
        :emotion_id,
        :strength,
        :afterglow,
        :position_x,
        :position_y,
        :felt_at,
        :memo
      ]
    )
  end
end
