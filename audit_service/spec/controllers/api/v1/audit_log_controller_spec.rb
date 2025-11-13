require 'rails_helper'

RSpec.describe Api::V1::AuditLogController, type: :controller do
  describe 'GET #index' do
    let!(:client_log1) { create(:audit_log, :for_client, resource_id: 'client-1', status: 'success', created_at: 2.days.ago) }
    let!(:client_log2) { create(:audit_log, :for_client, resource_id: 'client-2', status: 'success', created_at: 1.day.ago) }
    let!(:invoice_log) { create(:audit_log, :for_invoice, resource_id: 'invoice-1', status: 'success', created_at: 3.days.ago) }
    let!(:failed_log) { create(:audit_log, :failed, resource_type: 'client', resource_id: 'client-3', created_at: 4.days.ago) }

    context 'without filters' do
      it 'returns all audit logs' do
        get :index
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']).to be_an(Array)
        expect(json_response['total_audit_logs']).to eq(4)
      end

      it 'returns logs ordered by created_at descending' do
        get :index
        json_response = JSON.parse(response.body)
        logs = json_response['data']
        
        expect(logs.length).to be > 0
        dates = logs.map { |log| DateTime.parse(log['created_at']) }
        expect(dates).to eq(dates.sort.reverse)
      end

      it 'limits results to 100' do
        105.times { create(:audit_log) }
        
        get :index
        json_response = JSON.parse(response.body)
        expect(json_response['data'].length).to eq(100)
      end
    end

    context 'with resource_type filter' do
      it 'filters by resource_type' do
        get :index, params: { resource_type: 'client' }
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data'].length).to eq(3)
        json_response['data'].each do |log|
          expect(log['resource_type']).to eq('client')
        end
      end

      it 'returns empty array when no logs match resource_type' do
        get :index, params: { resource_type: 'nonexistent' }
        
        json_response = JSON.parse(response.body)
        expect(json_response['data']).to eq([])
        expect(json_response['total_audit_logs']).to eq(0)
      end
    end

    context 'with resource_id filter' do
      it 'filters by resource_id' do
        get :index, params: { resource_id: 'client-1' }
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data'].length).to eq(1)
        expect(json_response['data'].first['resource_id']).to eq('client-1')
      end
    end

    context 'with status filter' do
      it 'filters by status' do
        get :index, params: { status: 'failed' }
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data'].length).to eq(1)
        expect(json_response['data'].first['status']).to eq('failed')
      end
    end

    context 'with date range filter' do
      it 'filters by start_date and end_date' do
        start_date = 2.days.ago.strftime('%Y-%m-%d')
        end_date = Time.current.strftime('%Y-%m-%d')
        
        get :index, params: { start_date: start_date, end_date: end_date }
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data'].length).to be >= 2
      end

      it 'returns empty array when date range has no logs' do
        start_date = 10.days.ago.strftime('%Y-%m-%d')
        end_date = 9.days.ago.strftime('%Y-%m-%d')
        
        get :index, params: { start_date: start_date, end_date: end_date }
        
        json_response = JSON.parse(response.body)
        expect(json_response['data']).to eq([])
      end
    end

    context 'with multiple filters' do
      it 'applies all filters correctly' do
        get :index, params: { 
          resource_type: 'client', 
          status: 'success',
          resource_id: 'client-1'
        }
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data'].length).to eq(1)
        log = json_response['data'].first
        expect(log['resource_type']).to eq('client')
        expect(log['status']).to eq('success')
        expect(log['resource_id']).to eq('client-1')
      end
    end
  end

  describe 'GET #show' do
    let!(:client_log1) { create(:audit_log, :for_client, resource_id: 'client-1', action: 'create', created_at: 2.days.ago) }
    let!(:client_log2) { create(:audit_log, :for_client, resource_id: 'client-1', action: 'update', created_at: 1.day.ago) }
    let!(:invoice_log) { create(:audit_log, :for_invoice, resource_id: 'invoice-1', created_at: 3.days.ago) }

    context 'with resource_id only' do
      it 'returns all logs for the resource_id' do
        get :show, params: { resource_id: 'client-1' }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']).to be_an(Array)
        expect(json_response['data'].length).to eq(2)
        json_response['data'].each do |log|
          expect(log['resource_id']).to eq('client-1')
        end
      end

      it 'returns logs ordered by created_at descending' do
        get :show, params: { resource_id: 'client-1' }
        
        json_response = JSON.parse(response.body)
        logs = json_response['data']
        dates = logs.map { |log| DateTime.parse(log['created_at']) }
        expect(dates).to eq(dates.sort.reverse)
      end
    end

    context 'with resource_id and resource_type' do
      it 'filters by both resource_id and resource_type' do
        get :show, params: { resource_id: 'client-1', resource_type: 'client' }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data'].length).to eq(2)
        json_response['data'].each do |log|
          expect(log['resource_id']).to eq('client-1')
          expect(log['resource_type']).to eq('client')
        end
      end

      it 'returns empty array when resource_type does not match' do
        get :show, params: { resource_id: 'client-1', resource_type: 'invoice' }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to include('No se encontraron logs')
      end
    end

    context 'when no logs found' do
      it 'returns not found status' do
        get :show, params: { resource_id: 'nonexistent-id' }
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to include('No se encontraron logs')
      end
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          audit_log: {
            resource_type: 'client',
            resource_id: 'client-123',
            action: 'create',
            status: 'success',
            changes_made: { 'name' => ['Old', 'New'] }
          }
        }
      end

      it 'creates a new audit log' do
        expect {
          post :create, params: valid_params
        }.to change(AuditLog, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: valid_params
        
        expect(response).to have_http_status(:created)
      end

      it 'returns success message and data' do
        post :create, params: valid_params
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Log creado exitosamente')
        expect(json_response['data']).to be_present
        expect(json_response['data']['resource_type']).to eq('client')
        expect(json_response['data']['resource_id']).to eq('client-123')
      end

      it 'sets created_at automatically' do
        post :create, params: valid_params
        
        json_response = JSON.parse(response.body)
        created_at = DateTime.parse(json_response['data']['created_at']).to_time
        expect(created_at).to be_within(1.second).of(Time.current)
      end
    end

    context 'with invalid parameters' do
      context 'missing required fields' do
        it 'returns unprocessable_entity when resource_type is missing' do
          post :create, params: {
            audit_log: {
              resource_id: 'client-123',
              action: 'create',
              status: 'success'
            }
          }
          
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be false
          expect(json_response['message']).to eq('No se pudo crear el log')
          expect(json_response['errors']).to be_present
        end

        it 'returns unprocessable_entity when resource_id is missing' do
          post :create, params: {
            audit_log: {
              resource_type: 'client',
              action: 'create',
              status: 'success'
            }
          }
          
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns unprocessable_entity when action is missing' do
          post :create, params: {
            audit_log: {
              resource_type: 'client',
              resource_id: 'client-123',
              status: 'success'
            }
          }
          
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns unprocessable_entity when status is missing' do
          post :create, params: {
            audit_log: {
              resource_type: 'client',
              resource_id: 'client-123',
              action: 'create'
            }
          }
          
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'invalid enum values' do
        it 'returns unprocessable_entity when resource_type is invalid' do
          post :create, params: {
            audit_log: {
              resource_type: 'invalid',
              resource_id: 'client-123',
              action: 'create',
              status: 'success'
            }
          }
          
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to be_present
        end

        it 'returns unprocessable_entity when action is invalid' do
          post :create, params: {
            audit_log: {
              resource_type: 'client',
              resource_id: 'client-123',
              action: 'invalid',
              status: 'success'
            }
          }
          
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns unprocessable_entity when status is invalid' do
          post :create, params: {
            audit_log: {
              resource_type: 'client',
              resource_id: 'client-123',
              action: 'create',
              status: 'invalid'
            }
          }
          
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'with error_message' do
      it 'creates log with error_message for failed status' do
        post :create, params: {
          audit_log: {
            resource_type: 'client',
            resource_id: 'client-123',
            action: 'error',
            status: 'failed',
            error_message: 'Database connection failed'
          }
        }
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['data']['status']).to eq('failed')
        expect(json_response['data']['error_message']).to eq('Database connection failed')
      end
    end

    context 'with changes_made hash' do
      it 'creates log with changes_made' do
        changes = {
          'name' => ['Old Name', 'New Name'],
          'email' => ['old@example.com', 'new@example.com']
        }
        
        post :create, params: {
          audit_log: {
            resource_type: 'client',
            resource_id: 'client-123',
            action: 'update',
            status: 'success',
            changes_made: changes
          }
        }
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['data']['changes_made']).to eq(changes)
      end
    end
  end
end

