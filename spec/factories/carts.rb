FactoryBot.define do
  factory :cart do
    user
    session_id { SecureRandom.hex(16) }
    abandoned_at { nil }

    trait :guest do
      user { nil }
      session_id { SecureRandom.hex(16) }
    end

    trait :abandoned do
      abandoned_at { 1.day.ago }
    end

    trait :with_items do
      transient do
        items_count { 3 }
      end

      after(:create) do |cart, evaluator|
        create_list(:cart_item, evaluator.items_count, cart: cart)
      end
    end

    trait :empty do
      # No items - default state
    end
  end
end
