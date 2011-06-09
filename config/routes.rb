Crosswords::Application.routes.draw do
  resources :crosswords, :except => [:edit, :update]

  post 'pusher/auth' => 'home#auth'
  post 'pusher/push' => 'home#push'
  root :to => 'crosswords#index'
end
