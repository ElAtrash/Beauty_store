# frozen_string_literal: true

FactoryBot.define do
  factory :address do
    association :user
    label { "Home" }
    address_line_1 { "123 Main Street" }
    address_line_2 { "Apt 4B" }
    city { "Beirut" }
    governorate { "Beirut" }
    landmarks { "Near ABC Mall" }
    phone_number { "70123456" }
    default { false }

    trait :default do
      default { true }
    end

    trait :work do
      label { "Work" }
    end

    trait :deleted do
      deleted_at { 1.day.ago }
    end
  end
end
