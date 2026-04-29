module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = cookies.encrypted[:session_token]
      User.from_session_token(token) || reject_unauthorized_connection
    end
  end
end
