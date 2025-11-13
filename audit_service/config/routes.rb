Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get :health_check, to: 'application#health_check'
      
      scope path: 'auditoria', as: 'auditoria' do
        get '/', to: 'audit_log#index'
        post '/', to: 'audit_log#create'
        get '/facturas/:factura_id', to: 'audit_log#show_invoice', as: 'invoice'
        get '/clientes/:cliente_id', to: 'audit_log#show_client', as: 'client'
        get '/:resource_id', to: 'audit_log#show'
      end
    end
  end
end
