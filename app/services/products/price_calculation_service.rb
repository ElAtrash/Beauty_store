# frozen_string_literal: true

module Products
  class PriceCalculationService
    class << self
      def calculate_range(product)
        new(product).calculate_range
      end
    end

    def initialize(product)
      @product = product
    end

    def calculate_range
      min_cents, max_cents = product_variants.pick("MIN(price_cents), MAX(price_cents)")
      return nil unless min_cents && max_cents

      min_price = Money.new(min_cents)
      max_price = Money.new(max_cents)

      min_price == max_price ? min_price : (min_price..max_price)
    end

    private

    attr_reader :product
    delegate :product_variants, to: :product
  end
end
