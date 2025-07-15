FactoryBot.define do
  factory :brand do
    name { Faker::Company.name }
    slug { name.parameterize }
    description { Faker::Lorem.paragraph }
    logo_url { Faker::Internet.url }
    featured { false }

    trait :featured do
      featured { true }
    end

    trait :with_products do
      transient do
        products_count { 5 }
      end

      after(:create) do |brand, evaluator|
        create_list(:product, evaluator.products_count, brand: brand)
      end
    end
  end
end
