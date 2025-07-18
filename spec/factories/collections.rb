FactoryBot.define do
  factory :collection do
    name { [ "Summer Essentials", "Best Sellers", "New Arrivals", "Anti-Aging", "Sensitive Skin" ].sample }
    slug { name.parameterize }
    description { Faker::Lorem.paragraph }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_products do
      transient do
        products_count { 5 }
      end

      after(:create) do |collection, evaluator|
        products = create_list(:product, evaluator.products_count)
        products.each_with_index do |product, index|
          create(:collection_product, collection: collection, product: product, position: index + 1)
        end
      end
    end
  end
end
