Rails.application.routes.draw do
  resources :events, except: :destroy do
    patch :schedule, on: :member, action: :update_schedule
    patch :complete_follow_up, on: :member
  end
  resources :services
  resources :rooms
  resources :clients, only: %i[index show new create edit update destroy]
  get "monthly_goals", to: "monthly_goals#index", as: :monthly_goals
  patch "monthly_goals", to: "monthly_goals#update_year"
  namespace :admin, path: "configuracoes", as: "admin" do
    resources :users, only: %i[index create], path: "usuarios"
  end
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root path — redireciona para dashboard após login
  root "dashboard#index"
end
