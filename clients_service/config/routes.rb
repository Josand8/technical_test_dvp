Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get :health_check, to: 'application#check_health'
      resources :clients, only: [:index, :show, :create]
    end
  end
end
