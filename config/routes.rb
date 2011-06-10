Crosswords::Application.routes.draw do
  resources :crosswords, :except => [:edit, :update]

  post 'pusher/auth' => 'home#auth'
  root :to => 'crosswords#index'
end
