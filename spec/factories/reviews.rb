FactoryBot.define do
  factory :review do
    product
    user
    rating { rand(1..5) }
    title { Faker::Lorem.sentence(word_count: 3) }
    body { Faker::Lorem.paragraph(sentence_count: 3) }
    verified_purchase { [ true, false ].sample }
    status { "pending" }

    trait :approved do
      status { "approved" }
    end

    trait :rejected do
      status { "rejected" }
    end

    trait :verified do
      verified_purchase { true }
    end

    trait :five_star do
      rating { 5 }
      title { "Excellent product!" }
      body { "I absolutely love this product. It exceeded my expectations and I would definitely recommend it to others." }
    end

    trait :one_star do
      rating { 1 }
      title { "Very disappointed" }
      body { "This product did not work for me at all. I would not recommend it and it was a waste of money." }
    end

    trait :three_star do
      rating { 3 }
      title { "It's okay" }
      body { "This product is decent but nothing special. It does what it says but there are probably better options out there." }
    end
  end
end
