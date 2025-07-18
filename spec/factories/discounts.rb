FactoryBot.define do
  factory :discount do
    code { "#{Faker::Lorem.word.upcase}#{rand(10..99)}" }
    discount_type { [ "percentage", "fixed" ].sample }
    value { discount_type == "percentage" ? Money.new(rand(500..2500)) : Money.new(rand(1000..5000)) } # 5-25% or $10-50
    usage_limit { [ nil, 10, 50, 100 ].sample }
    usage_count { 0 }
    valid_from { 1.week.ago }
    valid_until { 1.month.from_now }
    active { true }

    trait :percentage do
      discount_type { "percentage" }
      value { Money.new(rand(500..2500)) } # 5-25%
    end

    trait :fixed do
      discount_type { "fixed" }
      value { Money.new(rand(1000..5000)) } # $10-50
    end

    trait :unlimited_use do
      usage_limit { nil }
    end

    trait :limited_use do
      usage_limit { rand(10..100) }
    end

    trait :expired do
      valid_until { 1.week.ago }
    end

    trait :future do
      valid_from { 1.week.from_now }
      valid_until { 2.months.from_now }
    end

    trait :inactive do
      active { false }
    end

    trait :exhausted do
      usage_limit { 10 }
      usage_count { 10 }
    end

    trait :twenty_percent_off do
      code { "SAVE20" }
      discount_type { "percentage" }
      value { Money.new(2000) }
    end

    trait :ten_dollars_off do
      code { "SAVE10" }
      discount_type { "fixed" }
      value { Money.new(1000) }
    end
  end
end
