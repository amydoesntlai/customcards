class StartRoundJob < ApplicationJob
  queue_as :default

  def perform(game_room_id)
    room = GameRoom.find(game_room_id)
    return unless room.playing?

    check_win_condition(room) and return if room.rounds.any?

    judge = room.next_judge
    prompt = draw_prompt(room)
    number = (room.rounds.maximum(:number) || 0) + 1

    round = room.rounds.create!(
      judge: judge,
      prompt_card: prompt,
      number: number,
      status: "submitting"
    )
    room.update!(active_round: round)

    deal_cards(room, judge)
    broadcast_round_started(room, round)
    broadcast_hands(room, round)
  end

  private

  def check_win_condition(room)
    winner_grp = room.active_players.order(score: :desc).first
    return false unless winner_grp && winner_grp.score >= room.rounds_to_win

    room.update!(status: "finished")
    ActionCable.server.broadcast(room.broadcast_stream, {
      type: "game_over",
      winner: winner_grp.user.username,
      final_scores: room.active_players.order(score: :desc).map { |grp|
        { username: grp.user.username, score: grp.score }
      }
    })
    true
  end

  def draw_prompt(room)
    used_ids = room.rounds.pluck(:prompt_card_id)
    Card.prompt.approved.where.not(id: used_ids).order(Arel.sql("RANDOM()")).first ||
      Card.prompt.approved.order(Arel.sql("RANDOM()")).first
  end

  def deal_cards(room, judge)
    room.active_players.each do |grp|
      next if grp.user_id == judge.id

      current_count = grp.player_hands.where(played: false).count
      needed = room.hand_size - current_count
      next if needed <= 0

      held_ids = grp.player_hands.pluck(:card_id)
      new_cards = Card.response.approved
                      .where.not(id: held_ids)
                      .order(Arel.sql("RANDOM()"))
                      .limit(needed)

      rows = new_cards.map { |c|
        { game_room_player_id: grp.id, card_id: c.id, played: false,
          created_at: Time.current, updated_at: Time.current }
      }
      PlayerHand.insert_all!(rows) if rows.any?
    end
  end

  def broadcast_round_started(room, round)
    ActionCable.server.broadcast(room.broadcast_stream, {
      type: "round_started",
      number: round.number,
      judge: round.judge.username,
      prompt: round.prompt_card.content,
      pick_count: round.prompt_card.pick_count,
      submitted_count: 0,
      needed_count: round.non_judge_players.count
    })

    Turbo::StreamsChannel.broadcast_replace_to(
      room.broadcast_stream,
      target: "prompt-area",
      partial: "game/prompt_area",
      locals: { round: round }
    )
  end

  def broadcast_hands(room, round)
    room.active_players.each do |grp|
      cards = grp.unplayed_cards
      Turbo::StreamsChannel.broadcast_replace_to(
        "player_hand:#{grp.id}",
        target: "hand",
        partial: "game/hand",
        locals: {
          cards: cards,
          round: round,
          is_judge: grp.user_id == round.judge_id,
          room: room
        }
      )
    end
  end
end
