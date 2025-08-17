# frozen_string_literal: true

class Products::ProductInfoComponent < ViewComponent::Base
  def initialize(product:, product_data: nil)
    @product = product
    @product_data = product_data || build_product_data
  end

  private

  attr_reader :product, :product_data

  def build_product_data
    Products::ProductPresenter.new(product).build_display_data
  end

  def product_info
    product_data.product_info
  end

  def default_price_info
    product_data.price_for_variant
  end

  def default_stock_info
    product_data.stock_for_variant
  end

  def variant_options
    product_data.variant_options
  end

  def js_data
    product_data.to_js_data
  end
end
