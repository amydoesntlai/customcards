class CardsController < ApplicationController
  before_action :require_user

  def new
    @deck = current_user.owned_decks.find(params[:deck_id])
    @card = @deck.cards.build
  end

  def create
    @deck = current_user.owned_decks.find(params[:deck_id])
    @card = @deck.cards.build(card_params)
    @card.creator = current_user
    @card.status = @deck.public? ? "pending" : "approved"

    if @card.save
      redirect_to deck_path(@deck), notice: "Card added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def approve
    @card = Card.find(params[:id])
    return head :forbidden unless admin?
    @card.update!(status: "approved")
    redirect_back_or_to decks_path, notice: "Card approved."
  end

  def reject
    @card = Card.find(params[:id])
    return head :forbidden unless admin?
    @card.update!(status: "rejected")
    redirect_back_or_to decks_path, notice: "Card rejected."
  end

  private

  def card_params
    params.expect(card: [ :content, :card_type, :pick_count ])
  end

  def admin?
    # Simple admin check: first user, or extend with a boolean column later
    User.order(:id).first == current_user
  end
end
