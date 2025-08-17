# frozen_string_literal: true

module Products
  class ProductActionsComponent < ViewComponent::Base
    def initialize(stock_info:)
      @stock_info = stock_info
    end

    private

    attr_reader :stock_info

    def cart_button_text
      stock_info.available? ? "ADD TO CART" : "OUT OF STOCK"
    end

    def cart_button_disabled?
      !stock_info.available?
    end
  end
end
