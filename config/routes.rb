PolylingoChat::Engine.routes.draw do
  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:index, :create]
  end
end
