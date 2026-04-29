class RoundsController < ApplicationController
  before_action :require_user

  def create
    room = GameRoom.find_by!(code: params[:code].upcase)
    return head :forbidden unless room.players.include?(current_user)
    return head :conflict  unless room.playing?

    StartRoundJob.perform_later(room.id)
    head :ok
  end
end
