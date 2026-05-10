class GameRoomsController < ApplicationController
  before_action :require_user
  before_action :find_room, only: [ :show, :join, :start ]

  def index
    @my_rooms = current_user.game_rooms.includes(:owner)
                            .order(created_at: :desc).limit(10)
  end

  def new
    @room = GameRoom.new(rounds_to_win: 5, hand_size: 7)
    @decks = available_decks
  end

  def create
    @room = GameRoom.new(room_params)
    @room.owner = current_user

    if @room.save
      @room.game_room_players.create!(user: current_user)
      redirect_to game_room_path(@room.code)
    else
      @decks = available_decks
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @membership = @room.game_room_players.find_by(user: current_user)
    @round = @room.active_round
    @my_grp = @membership
  end

  def join
    if @room.finished?
      return redirect_to root_path, alert: "That game is already over."
    end

    membership = @room.game_room_players.find_or_initialize_by(user: current_user)

    if membership.new_record?
      return redirect_to root_path, alert: "Room is full." if @room.full?
      return redirect_to root_path, alert: "Game already started." unless @room.waiting?
      membership.save!
    else
      membership.mark_seen!
    end

    broadcast_player_list(@room)
    redirect_to game_room_path(@room.code)
  end

  def start
    return head :forbidden unless @room.owner == current_user

    @room.with_lock do
      return redirect_to game_room_path(@room.code), alert: "Need at least 3 players." if @room.active_players.count < 3
      return redirect_to game_room_path(@room.code), alert: "Game already started." unless @room.waiting?

      @room.update!(status: "playing")
    end

    StartRoundJob.perform_now(@room.id)
    redirect_to game_room_path(@room.code)
  end

  private

  def find_room
    @room = GameRoom.find_by!(code: params[:code].to_s.upcase)
  end

  def room_params
    params.expect(game_room: [ :rounds_to_win, :hand_size ])
  end

  def available_decks
    Deck.where(public: true).or(Deck.where(owner: current_user))
  end

  def broadcast_player_list(room)
    Turbo::StreamsChannel.broadcast_update_to(
      room.broadcast_stream,
      target: "player-status",
      partial: "game_rooms/player_list",
      locals: { room: room }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      room.broadcast_stream,
      target: "lobby-player-count",
      html: "#{room.active_players.count} player(s) in room"
    )

    ActionCable.server.broadcast(room.broadcast_stream, {
      type: "player_count_updated",
      count: room.active_players.count
    })
  end
end
