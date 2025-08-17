# frozen_string_literal: true

module Products
  class ProductHeaderComponent < ViewComponent::Base
    def initialize(product_info:)
      @product_info = product_info
    end

    private

    attr_reader :product_info

    def show_rating?
      product_info.reviews_count && product_info.reviews_count > 0
    end
  end
end
