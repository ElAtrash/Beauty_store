FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email_address { Faker::Internet.unique.email }
    password { "password123" }
    phone_number { Faker::PhoneNumber.cell_phone }
    preferred_language { "ar" }
    governorate { Faker::Address.state }
    city { Faker::Address.city }
    date_of_birth { Faker::Date.birthday(min_age: 18, max_age: 65) }
    admin { false }
    orders_count { 0 }

    trait :admin do
      admin { true }
    end

    trait :with_customer_profile do
      after(:create) do |user|
        create(:customer_profile, user: user)
      end
    end

    trait :with_orders do
      transient do
        orders_count { 3 }
      end

      after(:create) do |user, evaluator|
        create_list(:order, evaluator.orders_count, user: user)
      end
    end
  end
end
