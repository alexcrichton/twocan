Crosswords::Application.routes.draw do
  resources :crosswords, :except => [:edit, :update]

  devise_for :users

  match 'auth/:provider/callback' => 'home#omniauth'
  post 'pusher/auth' => 'home#pusher_auth'
  root :to => 'crosswords#index'
end
