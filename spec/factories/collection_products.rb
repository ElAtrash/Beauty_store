FactoryBot.define do
  factory :collection_product do
    collection
    product
    position { rand(1..10) }
  end
end
