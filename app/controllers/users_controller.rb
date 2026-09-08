class UsersController < ApplicationController
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
    params.expect(user: [:name, :email, :password, :password_confirmation])
  end
end
