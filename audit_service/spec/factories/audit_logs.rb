FactoryBot.define do
  factory :audit_log do
    resource_type { 'client' }
    resource_id { SecureRandom.uuid }
    action { 'create' }
    changes_made { {} }
    status { 'success' }
    error_message { nil }
    created_at { Time.current }

    trait :for_invoice do
      resource_type { 'invoice' }
    end

    trait :for_client do
      resource_type { 'client' }
    end

    trait :read_action do
      action { 'read' }
    end

    trait :update_action do
      action { 'update' }
    end

    trait :delete_action do
      action { 'delete' }
    end

    trait :error_action do
      action { 'error' }
    end

    trait :failed do
      status { 'failed' }
      error_message { 'Error message here' }
    end

    trait :with_changes do
      changes_made do
        {
          'name' => ['Old Name', 'New Name'],
          'email' => ['old@example.com', 'new@example.com']
        }
      end
    end

    trait :with_invoice_changes do
      resource_type { 'invoice' }
      changes_made do
        {
          'status' => ['pending', 'paid'],
          'total' => [100.0, 120.0]
        }
      end
    end
  end
end

