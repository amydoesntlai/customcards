class GameRoomChannel < ApplicationCable::Channel
  def subscribed
    @room = GameRoom.find_by(code: params[:room_code])
    return reject unless @room

    membership = @room.game_room_players.find_by(user: current_user)
    return reject unless membership

    stream_from @room.broadcast_stream

    membership.mark_seen!
    broadcast_presence("online")
  end

  def unsubscribed
    return unless @room

    membership = @room.game_room_players.find_by(user: current_user)
    return unless membership

    membership.update!(status: "disconnected", last_seen_at: Time.current)
    broadcast_presence("offline")

    HandleDisconnectJob.set(wait: 45.seconds).perform_later(
      game_room_id: @room.id,
      user_id: current_user.id
    )
  end

  private

  def broadcast_presence(state)
    ActionCable.server.broadcast(@room.broadcast_stream, {
      type: "presence",
      username: current_user.username,
      state: state,
      players: player_list
    })
  end

  def player_list
    @room.active_players.map { |grp|
      { username: grp.user.username, score: grp.score, online: grp.status == "active" }
    }
  end
end
