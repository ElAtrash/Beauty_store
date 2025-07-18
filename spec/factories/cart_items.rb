FactoryBot.define do
  factory :cart_item do
    cart
    product_variant
    quantity { rand(1..5) }

    trait :single_item do
      quantity { 1 }
    end

    trait :bulk_quantity do
      quantity { rand(10..20) }
    end
  end
end
