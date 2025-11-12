Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get :health_check, to: 'application#health_check'
      resources :invoices, only: [:index, :show, :create], path: 'facturas'
    end
  end
end
