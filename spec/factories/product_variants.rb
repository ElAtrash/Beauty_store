FactoryBot.define do
  factory :product_variant do
    association :product, product_attributes: { "skin_type" => "normal" }
    name { [ "30ml", "50ml", "100ml", "Travel Size", "Full Size" ].sample }
    sku { "SKU-#{Faker::Alphanumeric.alphanumeric(number: 8).upcase}" }
    barcode { Faker::Code.ean }
    price { Money.new(rand(2000..15000)) }
    compare_at_price { Money.new(0) }
    cost { Money.new(price.cents * 0.6) }
    color { nil }
    color_hex { nil }
    size_value { [ 30, 50, 100 ].sample }
    size_unit { "ml" }
    size_type { "volume" }
    stock_quantity { rand(0..100) }
    track_inventory { true }
    allow_backorder { false }
    position { rand(1..5) }
    is_default { false }
    canonical_variant { false }
    sales_count { 0 }
    conversion_score { 0.0 }

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

    trait :marked_default do
      is_default { true }
    end

    trait :canonical do
      canonical_variant { true }
    end

    trait :with_performance do
      sales_count { rand(5..50) }
      conversion_score { rand(1.0..10.0) }
    end

    trait :bestseller do
      sales_count { rand(20..100) }
      conversion_score { rand(5.0..10.0) }
    end

    trait :with_color do
      color { %w[red blue yellow green black white].sample }
      color_hex { "##{Faker::Color.hex_color.delete('#')}" }
    end

    trait :red do
      color { "red" }
      color_hex { "#FF0000" }
    end

    trait :blue do
      color { "blue" }
      color_hex { "#0000FF" }
    end

    trait :yellow do
      color { "yellow" }
      color_hex { "#FFFF00" }
    end

    trait :small_size do
      name { "50ml" }
      size_value { 50 }
      size_unit { "ml" }
      size_type { "volume" }
    end

    trait :medium_size do
      name { "100ml" }
      size_value { 100 }
      size_unit { "ml" }
      size_type { "volume" }
    end

    trait :large_size do
      name { "200ml" }
      size_value { 200 }
      size_unit { "ml" }
      size_type { "volume" }
    end
  end
end
