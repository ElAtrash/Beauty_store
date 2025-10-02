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

  def flash_type_class(type)
    case type.to_s
    when "notice", "success" then "success"
    when "alert", "error" then "error"
    when "warning" then "warning"
    else "info"
    end
  end

  def validation_translations_for_js
    translations = {}

    validation_keys = [
      "field_required", "first_name_required", "last_name_required",
      "email_required", "email_invalid", "phone_required", "phone_invalid", "phone_lebanon_invalid",
      "password_required", "password_too_short", "password_confirmation_required",
      "passwords_dont_match", "address_required", "address_too_short",
      "delivery_date_required", "validation_error"
    ]

    validation_keys.each do |key|
      begin
        translation_key = "validation.errors.#{key}"
        translated_value = I18n.t(translation_key)

        if translated_value != translation_key
          translations[key] = translated_value
        else
          Rails.logger.warn "Missing validation translation: #{translation_key}"
          translations[key] = key.humanize
        end
      rescue => e
        Rails.logger.error "Error loading validation translation for #{key}: #{e.message}"
        translations[key] = key.humanize
      end
    end

    translations.to_json
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
