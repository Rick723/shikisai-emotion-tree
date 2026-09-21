class SessionsController < ApplicationController
  def new
    return unless request.headers["X-Shikisai-IP-Diagnostic"] == "1"

    response.set_header("X-Shikisai-IP-Diagnostic-Forwarded-For", request.get_header("HTTP_X_FORWARDED_FOR").to_s)
    response.set_header("X-Shikisai-IP-Diagnostic-Real-IP", request.get_header("HTTP_X_REAL_IP").to_s)
    response.set_header("X-Shikisai-IP-Diagnostic-Remote-IP", request.remote_ip)
    response.set_header("X-Shikisai-IP-Diagnostic-Request-ID", request.request_id)
  end

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
