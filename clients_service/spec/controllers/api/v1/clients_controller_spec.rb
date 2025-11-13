require 'rails_helper'

RSpec.describe Api::V1::ClientsController, type: :request do
  describe 'GET #index' do
    before do
      Client.delete_all
    end

    let!(:client1) { create(:client, name: 'Juan Pérez', email: 'juanperez@gmail.com', identification: 'ID001') }
    let!(:client2) { create(:client, name: 'María López', email: 'maria@example.com', identification: 'ID002') }

    it 'returns all clients' do
      get '/api/v1/clientes', as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']).to be_an(Array)
      expect(json_response['total_clients']).to eq(2)
    end

    it 'searches clients by name' do
      get '/api/v1/clientes?search=Juan', as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']).not_to be_empty
      expect(json_response['total_clients']).to eq(1)
    end

    it 'searches clients by email' do
      get '/api/v1/clientes?search=juanperez', as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']).not_to be_empty
      expect(json_response['total_clients']).to eq(1)
    end

    it 'returns empty results for non-existent search' do
      get '/api/v1/clientes?search=NoExiste', as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']).to be_empty
      expect(json_response['total_clients']).to eq(0)
    end
  end

  describe 'GET #show' do
    let!(:client) { create(:client) }

    it 'returns client details' do
      get "/api/v1/clientes/#{client.id}", as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['id']).to eq(client.id)
      expect(json_response['data']['name']).to eq(client.name)
    end

    it 'returns not found for non-existent client' do
      get '/api/v1/clientes/99999', as: :json

      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be false
      expect(json_response['message']).to eq('Cliente no encontrado')
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      let(:valid_attributes) do
        {
          client: {
            name: 'Nuevo Cliente',
            identification: '87654321',
            email: 'nuevo@example.com',
            address: 'Calle Nueva 456'
          }
        }
      end

      it 'creates a new client' do
        expect {
          post '/api/v1/clientes', params: valid_attributes, as: :json
        }.to change(Client, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Cliente creado exitosamente')
        expect(json_response['data']['name']).to eq('Nuevo Cliente')
      end
    end

    context 'with invalid attributes' do
      it 'does not create client without name' do
        expect {
          post '/api/v1/clientes', params: {
            client: { email: 'test@example.com' }
          }, as: :json
        }.not_to change(Client, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['errors']).not_to be_nil
      end

      it 'does not create client without email' do
        expect {
          post '/api/v1/clientes', params: {
            client: { name: 'Test Client' }
          }, as: :json
        }.not_to change(Client, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
      end

      it 'does not create client with invalid email format' do
        expect {
          post '/api/v1/clientes', params: {
            client: {
              name: 'Test Client',
              email: 'invalid_email'
            }
          }, as: :json
        }.not_to change(Client, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
      end

      it 'does not create client with duplicate email' do
        existing_client = create(:client, email: 'duplicate@example.com')

        expect {
          post '/api/v1/clientes', params: {
            client: {
              name: 'Duplicate Email Client',
              email: existing_client.email
            }
          }, as: :json
        }.not_to change(Client, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
      end
    end
  end
end

