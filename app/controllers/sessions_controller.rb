class SessionsController < ApplicationController
  rate_limit to: 10,
             within: 3.minutes,
             only: :create,
             by: -> { request.get_header("HTTP_X_REAL_IP").presence || request.remote_ip }

  def new; end

  def create
    credentials = params.expect(session: %i[email password])
    @email = credentials[:email].to_s.downcase
    user = User.find_by(email: @email)

    if user&.authenticate(credentials[:password].to_s)
      start_session(user)
    else
      @authentication_error = "メールアドレスまたはパスワードが正しくありません。"
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    reset_session
    redirect_to root_path, status: :see_other
  end

  private

  def start_session(user)
    reset_session
    session[:user_id] = user.id
    redirect_to tree_path, status: :see_other
  end
end
