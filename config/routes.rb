Crosswords::Application.routes.draw do
  resources :crosswords

  post 'pusher/auth' => 'home#auth'
  post 'pusher/push' => 'home#push'
  root :to => 'home#index'
end
