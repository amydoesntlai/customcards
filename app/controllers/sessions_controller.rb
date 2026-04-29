class SessionsController < ApplicationController
  def new
    redirect_to root_path if logged_in?
  end

  def create
    username = params[:username].to_s.strip

    user = User.find_by(username: username)

    if user
      sign_in(user)
      redirect_to session.delete(:return_to) || root_path
    else
      user = User.new(username: username)
      if user.save
        sign_in(user)
        redirect_to session.delete(:return_to) || root_path
      else
        @error = user.errors.full_messages.first
        render :new, status: :unprocessable_entity
      end
    end
  end

  def destroy
    cookies.delete(:session_token)
    redirect_to new_session_path, notice: "Signed out."
  end

  private

  def sign_in(user)
    cookies.encrypted.permanent[:session_token] = {
      value: user.session_token,
      httponly: true
    }
  end
end
