class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_user
  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user
  end

  def logged_in?
    current_user.present?
  end

  def set_current_user
    token = cookies.encrypted[:session_token]
    @current_user = User.from_session_token(token) if token
  end

  def require_user
    return if logged_in?
    session[:return_to] = request.fullpath
    redirect_to new_session_path, alert: "Please choose a username to continue."
  end
end
