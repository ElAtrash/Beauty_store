# frozen_string_literal: true

class Products::CartActionsComponent < ViewComponent::Base
  def initialize(product:, variant: nil, product_data: nil, stock_info: nil, current_cart: nil)
    @product = product
    @variant = variant
    @product_data = product_data
    @stock_info = stock_info
    @current_cart = current_cart
  end

  def current_variant
    @current_variant ||= determine_current_variant
  end

  def cart_item
    @cart_item ||= current_cart&.cart_items&.find_by(product_variant_id: current_variant&.id) if current_variant
  end

  def stock_available?
    @stock_available ||= determine_stock_availability
  end

  def turbo_frame_id
    "cart-actions-#{product.id}"
  end

  private

  attr_reader :product, :variant, :product_data, :stock_info, :current_cart

  def determine_current_variant
    return variant if variant.present?

    if product_data.present?
      variant_id = product_data.default_variant&.dig(:id)
      return ProductVariant.find_by(id: variant_id) if variant_id
    end

    product.default_variant
  end

  def determine_stock_availability
    return stock_info[:available] if stock_info.present?

    current_variant&.available? || false
  end
end
