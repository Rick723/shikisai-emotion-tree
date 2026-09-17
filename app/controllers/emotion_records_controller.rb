class EmotionRecordsController < ApplicationController
  before_action :require_login, only: %i[new create]

  def new
    @emotion_record = current_user.emotion_records.new
    prepare_form_context
  end

  def create
    @emotion_record = current_user.emotion_records.new(
      emotion_record_params.merge(felt_on: Date.current)
    )

    if @emotion_record.save
      redirect_to tree_path, status: :see_other
    else
      prepare_form_context
      render :new, status: :unprocessable_content
    end
  end

  private

  def prepare_form_context
    @today = Date.current
    @emotions = Emotion.order(:display_order)
    @existing_emotion_records = current_user.emotion_records
                                            .where(felt_on: @today)
                                            .includes(:emotion)
                                            .order(:id)
                                            .load
  end

  def emotion_record_params
    params.expect(
      emotion_record: %i[
        emotion_id strength afterglow position_x position_y
        felt_at memo
      ]
    )
  end
end
