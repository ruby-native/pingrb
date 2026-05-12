Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  post "webhooks/:parser_type/:token", to: "webhooks#create", as: :webhook

  resources :sources, only: %i[index show new create update destroy] do
    member { post :rotate }
  end
  resource :registration, only: %i[new create]
  get "privacy", to: "home#privacy", as: :privacy
  root "home#show"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
