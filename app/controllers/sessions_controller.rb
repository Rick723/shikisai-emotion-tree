class SessionsController < ApplicationController
  def new
  end

  def destroy
    reset_session
    redirect_to root_path, status: :see_other
  end

  def create
    credentials = params.expect(session: [:email, :password])
    @email = credentials[:email].to_s.downcase
    user = User.find_by(email: @email)

    if user&.authenticate(credentials[:password].to_s)
      reset_session
      session[:user_id] = user.id
      redirect_to tree_path, status: :see_other
    else
      @authentication_error = "メールアドレスまたはパスワードが正しくありません。"
      render :new, status: :unprocessable_content
    end
  end
end
