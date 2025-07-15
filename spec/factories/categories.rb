FactoryBot.define do
  factory :category do
    name { Faker::Commerce.department }
    slug { name.parameterize }
    description { Faker::Lorem.paragraph }
    position { rand(1..10) }

    trait :root do
      parent { nil }
    end

    trait :subcategory do
      parent { create(:category, :root) }
    end

    trait :with_children do
      transient do
        children_count { 3 }
      end

      after(:create) do |category, evaluator|
        create_list(:category, evaluator.children_count, parent: category)
      end
    end

    trait :with_products do
      transient do
        products_count { 5 }
      end

      after(:create) do |category, evaluator|
        products = create_list(:product, evaluator.products_count)
        products.each do |product|
          create(:categorization, category: category, product: product)
        end
      end
    end
  end
end
