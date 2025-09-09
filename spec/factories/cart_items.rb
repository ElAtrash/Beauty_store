FactoryBot.define do
  factory :cart_item do
    cart
    product_variant
    quantity { 1 }
    price_snapshot_cents { 1000 }
    price_snapshot_currency { 'USD' }

    trait :single_item do
      quantity { 1 }
    end

    trait :bulk_quantity do
      quantity { 10 }
    end

    trait :random_values do
      quantity { rand(1..5) }
      price_snapshot_cents { rand(100..5000) }
    end
  end
end
