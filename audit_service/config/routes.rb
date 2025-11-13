Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get :health_check, to: 'application#health_check'

      get 'auditoria', to: 'audit_log#index'
      post 'auditoria', to: 'audit_log#create'
      get 'auditoria/:resource_id', to: 'audit_log#show'
    end
  end
end
