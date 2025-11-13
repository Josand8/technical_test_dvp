FactoryBot.define do
  factory :client do
    sequence(:name) { |n| "Cliente #{n}" }
    sequence(:identification) { |n| "ID#{n.to_s.rjust(6, '0')}" }
    sequence(:email) { |n| "cliente#{n}@example.com" }
    address { "Calle Principal 123" }

    trait :without_identification do
      identification { nil }
    end

    trait :without_address do
      address { nil }
    end

    trait :uppercase_email do
      sequence(:email) { |n| "UPPERCASE#{n}@EXAMPLE.COM" }
    end

    trait :mixed_case_email do
      sequence(:email) { |n| "TeSt#{n}@ExAmPlE.cOm" }
    end
  end
end

