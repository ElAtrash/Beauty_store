# frozen_string_literal: true

module Products
  class ProductPriceComponent < ViewComponent::Base
    def initialize(price_info:, stock_info:)
      @price_info = price_info
      @stock_info = stock_info
    end

    private

    attr_reader :price_info, :stock_info

    def show_sale_badge?
      price_info.on_sale? && price_info.original.present?
    end

    def stock_css_class
      stock_info.available? ? "text-green-600" : "text-red-600"
    end
  end
end
