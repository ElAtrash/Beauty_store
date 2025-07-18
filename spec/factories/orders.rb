FactoryBot.define do
  factory :order do
    user
    email { user&.email_address || Faker::Internet.email }
    status { "pending" }
    payment_status { "pending" }
    fulfillment_status { nil }
    subtotal { Money.new(10000) }
    tax_total { Money.new(800) }
    shipping_total { Money.new(500) }
    discount_total { Money.new(0) }
    total { subtotal + tax_total + shipping_total - discount_total }
    billing_address {
      {
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        address1: Faker::Address.street_address,
        city: Faker::Address.city,
        zip: Faker::Address.zip_code,
        country: "US"
      }
    }
    shipping_address { billing_address }
    notes { Faker::Lorem.sentence }

    trait :guest do
      user { nil }
      email { Faker::Internet.email }
    end

    trait :processing do
      status { "processing" }
    end

    trait :shipped do
      status { "shipped" }
      fulfillment_status { "shipped" }
    end

    trait :delivered do
      status { "delivered" }
      fulfillment_status { "delivered" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :paid do
      payment_status { "paid" }
    end

    trait :refunded do
      payment_status { "refunded" }
    end

    trait :with_items do
      transient do
        items_count { 3 }
      end

      after(:create) do |order, evaluator|
        create_list(:order_item, evaluator.items_count, order: order)
        order.calculate_totals!
      end
    end

    trait :with_discount do
      discount_total { Money.new(1000) }
      total { subtotal + tax_total + shipping_total - discount_total }
    end
  end
end
