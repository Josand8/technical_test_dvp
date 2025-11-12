Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get :health_check, to: 'application#health_check'
      resources :clients, only: [:index, :show, :create], path: 'clientes'
    end
  end
end
