require 'rails_helper'

RSpec.describe AuditLog, type: :model do
  describe 'validations' do
    it 'validates presence of resource_type' do
      audit_log = build(:audit_log, resource_type: nil)
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:resource_type]).to be_present
    end

    it 'validates presence of resource_id' do
      audit_log = build(:audit_log, resource_id: nil)
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:resource_id]).to be_present
    end

    it 'validates presence of action' do
      audit_log = build(:audit_log, action: nil)
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:action]).to be_present
    end

    it 'validates presence of status' do
      audit_log = build(:audit_log, status: nil)
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:status]).to be_present
    end

    it 'validates inclusion of resource_type in allowed values' do
      audit_log = build(:audit_log, resource_type: 'invalid')
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:resource_type]).to be_present
    end

    it 'validates inclusion of action in allowed values' do
      audit_log = build(:audit_log, action: 'invalid')
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:action]).to be_present
    end

    it 'validates inclusion of status in allowed values' do
      audit_log = build(:audit_log, status: 'invalid')
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:status]).to be_present
    end
  end

  describe 'fields' do
    it 'has the correct field types' do
      audit_log = described_class.new
      expect(audit_log).to respond_to(:resource_type)
      expect(audit_log).to respond_to(:resource_id)
      expect(audit_log).to respond_to(:action)
      expect(audit_log).to respond_to(:changes_made)
      expect(audit_log).to respond_to(:status)
      expect(audit_log).to respond_to(:error_message)
      expect(audit_log).to respond_to(:created_at)
    end

    it 'has default value for changes_made' do
      audit_log = described_class.new
      expect(audit_log.changes_made).to eq({})
    end
  end

  describe 'callbacks' do
    describe '#set_created_at' do
      context 'when created_at is not set' do
        it 'sets created_at before creation' do
          audit_log = build(:audit_log, created_at: nil)
          expect(audit_log.created_at).to be_nil
          
          audit_log.save
          expect(audit_log.created_at).not_to be_nil
          created_at_time = audit_log.created_at.is_a?(String) ? DateTime.parse(audit_log.created_at).to_time : audit_log.created_at.to_time
          expect(created_at_time).to be_within(1.second).of(Time.current)
        end
      end

      context 'when created_at is already set' do
        it 'does not override existing created_at' do
          custom_time = 1.day.ago
          audit_log = build(:audit_log, created_at: custom_time)
          
          audit_log.save
          created_at_time = audit_log.created_at.is_a?(String) ? DateTime.parse(audit_log.created_at).to_time : audit_log.created_at.to_time
          expect(created_at_time).to be_within(1.second).of(custom_time)
        end
      end
    end
  end

  describe 'valid resource types' do
    it 'accepts "client" as resource_type' do
      audit_log = build(:audit_log, resource_type: 'client')
      expect(audit_log).to be_valid
    end

    it 'accepts "invoice" as resource_type' do
      audit_log = build(:audit_log, resource_type: 'invoice')
      expect(audit_log).to be_valid
    end

    it 'rejects invalid resource_type' do
      audit_log = build(:audit_log, resource_type: 'invalid')
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:resource_type]).to be_present
    end
  end

  describe 'valid actions' do
    %w[create read update delete error].each do |action|
      it "accepts '#{action}' as action" do
        audit_log = build(:audit_log, action: action)
        expect(audit_log).to be_valid
      end
    end

    it 'rejects invalid action' do
      audit_log = build(:audit_log, action: 'invalid')
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:action]).to be_present
    end
  end

  describe 'valid statuses' do
    it 'accepts "success" as status' do
      audit_log = build(:audit_log, status: 'success')
      expect(audit_log).to be_valid
    end

    it 'accepts "failed" as status' do
      audit_log = build(:audit_log, status: 'failed')
      expect(audit_log).to be_valid
    end

    it 'rejects invalid status' do
      audit_log = build(:audit_log, status: 'invalid')
      expect(audit_log).not_to be_valid
      expect(audit_log.errors[:status]).to be_present
    end
  end

  describe 'changes_made field' do
    it 'can store hash of changes' do
      changes = {
        'name' => ['Old Name', 'New Name'],
        'email' => ['old@example.com', 'new@example.com']
      }
      audit_log = create(:audit_log, changes_made: changes)
      expect(audit_log.changes_made).to eq(changes)
    end

    it 'defaults to empty hash' do
      audit_log = create(:audit_log)
      expect(audit_log.changes_made).to eq({})
    end
  end

  describe 'error_message field' do
    it 'can be nil for successful operations' do
      audit_log = create(:audit_log, status: 'success', error_message: nil)
      expect(audit_log.error_message).to be_nil
    end

    it 'can store error message for failed operations' do
      error_msg = 'Database connection failed'
      audit_log = create(:audit_log, status: 'failed', error_message: error_msg)
      expect(audit_log.error_message).to eq(error_msg)
    end
  end

  describe 'factory' do
    it 'creates a valid audit_log' do
      audit_log = build(:audit_log)
      expect(audit_log).to be_valid
    end

    it 'creates an audit_log with invoice resource_type' do
      audit_log = create(:audit_log, :for_invoice)
      expect(audit_log.resource_type).to eq('invoice')
      expect(audit_log).to be_persisted
    end

    it 'creates an audit_log with client resource_type' do
      audit_log = create(:audit_log, :for_client)
      expect(audit_log.resource_type).to eq('client')
      expect(audit_log).to be_persisted
    end

    it 'creates a failed audit_log' do
      audit_log = create(:audit_log, :failed)
      expect(audit_log.status).to eq('failed')
      expect(audit_log.error_message).to be_present
    end

    it 'creates an audit_log with changes' do
      audit_log = create(:audit_log, :with_changes)
      expect(audit_log.changes_made).not_to be_empty
      expect(audit_log.changes_made['name']).to be_present
    end
  end

  describe 'scopes and queries' do
    let!(:client_log1) { create(:audit_log, :for_client, resource_id: 'client-1', action: 'create') }
    let!(:client_log2) { create(:audit_log, :for_client, resource_id: 'client-1', action: 'update') }
    let!(:invoice_log) { create(:audit_log, :for_invoice, resource_id: 'invoice-1', action: 'create') }
    let!(:failed_log) { create(:audit_log, :failed, :error_action, resource_type: 'client', resource_id: 'client-2') }

    it 'can query by resource_type' do
      client_logs = described_class.where(resource_type: 'client')
      expect(client_logs.count).to eq(3)
    end

    it 'can query by resource_id' do
      logs = described_class.where(resource_id: 'client-1')
      expect(logs.count).to eq(2)
    end

    it 'can query by status' do
      failed_logs = described_class.where(status: 'failed')
      expect(failed_logs.count).to eq(1)
    end

    it 'can query by action' do
      create_logs = described_class.where(action: 'create')
      expect(create_logs.count).to eq(2)
    end

    it 'can combine resource_type and resource_id' do
      logs = described_class.where(resource_type: 'client', resource_id: 'client-1')
      expect(logs.count).to eq(2)
    end
  end
end

