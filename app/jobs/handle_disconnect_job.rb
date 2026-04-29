class HandleDisconnectJob < ApplicationJob
  queue_as :default

  def perform(game_room_id:, user_id:)
    room = GameRoom.find(game_room_id)
    return unless room.playing?

    grp = room.game_room_players.find_by(user_id: user_id)
    return unless grp&.status == "disconnected"

    round = room.active_round
    return unless round&.status == "submitting"

    if round.judge_id == user_id
      handle_judge_disconnect(room, round)
    else
      handle_player_disconnect(room, round, grp)
    end
  end

  private

  def handle_judge_disconnect(room, round)
    round.update!(status: "complete")
    ActionCable.server.broadcast(room.broadcast_stream, {
      type: "system_message",
      message: "Judge disconnected — rotating to next player."
    })
    StartRoundJob.perform_later(room.id)
  end

  def handle_player_disconnect(room, round, grp)
    return if round.submissions.exists?(user_id: grp.user_id)

    cards = grp.player_hands.where(played: false)
                .order(Arel.sql("RANDOM()"))
                .limit(round.prompt_card.pick_count)
    return if cards.empty?

    submission = round.submissions.create!(user_id: grp.user_id)
    cards.each_with_index do |ph, idx|
      submission.submission_cards.create!(card_id: ph.card_id, position: idx)
      ph.update!(played: true)
    end

    ActionCable.server.broadcast(room.broadcast_stream, {
      type: "card_submitted",
      submitted_count: round.submissions.reload.count,
      needed_count: round.non_judge_players.count
    })

    if round.reload.all_submitted?
      round.advance_to_judging!
      broadcast_judging(room, round)
    end
  end

  def broadcast_judging(room, round)
    subs = round.submissions.includes(:cards).to_a.shuffle
    ActionCable.server.broadcast(room.broadcast_stream, {
      type: "judging_started",
      submissions: subs.map { |s|
        { id: s.id, cards: s.cards.order("submission_cards.position").map(&:content) }
      }
    })

    room.active_players.each do |grp|
      next unless grp.user_id == round.judge_id
      Turbo::StreamsChannel.broadcast_replace_to(
        "player_hand:#{grp.id}",
        target: "hand",
        partial: "game/judging_panel",
        locals: { round: round, submissions: subs, room: room }
      )
    end
  end
end
