require 'rails_helper'

RSpec.describe Api::V1::InvoicesController, type: :request do
  let(:client_data) do
    {
      'id' => 1,
      'name' => 'Cliente Test',
      'email' => 'test@example.com',
      'identification' => '12345678',
      'address' => 'Dirección Test'
    }
  end

  before do
    allow(ClientsService).to receive(:client_exists?).and_return(true)
    allow(ClientsService).to receive(:find_client).and_return(client_data)
    allow(AuditService).to receive(:log_read)
    allow(AuditService).to receive(:log_create)
    allow(AuditService).to receive(:log_error)
  end

  describe 'GET #index' do
    let!(:invoice1) { create(:invoice, client_id: 1, status: 'pending') }
    let!(:invoice2) { create(:invoice, client_id: 1, status: 'paid') }

    it 'should get index' do
      get '/api/v1/facturas'
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']).not_to be_nil
      expect(json_response['total_invoices']).to eq(2)
    end

    it 'should include client data in response' do
      get '/api/v1/facturas'
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      first_invoice = json_response['data'].first
      
      expect(first_invoice['client']).not_to be_nil
      expect(first_invoice['client']['id']).to eq(client_data['id'])
    end

    it 'should filter by client_id' do
      get '/api/v1/facturas', params: { client_id: 1 }
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['total_invoices']).to eq(2)
    end

    it 'should return not_found for non-existent client' do
      allow(ClientsService).to receive(:find_client).and_return(nil)
      
      get '/api/v1/facturas', params: { client_id: 999 }
      
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be false
      expect(json_response['message']).to eq("Cliente no encontrado")
    end

    it 'should filter by status' do
      get '/api/v1/facturas', params: { status: 'paid' }
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['total_invoices']).to eq(1)
      expect(json_response['data'].first['status']).to eq('paid')
    end

    it 'should return bad_request for invalid date format' do
      get '/api/v1/facturas', params: { fechaInicio: 'invalid-date' }
      
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be false
    end
  end

  describe 'GET #show' do
    let!(:invoice) { create(:invoice, client_id: 1) }

    it 'should show invoice' do
      get "/api/v1/facturas/#{invoice.id}"
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['id']).to eq(invoice.id)
    end

    it 'should include detailed client data' do
      get "/api/v1/facturas/#{invoice.id}"
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      client = json_response['data']['client']
      
      expect(client).not_to be_nil
      expect(client['id']).to eq(client_data['id'])
      expect(client['name']).to eq(client_data['name'])
    end

    it 'should return not_found for non-existent invoice' do
      get '/api/v1/facturas/99999'
      
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be false
      expect(json_response['message']).to eq("Factura no encontrada")
    end

    it 'should call AuditService.log_read' do
      expect(AuditService).to receive(:log_read).with('invoice', invoice.id)
      get "/api/v1/facturas/#{invoice.id}"
    end
  end

  describe 'POST #create' do
    let(:valid_invoice_params) do
      {
        invoice: {
          client_id: 1,
          issue_date: Date.current,
          due_date: Date.current + 30.days,
          subtotal: 1500.00,
          tax: 285.00,
          status: 'pending'
        }
      }
    end

    it 'should create invoice with valid data' do
      expect {
        post '/api/v1/facturas', params: valid_invoice_params
      }.to change(Invoice, :count).by(1)
      
      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['message']).to eq("Factura creada exitosamente")
    end

    it 'should generate invoice_number automatically' do
      post '/api/v1/facturas', params: {
        invoice: {
          client_id: 1,
          issue_date: Date.current,
          subtotal: 1000.00,
          status: 'pending'
        }
      }
      
      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response['data']['invoice_number']).not_to be_nil
      expect(json_response['data']['invoice_number']).to match(/INV-\d{8}-\d{4}/)
    end

    it 'should not create invoice without required fields' do
      expect {
        post '/api/v1/facturas', params: {
          invoice: {
            client_id: 1,
            status: 'pending'
          }
        }
      }.not_to change(Invoice, :count)
      
      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be false
    end

    it 'should not create invoice with non-existent client' do
      allow(ClientsService).to receive(:client_exists?).and_return(false)
      
      expect {
        post '/api/v1/facturas', params: {
          invoice: {
            client_id: 999,
            issue_date: Date.current,
            subtotal: 1000.00,
            status: 'pending'
          }
        }
      }.not_to change(Invoice, :count)
      
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'should calculate total automatically' do
      post '/api/v1/facturas', params: {
        invoice: {
          client_id: 1,
          issue_date: Date.current,
          subtotal: 1000.00,
          tax: 190.00,
          status: 'pending'
        }
      }
      
      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response['data']['total']).to eq("1190.0")
    end

    it 'should call AuditService.log_create on success' do
      expect(AuditService).to receive(:log_create).with('invoice', anything, anything)
      post '/api/v1/facturas', params: valid_invoice_params
    end
  end
end
