FactoryBot.define do
  factory :customer_profile do
    user
    skin_type { CustomerProfile.skin_types.keys.sample }
    skin_concerns { CustomerProfile.skin_concerns.keys.sample(rand(1..3)) }
    tags { [ Faker::Lorem.word, Faker::Lorem.word ] }
    total_spent { Money.new(rand(0..50000)) }

    trait :oily_skin do
      skin_type { "oily" }
      skin_concerns { [ "acne", "pores" ] }
    end

    trait :dry_skin do
      skin_type { "dry" }
      skin_concerns { [ "dullness", "sensitivity" ] }
    end

    trait :big_spender do
      total_spent { Money.new(rand(100000..500000)) }
    end
  end
end
