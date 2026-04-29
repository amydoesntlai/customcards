class DecksController < ApplicationController
  before_action :require_user

  def index
    @my_decks = current_user.owned_decks.includes(:cards)
    @public_decks = Deck.public_decks.where.not(owner: current_user).includes(:cards)
    @builtin_decks = Deck.builtin.includes(:cards)
  end

  def new
    @deck = Deck.new
  end

  def create
    @deck = current_user.owned_decks.build(deck_params)
    if @deck.save
      redirect_to deck_path(@deck), notice: "Deck created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @deck = Deck.find(params[:id])
    @cards = @deck.cards.order(:card_type, :content)
  end

  private

  def deck_params
    params.expect(deck: [ :name, :public ])
  end
end
