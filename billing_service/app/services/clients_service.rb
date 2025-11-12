require 'net/http'
require 'json'

class ClientsService
  CLIENTS_SERVICE_URL = ENV.fetch('CLIENTS_SERVICE_URL', 'http://127.0.0.1:3000')

  def self.find_client(client_id)
    uri = URI("#{CLIENTS_SERVICE_URL}/api/v1/clientes/#{client_id}")
    
    begin
      response = Net::HTTP.get_response(uri)
      
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        if data['success']
          data['data']
        else
          nil
        end
      else
        nil
      end
    rescue StandardError => e
      Rails.logger.error("Error al consultar servicio de clientes: #{e.message}")
      nil
    end
  end

  def self.client_exists?(client_id)
    find_client(client_id).present?
  end
end

