class SubmissionsController < ApplicationController
  before_action :require_user

  def create
    room  = GameRoom.find_by!(code: params[:code].upcase)
    round = room.active_round

    return head :not_found         unless round
    return head :forbidden         unless room.players.include?(current_user)
    return head :forbidden         if round.judge_id == current_user.id
    return head :conflict          unless round.status == "submitting"
    return head :conflict          if round.submissions.exists?(user: current_user)

    card_ids = Array(params[:card_ids]).map(&:to_i).first(round.prompt_card.pick_count)
    return head :unprocessable_entity if card_ids.size != round.prompt_card.pick_count

    grp = room.game_room_players.find_by!(user: current_user)

    # Verify submitted cards are actually in the player's unplayed hand
    valid_ids = grp.player_hands.where(played: false).pluck(:card_id)
    return head :unprocessable_entity unless card_ids.all? { |id| valid_ids.include?(id) }

    ApplicationRecord.transaction do
      submission = round.submissions.create!(user: current_user)
      card_ids.each_with_index do |card_id, idx|
        submission.submission_cards.create!(card_id: card_id, position: idx)
        grp.player_hands.find_by!(card_id: card_id).update!(played: true)
      end
    end

    submitted_count = round.submissions.reload.count
    needed_count    = round.non_judge_players.count

    ActionCable.server.broadcast(room.broadcast_stream, {
      type: "card_submitted",
      submitted_count: submitted_count,
      needed_count: needed_count
    })

    if round.reload.all_submitted?
      round.advance_to_judging!
      broadcast_judging(room, round)
    end

    head :created
  end

  def pick_winner
    room       = GameRoom.find_by!(code: params[:code].upcase)
    round      = room.active_round
    submission = round&.submissions&.find_by(id: params[:id])

    return head :not_found  unless submission
    return head :forbidden  unless round.judge_id == current_user.id
    return head :conflict   unless round.status == "judging"

    submission.mark_winner!

    scores = room.active_players.order(score: :desc).map { |grp|
      { username: grp.user.username, score: grp.score }
    }

    ActionCable.server.broadcast(room.broadcast_stream, {
      type: "round_complete",
      winner: submission.user.username,
      winning_cards: submission.card_texts,
      scores: scores
    })

    Turbo::StreamsChannel.broadcast_replace_to(
      room.broadcast_stream,
      target: "scoreboard",
      partial: "game_rooms/scoreboard",
      locals: { room: room }
    )

    StartRoundJob.set(wait: 6.seconds).perform_later(room.id)
    head :ok
  end

  private

  def broadcast_judging(room, round)
    subs = round.submissions.includes(:cards).to_a.shuffle
    ActionCable.server.broadcast(room.broadcast_stream, {
      type: "judging_started",
      submissions: subs.map { |s|
        { id: s.id, cards: s.cards.order("submission_cards.position").map(&:content) }
      }
    })

    # Update judge's UI with the judging panel
    judge_grp = room.active_players.find { |grp| grp.user_id == round.judge_id }
    return unless judge_grp

    Turbo::StreamsChannel.broadcast_replace_to(
      "player_hand:#{judge_grp.id}",
      target: "hand",
      partial: "game/judging_panel",
      locals: { round: round, submissions: subs, room: room }
    )
  end
end
