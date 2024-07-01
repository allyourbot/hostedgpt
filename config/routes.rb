Rails.application.routes.draw do
  root to: "assistants#index"

  resources :users, only: [:new, :create, :update]

  resources :assistants do
    resources :messages, only: [:new, :create, :edit]
  end

  resources :conversations, only: [:show, :edit, :update, :destroy] do
    resources :messages, only: [:index]
  end

  resources :messages, only: [:show, :update]

  namespace :settings do
    resources :assistants, except: [:index, :show]
    resource :person, only: [:edit, :update]
    resources :language_models
    resources :api_services, except: [:show]
    resources :memories, only: [:index] do
      delete :destroy, on: :collection
    end
  end

  post "whatsapp/create" => "whatsapp#create"

  get "/login", to: "authentications#new"
  post "/login", to: "authentications#create"
  get "/register", to: "users#new"
  get "/logout", to: "authentications#destroy"

  get "/auth/:provider/callback" => "authentications/google_oauth#create", as: :google_oauth
  get "/auth/failure" => "authentications/google_oauth#failure" # connected in omniauth.rb

  # resources :documents  TODO: finish this feature

  get "/rails/active_storage/postgresql/:encoded_key/*filename" => "active_storage/postgresql#show", as: :rails_postgresql_service
  put "/rails/active_storage/postgresql/:encoded_token" => "active_storage/postgresql#update", as: :update_rails_postgresql_service

  get "up" => "rails/health#show", as: :rails_health_check
end
