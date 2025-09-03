FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    slug { name.parameterize }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    product_type { [ "serum", "moisturizer", "cleanser", "toner", "mask" ].sample }
    brand
    ingredients { Faker::Lorem.paragraph }
    how_to_use { Faker::Lorem.paragraph }
    skin_types { Product::SKIN_TYPES.sample(rand(1..3)) }
    active { true }
    published_at { 1.week.ago }
    meta_title { Faker::Lorem.sentence }
    meta_description { Faker::Lorem.paragraph }
    reviews_count { 0 }
    product_attributes { { "skin_type" => "normal" } }

    trait :published do
      published_at { 1.week.ago }
      active { true }
    end

    trait :unpublished do
      published_at { nil }
    end

    trait :future_published do
      published_at { 1.week.from_now }
    end

    trait :inactive do
      active { false }
    end

    trait :oily_skin do
      skin_types { [ "oily" ] }
    end

    trait :dry_skin do
      skin_types { [ "dry" ] }
    end

    trait :with_variants do
      transient do
        variants_count { 3 }
      end

      after(:create) do |product, evaluator|
        create_list(:product_variant, evaluator.variants_count, product: product)
      end
    end

    trait :with_reviews do
      transient do
        reviews_count { 5 }
      end

      after(:create) do |product, evaluator|
        create_list(:review, evaluator.reviews_count, product: product)
      end
    end

    trait :with_categories do
      transient do
        categories_count { 2 }
      end

      after(:create) do |product, evaluator|
        categories = create_list(:category, evaluator.categories_count)
        categories.each do |category|
          create(:categorization, product: product, category: category)
        end
      end
    end

    trait :with_color_variants do
      after(:create) do |product|
        create(:product_variant, :red, :small_size, product: product, stock_quantity: 10)
        create(:product_variant, :red, :medium_size, product: product, stock_quantity: 8)
        create(:product_variant, :blue, :small_size, product: product, stock_quantity: 5)
        create(:product_variant, :blue, :medium_size, product: product, stock_quantity: 3)
      end
    end

    trait :with_size_only_variants do
      after(:create) do |product|
        create(:product_variant, :small_size, product: product, stock_quantity: 10)
        create(:product_variant, :medium_size, product: product, stock_quantity: 8)
        create(:product_variant, :large_size, product: product, stock_quantity: 5)
      end
    end
  end
end
