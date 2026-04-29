Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Auth
  resource :session, only: [ :new, :create, :destroy ]

  # Lobby + game rooms
  resources :game_rooms, param: :code, only: [ :new, :create, :show ] do
    member do
      post :join
      post :start
    end
  end

  # Custom cards
  resources :decks, only: [ :index, :new, :create, :show ] do
    resources :cards, only: [ :new, :create ], shallow: true
  end
  resources :cards, only: [] do
    member do
      patch :approve
      patch :reject
    end
  end

  # Game actions (nested under room code for clarity)
  post "game_rooms/:code/rounds",             to: "rounds#create",        as: :game_room_rounds
  post "game_rooms/:code/submissions",        to: "submissions#create",   as: :game_room_submissions
  patch "game_rooms/:code/submissions/:id/pick_winner", to: "submissions#pick_winner", as: :pick_winner

  root "game_rooms#index"
end
