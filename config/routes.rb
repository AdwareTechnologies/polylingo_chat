PolylingoChat::Engine.routes.draw do
  resources :conversations, only: [:index, :show, :create] do
    member do
      post :mark_all_read
      get :unread_count
    end

    resources :messages, only: [:index, :create] do
      member do
        post :mark_as_read
      end
    end
  end
end
