Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get :health_check, to: 'application#health_check'
      resources :audit_log, only: [:index, :show, :create], path: 'auditoria'
    end
  end
end
