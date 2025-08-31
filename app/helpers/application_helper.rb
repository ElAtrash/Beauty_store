module ApplicationHelper
  include DiscountBadgeHelper

  def tailwind_variants(base_classes, variants: {})
    variant_classes = variants.map do |condition, classes|
      condition ? classes : nil
    end.compact.join(" ")

    [ base_classes, variant_classes ].join(" ").squish
  end

  def format_price(cents, currency = "USD")
    return I18n.t("products.price.unavailable") if cents.nil?

    amount = cents / 100.0
    case currency.upcase
    when "USD"
      number_to_currency(amount, unit: "$", precision: 2)
    else
      number_to_currency(amount, unit: currency_symbol(currency), precision: 2)
    end
  end

  private

  def currency_symbol(currency)
    case currency.upcase
    when "USD" then "$"
    when "EUR" then "€"
    when "GBP" then "£"
    else currency
    end
  end
end
