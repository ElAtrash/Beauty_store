# frozen_string_literal: true

Money.default_currency = :USD
Money.rounding_mode = BigDecimal::ROUND_HALF_UP

Money.locale_backend = :i18n

Money.default_formatting_rules = {
  symbol: true,
  thousands_separator: ",",
  decimal_mark: "."
}
