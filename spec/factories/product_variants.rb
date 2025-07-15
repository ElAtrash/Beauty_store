FactoryBot.define do
  factory :product_variant do
    product
    name { [ "30ml", "50ml", "100ml", "Travel Size", "Full Size" ].sample }
    sku { "SKU-#{Faker::Alphanumeric.alphanumeric(number: 8).upcase}" }
    barcode { Faker::Code.ean }
    price { Money.new(rand(2000..15000)) }
    compare_at_price { nil }
    cost { Money.new(price.cents * 0.6) } # 60% of price
    color { nil }
    size { [ "Small", "Medium", "Large" ].sample }
    volume { [ "30ml", "50ml", "100ml" ].sample }
    stock_quantity { rand(0..100) }
    track_inventory { true }
    allow_backorder { false }
    position { rand(1..5) }

    trait :on_sale do
      compare_at_price { Money.new(price.cents * 1.3) }
    end

    trait :out_of_stock do
      stock_quantity { 0 }
      allow_backorder { false }
    end

    trait :backorder_allowed do
      stock_quantity { 0 }
      allow_backorder { true }
    end

    trait :no_inventory_tracking do
      track_inventory { false }
      stock_quantity { 0 }
    end

    trait :high_stock do
      stock_quantity { rand(50..200) }
    end

    trait :low_stock do
      stock_quantity { rand(1..5) }
    end
  end
end
