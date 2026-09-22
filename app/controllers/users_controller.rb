class UsersController < ApplicationController
  rate_limit to: 10,
             within: 10.minutes,
             only: :create,
             by: -> { request.get_header("HTTP_X_REAL_IP").presence || request.remote_ip }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to login_path, status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.expect(user: %i[name email password password_confirmation])
  end
end
