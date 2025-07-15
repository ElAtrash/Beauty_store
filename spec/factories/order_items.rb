FactoryBot.define do
  factory :order_item do
    order
    product { create(:product) }
    product_variant { create(:product_variant, product: product) }
    product_name { product.name }
    variant_name { product_variant.name }
    quantity { rand(1..3) }
    unit_price { product_variant.price }
    total_price { unit_price * quantity }

    trait :high_quantity do
      quantity { rand(5..10) }
    end

    trait :single_item do
      quantity { 1 }
    end
  end
end
