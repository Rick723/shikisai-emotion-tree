class SessionsController < ApplicationController
  def new
    add_ip_diagnostic_headers if request.headers["X-Shikisai-IP-Diagnostic"] == "1"
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

  def add_ip_diagnostic_headers
    headers = {
      "X-Shikisai-IP-Diagnostic-Forwarded-For" => request.get_header("HTTP_X_FORWARDED_FOR").to_s,
      "X-Shikisai-IP-Diagnostic-Real-IP" => request.get_header("HTTP_X_REAL_IP").to_s,
      "X-Shikisai-IP-Diagnostic-Remote-IP" => request.remote_ip,
      "X-Shikisai-IP-Diagnostic-Request-ID" => request.request_id
    }
    headers.each { |name, value| response.set_header(name, value) }
  end

  def start_session(user)
    reset_session
    session[:user_id] = user.id
    redirect_to tree_path, status: :see_other
  end
end
