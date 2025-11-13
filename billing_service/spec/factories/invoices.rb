FactoryBot.define do
  factory :invoice do
    client_id { 1 }
    invoice_number { nil } # Se generará automáticamente si es nil
    issue_date { Date.current }
    due_date { Date.current + 30.days }
    subtotal { 1000.00 }
    tax { 190.00 }
    status { 'pending' }
    notes { nil }

    trait :paid do
      status { 'paid' }
    end

    trait :overdue do
      status { 'overdue' }
      due_date { Date.current - 1.day }
    end

    trait :cancelled do
      status { 'cancelled' }
    end

    trait :with_custom_number do
      invoice_number { "CUSTOM-001" }
    end

    trait :without_tax do
      tax { nil }
    end

    trait :with_notes do
      notes { "Factura de prueba" }
    end

    trait :with_past_due_date do
      due_date { Date.current - 5.days }
    end

    trait :with_future_issue_date do
      issue_date { Date.current + 1.day }
    end
  end
end

