FactoryBot.define do
  factory :order_item do
    association :order
    association :product
    association :product_variant

    trait :high_quantity do
      quantity { rand(5..10) }
    end

    trait :single_item do
      quantity { 1 }
    end
  end
end
