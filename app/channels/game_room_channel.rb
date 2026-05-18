class GameRoomChannel < ApplicationCable::Channel
  def subscribed
    @room = GameRoom.find_by(code: params[:room_code])
    return reject unless @room

    membership = @room.game_room_players.find_by(user: current_user)
    return reject unless membership

    stream_from @room.broadcast_stream

    membership.mark_seen!
    broadcast_presence("online")

    transmit({ type: "player_count_updated", count: @room.active_players.count })

    if @room.playing? && (round = @room.active_round)
      transmit({
        type: "round_started",
        number: round.number,
        judge: round.judge.username,
        prompt: round.prompt_card.content,
        pick_count: round.prompt_card.pick_count,
        submitted_count: round.submissions.count,
        needed_count: round.non_judge_players.count
      })
    end
  end

  def unsubscribed
    return unless @room

    membership = @room.game_room_players.find_by(user: current_user)
    return unless membership

    membership.update!(status: "disconnected", last_seen_at: Time.current)
    broadcast_presence("offline")
    broadcast_room_update

    HandleDisconnectJob.set(wait: 45.seconds).perform_later(
      game_room_id: @room.id,
      user_id: current_user.id
    )
  end

  private

  def broadcast_room_update
    Turbo::StreamsChannel.broadcast_update_to(
      @room.broadcast_stream,
      target: "lobby-player-count",
      html: "#{@room.active_players.count} player(s) in room"
    )

    Turbo::StreamsChannel.broadcast_update_to(
      @room.broadcast_stream,
      target: "scoreboard",
      partial: "game_rooms/scoreboard",
      locals: { room: @room }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      "room_owner:#{@room.id}",
      target: "start-section",
      partial: "game_rooms/start_section",
      locals: { room: @room }
    )
  end

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
